import 'package:flutter/material.dart';
import 'set_goal_page.dart';

class ChartBarData {
  final String label;
  final double percent;
  final bool isHighlight;

  ChartBarData({required this.label, required this.percent, this.isHighlight = false});
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
  String _stepStr = '0';
  String _calStr = '0 kcal';
  String _distStr = '0 km';
  String _avgStepStr = '0';
  int _currentGoal = 5000;
  List<ChartBarData> _chartData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _fetchDataForTab(_activeTab);
  }

  // [API MOCK] ดึงสถิติตามระยะเวลา D, W, M, Y
  Future<void> _fetchDataForTab(String tab) async {
    setState(() {
      _isLoading = true;
      _activeTab = tab;
    });

    // TODO: เรีย่น API เพื่อดึงของมูลกราฟและสรุปของแต่ละช่วงเวลา
    // e.g. /api/activities/summary?period=W

    // จำลองการ delay ของเ API
    await Future.delayed(const Duration(milliseconds: 100));

    setState(() {
      if (tab == 'D') {
        _title = 'Today';
        _stepStr = '3,000';
        _calStr = '32 kcal';
        _distStr = '1.2 km';
        _avgStepStr = '300';
        _chartData = [
          ChartBarData(label: '6', percent: 0.1),
          ChartBarData(label: '12', percent: 0.8),
          ChartBarData(label: '18', percent: 0.5),
          ChartBarData(label: '24', percent: 0.3, isHighlight: true),
        ];
      } else if (tab == 'W') {
        _title = 'This week';
        _stepStr = '10,000';
        _calStr = '900 kcal';
        _distStr = '6 km';
        _avgStepStr = '1,500';
        _chartData = [
          ChartBarData(label: 'S', percent: 0.5),
          ChartBarData(label: 'M', percent: 0.6),
          ChartBarData(label: 'T', percent: 0.9),
          ChartBarData(label: 'W', percent: 0.55),
          ChartBarData(label: 'T', percent: 0.65),
          ChartBarData(label: 'F', percent: 0.65),
          ChartBarData(label: 'S', percent: 1.0, isHighlight: true),
        ];
      } else if (tab == 'M') {
        _title = 'This month';
        _stepStr = '52,000';
        _calStr = '4,700 kcal';
        _distStr = '35 km';
        _avgStepStr = '2,400';
        _chartData = [
          ChartBarData(label: '5', percent: 0.4),
          ChartBarData(label: '10', percent: 0.5),
          ChartBarData(label: '15', percent: 0.6),
          ChartBarData(label: '20', percent: 0.9),
          ChartBarData(label: '25', percent: 0.7),
          ChartBarData(label: '30', percent: 1.0, isHighlight: true),
        ];
      } else if (tab == 'Y') {
        _title = 'This year';
        _stepStr = '605,000';
        _calStr = '55,000 kcal';
        _distStr = '350 km';
        _avgStepStr = '26,000';
        _chartData = [
          ChartBarData(label: 'J', percent: 0.3),
          ChartBarData(label: 'F', percent: 0.4),
          ChartBarData(label: 'M', percent: 0.8),
          ChartBarData(label: 'A', percent: 0.6),
          ChartBarData(label: 'M', percent: 0.5),
          ChartBarData(label: 'J', percent: 0.4),
          ChartBarData(label: 'J', percent: 1.0, isHighlight: true),
        ];
      }
      _isLoading = false;
    });
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
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              Text('Your current goal', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                '${_currentGoal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}', 
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Your Avg. step', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                _avgStepStr, 
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
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
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SetGoalPage(initialGoal: _currentGoal)),
                            );
                            // Refresh data when returning, in case goal was changed
                            _fetchDataForTab(_activeTab);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
            child: Center(child: CircularProgressIndicator(color: Colors.red))
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
            // Bar Chart Custom UI
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: _chartData.map((data) => _buildBar(data.label, data.percent, isHighlight: data.isHighlight)).toList(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 3,
                    height: double.infinity,
                    color: Colors.grey[200],
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('3000', style: TextStyle(color: Colors.grey, fontSize: 10)),
                      Text('1500', style: TextStyle(color: Colors.grey, fontSize: 10)),
                      Text('0', style: TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                ],
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 30, // Adaptive size based on screen, row handles spacing
          height: 130 * percent,
          decoration: BoxDecoration(
            color: isHighlight ? Colors.orange[700] : const Color(0xFF8B0000),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 10),
        Text(day, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
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
            _buildNavItem(icon: Icons.location_on_rounded, label: 'MAP', isActive: false, onTap: () {}),
            _buildNavItem(icon: Icons.track_changes_rounded, label: 'CHALLENGE', isActive: false, onTap: () {}),
            _buildNavItem(icon: Icons.ios_share_rounded, label: 'SHARE', isActive: false, onTap: () {}),
          ],
        ),
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
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
