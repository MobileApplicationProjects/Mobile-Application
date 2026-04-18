import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../home_page.dart';
import 'leaderboard_page.dart';
import 'share_page.dart';
import '../services/location_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  final LocationService _locationService = LocationService();
  
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(13.736717, 100.523186), // Bangkok default
    zoom: 14.4746,
  );

  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  LatLng? _currentPosition;
  bool _isLoading = true;
  
  String? _sessionId;
  StreamSubscription<Position>? _positionStream;
  List<LatLng> _points = [];
  List<LatLng> _pendingPoints = [];
  Timer? _uploadTimer;

  @override
  void initState() {
    super.initState();
    _initMapAndTracking();
  }

  @override
  void dispose() {
    _stopTracking();
    super.dispose();
  }

  Future<void> _initMapAndTracking() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Get initial position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _currentPosition = LatLng(position.latitude, position.longitude);
      
      if (mounted) {
        setState(() {
          _markers.add(
            Marker(
              markerId: const MarkerId('current_location'),
              position: _currentPosition!,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            )
          );
        });

        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition!, zoom: 15.5),
        ));
      }

      // 2. Start Session on Backend
      _sessionId = await _locationService.startSession();
      
      // 3. Start Live Tracking
      _startTracking();
      
    } catch (e) {
      print("Error initializing map/tracking: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  void _startTracking() {
    // Stream positions
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      final newPoint = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _currentPosition = newPoint;
        _points.add(newPoint);
        _pendingPoints.add(newPoint);
        
        // Update Polyline
        _polylines = {
          Polyline(
            polylineId: const PolylineId('real_route'),
            points: _points,
            color: Colors.redAccent,
            width: 5,
            jointType: JointType.round,
            endCap: Cap.roundCap,
            startCap: Cap.roundCap,
          ),
        };

        // Update Marker
        _markers = {
          Marker(
            markerId: const MarkerId('current_location'),
            position: newPoint,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          )
        };
      });
    });

    // periodic upload timer (every 30s)
    _uploadTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _uploadPendingPoints();
    });
  }

  Future<void> _uploadPendingPoints() async {
    if (_sessionId == null || _pendingPoints.isEmpty) return;
    
    final pointsToUpload = List<LatLng>.from(_pendingPoints);
    _pendingPoints.clear();
    
    try {
      await _locationService.addPoints(_sessionId!, pointsToUpload);
    } catch (e) {
      // Re-add on failure? For now just log
      print("Failed to upload points: $e");
      _pendingPoints.addAll(pointsToUpload);
    }
  }

  Future<void> _stopTracking() async {
    _positionStream?.cancel();
    _uploadTimer?.cancel();
    
    if (_sessionId != null) {
      // Final upload
      if (_pendingPoints.isNotEmpty) {
        await _uploadPendingPoints();
      }
      // End session
      try {
        await _locationService.endSession(_sessionId!);
      } catch (e) {
        print("Error ending session: $e");
      }
    }
  }

  // A very detailed dark theme similar to standard dark map
  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
    controller.setMapStyle('''
      [
        {
          "elementType": "geometry",
          "stylers": [
            { "color": "#212121" }
          ]
        },
        {
          "elementType": "labels.icon",
          "stylers": [
            { "visibility": "off" }
          ]
        },
        {
          "elementType": "labels.text.fill",
          "stylers": [
            { "color": "#757575" }
          ]
        },
        {
          "elementType": "labels.text.stroke",
          "stylers": [
            { "color": "#212121" }
          ]
        },
        {
          "featureType": "administrative",
          "elementType": "geometry",
          "stylers": [
            { "color": "#757575" }
          ]
        },
        {
          "featureType": "administrative.country",
          "elementType": "labels.text.fill",
          "stylers": [
            { "color": "#9e9e9e" }
          ]
        },
        {
          "featureType": "administrative.locality",
          "elementType": "labels.text.fill",
          "stylers": [
            { "color": "#bdbdbd" }
          ]
        },
        {
          "featureType": "poi",
          "elementType": "labels.text.fill",
          "stylers": [
            { "color": "#757575" }
          ]
        },
        {
          "featureType": "poi.park",
          "elementType": "geometry",
          "stylers": [
            { "color": "#181818" }
          ]
        },
        {
          "featureType": "poi.park",
          "elementType": "labels.text.fill",
          "stylers": [
            { "color": "#616161" }
          ]
        },
        {
          "featureType": "poi.park",
          "elementType": "labels.text.stroke",
          "stylers": [
            { "color": "#1b1b1b" }
          ]
        },
        {
          "featureType": "road",
          "elementType": "geometry.fill",
          "stylers": [
            { "color": "#2c2c2c" }
          ]
        },
        {
          "featureType": "road",
          "elementType": "labels.text.fill",
          "stylers": [
            { "color": "#8a8a8a" }
          ]
        },
        {
          "featureType": "road.arterial",
          "elementType": "geometry",
          "stylers": [
            { "color": "#373737" }
          ]
        },
        {
          "featureType": "road.highway",
          "elementType": "geometry",
          "stylers": [
            { "color": "#3c3c3c" }
          ]
        },
        {
          "featureType": "road.highway.controlled_access",
          "elementType": "geometry",
          "stylers": [
            { "color": "#4e4e4e" }
          ]
        },
        {
          "featureType": "road.local",
          "elementType": "labels.text.fill",
          "stylers": [
            { "color": "#616161" }
          ]
        },
        {
          "featureType": "transit",
          "elementType": "labels.text.fill",
          "stylers": [
            { "color": "#757575" }
          ]
        },
        {
          "featureType": "water",
          "elementType": "geometry",
          "stylers": [
            { "color": "#000000" }
          ]
        },
        {
          "featureType": "water",
          "elementType": "labels.text.fill",
          "stylers": [
            { "color": "#3d3d3d" }
          ]
        }
      ]
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialPosition,
            onMapCreated: _onMapCreated,
            polylines: _polylines,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.red)),

          // Top Search Bar Area
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Search locations',
                          hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                          prefixIcon: SizedBox(width: 16), // space
                          suffixIcon: Icon(Icons.search, color: Colors.black87),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavigationBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              icon: Icons.home_rounded,
              label: 'HOME',
              isActive: false,
              onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
            ),
            _buildNavItem(
              icon: Icons.location_on_rounded,
              label: 'MAP',
              isActive: true,
              onTap: () {}, // Current page
            ),
            _buildNavItem(
              icon: Icons.track_changes_rounded,
              label: 'CHALLENGE',
              isActive: false,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LeaderboardPage()),
                );
              },
            ),
            _buildNavItem(
              icon: Icons.ios_share_rounded,
              label: 'SHARE',
              isActive: false,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SharePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
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
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
