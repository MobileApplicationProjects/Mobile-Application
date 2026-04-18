import 'package:flutter/material.dart';
import '../services/health_service.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  bool _isLoading = true;

  // Data states
  Map<String, String> _avgActivity = {};
  Map<String, String> _maxActivity = {};
  Map<String, String> _tokenStats = {};

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await HealthService().fetchStatistics();
      
      if (stats != null) {
        setState(() {
          _avgActivity = {
            'Avg Step/Week': '${stats['avgStepsPerWeek'] ?? 0}',
            'Avg Calories/Week': '${stats['avgCaloriesPerWeek'] ?? 0}',
            'Avg Distance/Week': '${stats['avgDistancePerWeek'] ?? 0}',
          };
          _maxActivity = {
            'Max Step': '${stats['maxSteps'] ?? 0}',
            'Max Calories': '${stats['maxCalories'] ?? 0}',
            'Max Distance': '${stats['maxDistance'] ?? 0}',
          };
          _tokenStats = {
            'Avg token/day': '${stats['avgTokenPerDay'] ?? 0}',
            'Max token': '${stats['maxToken'] ?? 0}',
            'Max pay': '${stats['maxPay'] ?? 0}',
          };
          _isLoading = false;
        });
      } else {
        _setEmptyDefaults();
      }
    } catch (e) {
      _setEmptyDefaults();
    }
  }

  void _setEmptyDefaults() {
    setState(() {
      _avgActivity = {
        'Avg Step/Week': '0',
        'Avg Calories/Week': '0',
        'Avg Distance/Week': '0',
      };
      _maxActivity = {
        'Max Step': '0',
        'Max Calories': '0',
        'Max Distance': '0',
      };
      _tokenStats = {
        'Avg token/day': '0',
        'Max token': '0',
        'Max pay': '0',
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Statistics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.red),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  children: [
                    _buildStatCard(
                      title: 'Avg Activity',
                      rows: _avgActivity,
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      title: 'Max Activity',
                      rows: _maxActivity,
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      title: 'Token',
                      rows: _tokenStats,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildStatCard({
    required String title,
    required Map<String, String> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.orange[700],
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          ...rows.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      entry.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )).toList(),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
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
              isActive: true,
              onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
            ),
            _buildNavItem(
              icon: Icons.location_on_rounded,
              label: 'MAP',
              isActive: false,
              onTap: () {},
            ),
            _buildNavItem(
              icon: Icons.track_changes_rounded,
              label: 'CHALLENGE',
              isActive: false,
              onTap: () {},
            ),
            _buildNavItem(
              icon: Icons.ios_share_rounded,
              label: 'SHARE',
              isActive: false,
              onTap: () {},
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
