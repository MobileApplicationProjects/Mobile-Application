import 'package:flutter/material.dart';
import '../services/health_service.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class SetGoalPage extends StatefulWidget {
  final int initialGoal;

  const SetGoalPage({super.key, this.initialGoal = 5000});

  @override
  State<SetGoalPage> createState() => _SetGoalPageState();
}

class _SetGoalPageState extends State<SetGoalPage> {
  late int _currentGoal;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentGoal = widget.initialGoal;
    // Also fetch from DB to make sure we show the latest
    _fetchCurrentGoal();
  }

  Future<void> _fetchCurrentGoal() async {
    final goal = await HealthService().fetchGoal();
    if (mounted) setState(() => _currentGoal = goal);
  }

  Future<void> _saveGoal() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final success = await HealthService().saveGoal(_currentGoal);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Goal saved: $_currentGoal steps/day'),
          backgroundColor: Colors.green[700],
        ),
      );
      // Return the new goal to the caller
      Navigator.pop(context, _currentGoal);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save goal. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _increaseGoal() {
    setState(() => _currentGoal += 500);
  }

  void _decreaseGoal() {
    if (_currentGoal > 500) {
      setState(() => _currentGoal -= 500);
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
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
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
                    "Set your goal based on how active\nyou'd like to be, each day.",
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
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.red[800],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.remove,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),

                        const SizedBox(width: 32),

                        // Goal Number
                        Text(
                          _currentGoal.toString().replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                            (Match m) => '${m[1]},',
                          ),
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
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.red[800],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 22,
                            ),
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
                    const SizedBox(height: 48),

                    // --- SAVE BUTTON ---
                    GestureDetector(
                      onTap: _isSaving ? null : _saveGoal,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _isSaving ? Colors.grey : Colors.red[800],
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Goal',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
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
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }
}
