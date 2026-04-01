import 'package:flutter/material.dart';

class SetGoalPage extends StatefulWidget {
  final int initialGoal;
  
  const SetGoalPage({
    super.key,
    this.initialGoal = 5000,
  });

  @override
  State<SetGoalPage> createState() => _SetGoalPageState();
}

class _SetGoalPageState extends State<SetGoalPage> {
  late int _currentGoal;

  @override
  void initState() {
    super.initState();
    _currentGoal = widget.initialGoal;
    _fetchCurrentGoal();
  }

  // [API MOCK] ดึงข้อมูลเป้าหมายเดิมจากฐานข้อมูล (table: user_settings -> step_goal_daily)
  Future<void> _fetchCurrentGoal() async {
    // TODO: เรียก API get_user_settings เพื่อนำเป้าหมายปัจจุบันมาโชว์
    // final response = await http.get(Uri.parse('api/settings'));
    // setState(() { _currentGoal = response.data.step_goal_daily; });
  }

  // [API MOCK] อัปเดตเป้าหมายไปยังฐานข้อมูล 
  Future<void> _updateGoal(int newGoal) async {
    // TODO: เรียก API update_user_settings.step_goal_daily
    // await http.post('api/settings/update', body: {'step_goal_daily': newGoal});
    print('Mock API: Goal updated to $newGoal');
  }

  void _increaseGoal() {
    setState(() {
      _currentGoal += 500;
    });
    _updateGoal(_currentGoal);
  }

  void _decreaseGoal() {
    if (_currentGoal > 500) {
      setState(() {
        _currentGoal -= 500;
      });
      _updateGoal(_currentGoal);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1D),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- TOP BAR ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // --- HEADER TEXT ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Step Goal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Set your goal base how active\nyou'd like to be, each day.",
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),

            // --- GOAL SETTER AREA ---
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Minus Button
                        GestureDetector(
                          onTap: _decreaseGoal,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.red[800],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.remove, color: Colors.white),
                          ),
                        ),
                        
                        const SizedBox(width: 32),
                        
                        // Goal Number
                        Text(
                          '${_currentGoal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        
                        const SizedBox(width: 32),
                        
                        // Plus Button
                        GestureDetector(
                          onTap: _increaseGoal,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.red[800],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Step/day',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
