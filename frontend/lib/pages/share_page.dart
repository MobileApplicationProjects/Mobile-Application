import 'dart:async';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/share_service.dart';
import '../services/health_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../home_page.dart';
import 'map_page.dart';
import 'leaderboard_page.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class SharePage extends StatefulWidget {
  const SharePage({super.key});

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final ShareService _shareService = ShareService();
  final LocationService _locationService = LocationService();
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  
  bool _isLoading = true;
  Map<String, dynamic>? _summary;

  int _steps = 0;
  int _goal = 5000;
  double _calories = 0.0;
  double _distanceKm = 0.0;
  String _displayName = 'User';

  List<LatLng> _routePoints = [];
  LatLng? _routeCenter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    try {
      // Use HealthService (same as HomePage) to get real-time device data
      final healthService = HealthService();
      final authService = AuthService();

      final results = await Future.wait([
        healthService.fetchTodayMetrics(),
        healthService.fetchGoal().then((g) => {'goal': g}),
        authService.getProfile(),
        _locationService.getLatestSession().catchError((_) => null),
      ]);

      final healthData = results[0] as Map<String, dynamic>;
      final goal = (results[1] as Map<String, dynamic>)['goal'] as int;
      final profileResult = results[2] as Map<String, dynamic>;
      final session = results[3] as Map<String, dynamic>?;
      final profile = profileResult['profile'];

      // Parse route points from latest session
      List<LatLng> points = [];
      if (session != null && session['points'] != null) {
        final rawPoints = session['points'] as List<dynamic>;
        points = rawPoints
          .map((p) => LatLng(
            (p['lat'] as num).toDouble(),
            (p['lng'] as num).toDouble(),
          ))
          .toList();
      }

      // Compute center of route
      LatLng? center;
      if (points.isNotEmpty) {
        double avgLat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
        double avgLng = points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;
        center = LatLng(avgLat, avgLng);
      }

      if (mounted) {
        setState(() {
          _steps = healthData['steps'] ?? 0;
          _goal = goal;
          _calories = (healthData['calories'] ?? 0.0).toDouble();
          double meters = (healthData['distance'] ?? 0.0).toDouble();
          _distanceKm = meters / 1000.0;
          _routePoints = points;
          _routeCenter = center;

          if (profile != null) {
            final first = profile['firstName'] ?? '';
            final last = profile['lastName'] ?? '';
            _displayName = first.isNotEmpty ? '$first $last' : (profile['username'] ?? 'User');
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading share summary: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showShareMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Share to',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Instagram with image icon
                  GestureDetector(
                    onTap: () => _handleShare(sheetContext, 'instagram'),
                    child: SizedBox(
                      width: 70,
                      child: Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset('assets/images/Instagram_icon.png', width: 28, height: 28),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Instagram',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildShareIcon(icon: Icons.download, label: 'Save', onTap: () => _handleShare(sheetContext, 'save')),
                  _buildShareIcon(icon: Icons.link, label: 'Copy Link', onTap: () => _handleShare(sheetContext, 'copy_link')),
                  _buildShareIcon(icon: Icons.more_horiz, label: 'More', onTap: () => _handleShare(sheetContext, 'more')),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }
    );
  }

  Widget _buildShareIcon({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(child: Icon(icon, color: Colors.black, size: 28)),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleShare(BuildContext sheetContext, String platform) async {
    Navigator.pop(sheetContext); // Close bottom sheet
    
    // Log the share event
    await _shareService.logShare(platform, _summary);

    if (!mounted) return;
    await _shareImage();
  }

  Future<void> _shareImage() async {
    if (!mounted) return;
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing image...')),
    );

    try {
      final directory = await getApplicationDocumentsDirectory();
      
      if (!mounted) return;
      final imagePath = await _screenshotController.captureAndSave(
        directory.path,
        fileName: "share_summary.png",
        pixelRatio: 3.0,
      );

      if (imagePath != null && mounted) {
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: 'Checkout my workout progress today on Gao!',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Share',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // balance
                ],
              ),
            ),
            
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.red))
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Screenshot(
                          controller: _screenshotController,
                          child: _buildShareCard(),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _showShareMenu,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Share',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
            ),

            const CustomBottomNavBar(currentIndex: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildShareCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                _displayName,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActivityRing(
                value: _goal > 0 ? (_steps / _goal).clamp(0.0, 1.0) : 0.0,
                icon: Icons.directions_run_rounded,
                iconColor: Colors.red[400]!,
                valueText: '$_steps',
                titleText: 'Step',
                subtitleText: 'Goal $_goal',
                ringColor: Colors.orange[800]!,
              ),
              _buildActivityRing(
                value: (_calories / 500.0).clamp(0.0, 1.0),
                icon: Icons.local_fire_department_rounded,
                iconColor: Colors.red[400]!,
                valueText: '${_calories.toStringAsFixed(0)} kcal',
                titleText: 'Calories',
                ringColor: Colors.orange[800]!,
              ),
              _buildActivityRing(
                value: (_distanceKm / 5.0).clamp(0.0, 1.0),
                icon: Icons.arrow_forward_rounded,
                iconColor: Colors.red[400]!,
                valueText: '${_distanceKm.toStringAsFixed(1)} km',
                titleText: 'Distance',
                ringColor: Colors.orange[800]!,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Route Map
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 220,
              child: _routePoints.isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_outlined, color: Colors.grey[700], size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'No route recorded yet',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _routeCenter ?? const LatLng(13.736717, 100.523186),
                      zoom: 15,
                    ),
                    onMapCreated: (controller) {
                      if (!_mapController.isCompleted) {
                        _mapController.complete(controller);
                      }
                      // Fit bounds to route
                      if (_routePoints.length > 1) {
                        final bounds = _boundsFromPoints(_routePoints);
                        controller.animateCamera(
                          CameraUpdate.newLatLngBounds(bounds, 40),
                        );
                      }
                    },
                    polylines: {
                      Polyline(
                        polylineId: const PolylineId('route'),
                        points: _routePoints,
                        color: Colors.orange,
                        width: 5,
                        startCap: Cap.roundCap,
                        endCap: Cap.roundCap,
                      ),
                    },
                    markers: _routePoints.isEmpty ? {} : {
                      Marker(
                        markerId: const MarkerId('start'),
                        position: _routePoints.first,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                      ),
                      Marker(
                        markerId: const MarkerId('end'),
                        position: _routePoints.last,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      ),
                    },
                    myLocationEnabled: false,
                    zoomControlsEnabled: false,
                    scrollGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    liteModeEnabled: true,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  LatLngBounds _boundsFromPoints(List<LatLng> points) {
    double minLat = points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    double maxLat = points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    double minLng = points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    double maxLng = points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Widget _buildActivityRing({
    required double value,
    required IconData icon,
    required Color iconColor,
    required String valueText,
    required String titleText,
    String? subtitleText,
    required Color ringColor,
  }) {
    return Column(
      children: [
        SizedBox(
          height: 60,
          width: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 60,
                width: 60,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 10,
                  backgroundColor: ringColor.withAlpha(30),
                  valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Icon(icon, color: iconColor, size: 26),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          valueText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          titleText,
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
        if (subtitleText != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitleText,
            style: TextStyle(color: Colors.grey[700], fontSize: 11),
          ),
        ] else ...[
          const SizedBox(height: 15),
        ],
      ],
    );
  }
}
