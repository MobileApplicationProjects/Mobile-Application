import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/share_service.dart';
import '../home_page.dart';
import 'map_page.dart';
import 'leaderboard_page.dart';

class SharePage extends StatefulWidget {
  const SharePage({super.key});

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final ShareService _shareService = ShareService();
  
  bool _isLoading = true;
  Map<String, dynamic>? _summary;

  int _steps = 0;
  int _goal = 5000;
  double _calories = 0.0;
  double _distanceKm = 0.0;
  String _displayName = 'User';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final summary = await _shareService.getTodaySummary();
      
      if (mounted) {
        setState(() {
          _summary = summary;
          _steps = summary['steps'] ?? 0;
          _goal = summary['stepGoalDaily'] ?? 5000;
          _calories = (summary['calories'] ?? 0.0).toDouble();
          _distanceKm = (summary['distanceKm'] ?? 0.0).toDouble();
          
          final profile = summary['profile'] as Map<String, dynamic>?;
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
      builder: (context) {
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
                  _buildShareIcon(icon: Icons.camera_alt, label: 'Instagram\nStory', onTap: () => _handleShare('instagram')),
                  _buildShareIcon(icon: Icons.download, label: 'Save', onTap: () => _handleShare('save')),
                  _buildShareIcon(icon: Icons.link, label: 'Copy Link', onTap: () => _handleShare('copy_link')),
                  _buildShareIcon(icon: Icons.more_horiz, label: 'More', onTap: () => _handleShare('more')),
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Future<void> _handleShare(String platform) async {
    Navigator.pop(context); // Close bottom sheet
    
    // Log the share event
    await _shareService.logShare(platform, _summary);

    await _shareImage();
  }

  Future<void> _shareImage() async {
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing image...')),
    );

    try {
      final directory = await getApplicationDocumentsDirectory();
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

            _buildBottomNavigationBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildShareCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                _displayName,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricRing(
                progress: (_steps / _goal).clamp(0.0, 1.0),
                iconPath: 'assets/images/target.png',
                valueText: '$_steps',
                labelText: 'Step',
              ),
              _buildMetricRing(
                progress: (_calories/1000).clamp(0.0, 1.0),
                iconPath: 'assets/images/fire.png',
                valueText: '${_calories.toStringAsFixed(0)} kcal',
                labelText: 'Calories',
              ),
              _buildMetricRing(
                progress: (_distanceKm/10).clamp(0.0, 1.0),
                iconPath: 'assets/images/location.png',
                fallbackIcon: Icons.directions_run_rounded,
                valueText: '${_distanceKm.toStringAsFixed(2)} km',
                labelText: 'Distance',
              ),
            ],
          ),
          const SizedBox(height: 30),
          // Map preview area (static box for screenshot)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 250,
              decoration: const BoxDecoration(
                color: Color(0xFF222222),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // We simulate a dark map background
                  Image.asset(
                    'assets/images/chart.png', // Replace with a generic map screenshot if preferred
                    fit: BoxFit.cover,
                    opacity: const AlwaysStoppedAnimation(0.2),
                    errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF2C2C2C)),
                  ),
                  const Center(
                    child: Icon(Icons.map, color: Colors.white24, size: 80),
                  ),
                  Positioned(
                    bottom: 15,
                    right: 15,
                    child: Icon(Icons.my_location, color: Colors.red[400], size: 30),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRing({
    required double progress,
    required String iconPath,
    IconData? fallbackIcon,
    required String valueText,
    required String labelText,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 4,
                color: Colors.grey[200],
              ),
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 4,
                color: Colors.red[700],
                strokeCap: StrokeCap.round,
              ),
              Center(
                child: fallbackIcon != null
                    ? Icon(fallbackIcon, size: 20, color: Colors.red[700])
                    : Image.asset(
                        iconPath,
                        width: 20,
                        height: 20,
                        color: Colors.red[700],
                        errorBuilder: (_, __, ___) => Icon(Icons.accessibility_new, size: 20, color: Colors.red[700]),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          valueText,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
        ),
        Text(
          labelText,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(icon: Icons.home_rounded, label: 'HOME', isActive: false, onTap: () {
             Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomePage()),
                (route) => false,
             );
          }),
          _buildNavItem(icon: Icons.location_on_rounded, label: 'MAP', isActive: false, onTap: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MapPage()));
          }),
          _buildNavItem(icon: Icons.track_changes_rounded, label: 'CHALLENGE', isActive: false, onTap: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LeaderboardPage()));
          }),
          _buildNavItem(icon: Icons.ios_share_rounded, label: 'SHARE', isActive: true, onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required bool isActive, required VoidCallback onTap}) {
    final color = isActive ? Colors.red[700]! : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
