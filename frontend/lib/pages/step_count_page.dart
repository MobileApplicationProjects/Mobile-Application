import 'package:flutter/material.dart';
import '../services/health_service.dart';
import 'set_goal_page.dart';

class ChartBarData {
  final String label;
  final double percent;
  final bool isHighlight;

  ChartBarData({
    required this.label,
    required this.percent,
    this.isHighlight = false,
  });
}

class StepCountPage extends StatefulWidget {
  final String initialTab;

  const StepCountPage({super.key, this.initialTab = 'W'});

  @override
  State<StepCountPage> createState() => _StepCountPageState();
}

class _StepCountPageState extends State<StepCountPage> {
  late String _activeTab;

  // Data State
  String _title = '';
  int _totalSteps = 0;
  double _totalCalories = 0;
  double _totalDistance = 0;
  int _currentGoal = 5000;
  List<ChartBarData> _chartData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _fetchGoal().then((_) => _fetchDataForTab(_activeTab));
  }

  Future<void> _fetchGoal() async {
    final goal = await HealthService().fetchGoal();
    if (mounted) setState(() => _currentGoal = goal);
  }

  Future<void> _fetchDataForTab(String tab) async {
    setState(() {
      _isLoading = true;
      _activeTab = tab;
    });

    final data = await HealthService().fetchSummary(tab);

    if (!mounted) return;

    if (data != null) {
      final bars = (data['chartBars'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final maxVal = bars.fold<double>(0, (m, b) => (b['value'] as num).toDouble() > m ? (b['value'] as num).toDouble() : m);
      final chartData = bars.asMap().entries.map((entry) {
        final i = entry.key;
        final b = entry.value;
        final v = (b['value'] as num).toDouble();
        final pct = maxVal > 0 ? v / maxVal : 0.0;
        return ChartBarData(
          label: b['label']?.toString() ?? '',
          percent: pct.clamp(0.0, 1.0),
          isHighlight: i == bars.length - 1,
        );
      }).toList();

      setState(() {
        _title = data['title'] ?? tab;
        _totalSteps = (data['steps'] as num?)?.toInt() ?? 0;
        _totalCalories = (data['calories'] as num?)?.toDouble() ?? 0;
        _totalDistance = (data['distance'] as num?)?.toDouble() ?? 0;
        _chartData = chartData;
        _isLoading = false;
      });
    } else {
      // fallback empty state
      setState(() {
        _title = tab == 'D' ? 'Today' : tab == 'W' ? 'This week' : tab == 'M' ? 'This month' : 'This year';
        _totalSteps = 0;
        _totalCalories = 0;
        _totalDistance = 0;
        _chartData = [];
        _isLoading = false;
      });
    }
  }

  String get _stepStr => _totalSteps.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  String get _calStr => '${_totalCalories.toStringAsFixed(0)} kcal';
  String get _distStr => '${_totalDistance.toStringAsFixed(1)} km';

  // avg steps per period
  String get _avgStepStr {
    if (_totalSteps == 0) return '0';
    int divider = 1;
    if (_activeTab == 'W') divider = 7;
    else if (_activeTab == 'M') divider = 30;
    else if (_activeTab == 'Y') divider = 365;
    final avg = (_totalSteps / divider).round();
    return avg.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1D),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- TOP APP BAR ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Text(
                    'Step Count',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // --- TABS (D/W/M/Y) ---
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTab('D'),
                    _buildTab('W'),
                    _buildTab('M'),
                    _buildTab('Y'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- CHART CARD ---
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildChartCard(),
                    const SizedBox(height: 24),

                    // -- GOAL & AVG INFO --
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your current goal',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentGoal.toString().replaceAllMapped(
                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                  (Match m) => '${m[1]},',
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Avg. step',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _avgStepStr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // -- SET GOAL BUTTON --
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: GestureDetector(
                          onTap: () async {
                            final newGoal = await Navigator.push<int>(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SetGoalPage(initialGoal: _currentGoal),
                              ),
                            );
                            // If a new goal was returned, refresh
                            if (newGoal != null && mounted) {
                              setState(() => _currentGoal = newGoal);
                            }
                            _fetchDataForTab(_activeTab);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[800],
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              'Set your goal',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildTab(String label) {
    final isActive = _activeTab == label;
    return GestureDetector(
      onTap: () => _fetchDataForTab(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(24),
      child: _isLoading
          ? const SizedBox(
              height: 250,
              child: Center(
                child: CircularProgressIndicator(color: Colors.red),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _title,
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatValue('Step', _stepStr),
                    _buildStatValue('Calories', _calStr),
                    _buildStatValue('Distance', _distStr),
                  ],
                ),
                const SizedBox(height: 40),
                // Bar Chart
                _chartData.isEmpty
                    ? SizedBox(
                        height: 120,
                        child: Center(
                          child: Text(
                            'No data yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 160,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: _chartData
                              .map(
                                (data) => _buildBar(
                                  data.label,
                                  data.percent,
                                  isHighlight: data.isHighlight,
                                ),
                              )
                              .toList(),
                        ),
                      ),
              ],
            ),
    );
  }

  Widget _buildStatValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBar(String day, double percent, {required bool isHighlight}) {
    // Ensure a minimum height so empty data still looks like a 0-state pill
    final double barHeight = (130 * percent) < 4 ? 4 : (130 * percent);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 25,
          height: barHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFD32F2F), // Red bars for all
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          day.toUpperCase(), 
          style: TextStyle(
            color: isHighlight ? Colors.orange[400] : Colors.grey[500], 
            fontSize: 12,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal
          )
        ),
        const SizedBox(height: 4),
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: isHighlight ? Colors.orange[400] : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  // Reused Bottom Navigation Bar
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
              onTap: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
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
