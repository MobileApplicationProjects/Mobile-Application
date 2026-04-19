import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/health_service.dart';
import '../services/auth_service.dart';
import 'challenge_page.dart';
import '../widgets/custom_bottom_nav_bar.dart';


class StreakPage extends StatefulWidget {
  const StreakPage({super.key});

  @override
  State<StreakPage> createState() => _StreakPageState();
}

class _StreakPageState extends State<StreakPage> {
  final HealthService _healthService = HealthService();
  bool _isLoading = true;
  bool _isAdmin = false;
  int _stepsToday = 0;
  int _streakCount = 0;
  int _totalActivities = 0;
  List<Map<String, dynamic>> _weeklyData = [];
  Map<DateTime, int> _allHealthData = {};
  
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isCalendarExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    
    // 1. Sync and load today's steps
    await _healthService.syncToday();
    final todayMetrics = await _healthService.fetchTodayMetrics();
    
    // 2. Load weekly data for pills
    final weekly = await _healthService.fetchWeeklyMetrics();
    
    // 3. Load yearly data for heatmap
    final yearlyRaw = await _healthService.fetchYearlyMetrics(DateTime.now().year);
    Map<DateTime, int> heatmapConverted = {};
    yearlyRaw.forEach((key, value) {
      try {
        heatmapConverted[DateTime.parse(key)] = value;
      } catch (_) {}
    });

    // 4. Fetch real streak from backend
    final currentStreak = await _healthService.fetchStreak();

    // 5. Check Admin Status
    bool isAdminUser = false;
    try {
      final response = await AuthService().getProfile();
      final profile = response['profile'] ?? {};
      isAdminUser = (profile['role'] == 'admin' || profile['is_admin'] == 1 || profile['is_admin'] == true);
    } catch (e) {
      print('Error checking admin status in StreakPage: $e');
    }

    if (mounted) {
      setState(() {
        _isAdmin = isAdminUser;
        _stepsToday = todayMetrics['steps'] ?? 0;
        _streakCount = currentStreak;
        _weeklyData = weekly;
        _allHealthData = heatmapConverted;
        _totalActivities = heatmapConverted.values.where((s) => s >= 3000).length;
        _isLoading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Streak',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : RefreshIndicator(
              onRefresh: _loadAllData,
              color: Colors.orange,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    _buildStreakCountCard(),
                    const SizedBox(height: 32),
                    _buildExpandableCalendarSection(),
                    const SizedBox(height: 32),
                    _buildTodayProgressCard(),
                    const SizedBox(height: 24),
                    _buildWarningContainer(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildExpandableCalendarSection() {
    return Column(
      children: [
        _buildWeeklyOverview(),
        if (_isCalendarExpanded) ...[
          const SizedBox(height: 16),
          _buildMonthlyCalendar(),
        ],
      ],
    );
  }

  Widget _buildStreakCountCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Image.asset(
            'assets/images/fire.png',
            width: 80,
            height: 80,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.local_fire_department,
              size: 80,
              color: Colors.orange,
            ),
          ),
          Column(
            children: [
              Text(
                '$_streakCount',
                style: TextStyle(
                  color: _streakCount < 3 ? Colors.grey : Colors.orange,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'Streak',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyOverview() {
    final now = DateTime.now();
    final days = List.generate(7, (index) => now.subtract(Duration(days: 6 - index)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMMM yyyy').format(now),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isCalendarExpanded = !_isCalendarExpanded;
                });
              },
              icon: Icon(
                _isCalendarExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.orange,
              ),
              label: Text(
                _isCalendarExpanded ? 'Close' : 'View Month',
                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: days.map((date) {
            final dateStr = DateFormat('dd/MM/yyyy').format(date);
            final dayData = _weeklyData.firstWhere(
              (d) => d['dateFormatted'] == dateStr,
              orElse: () => {'steps': 0},
            );
            
            int steps = dayData['steps'] ?? 0;
            if (DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(now)) {
              steps = _stepsToday;
            }

            return _buildDayPill(
              DateFormat('E').format(date)[0], 
              date.day.toString(), 
              steps >= 3000
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTodayProgressCard() {
    final double progress = (_stepsToday / 3000).clamp(0.0, 1.0);
    final bool isCompleted = _stepsToday >= 3000;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? Colors.green : Colors.orange),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Icon(
                      isCompleted ? Icons.check_circle_rounded : Icons.directions_run_rounded,
                      color: isCompleted ? Colors.green : Colors.orange,
                      size: 32,
                    )
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCompleted ? 'Unlocked!' : 'Streak Today',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_stepsToday / 3000 Step',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),
          Text(
            isCompleted 
              ? 'Great job! You\'ve maintained your streak for today.'
              : 'Complete all steps to unlock today\'s streak.',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyCalendar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_focusedDay),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.black),
                    onPressed: () {
                      setState(() {
                        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.black),
                    onPressed: () {
                      setState(() {
                        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            headerVisible: false,
            daysOfWeekHeight: 30,
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              weekendTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
              weekendStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                return _buildCalendarDay(day, false);
              },
              todayBuilder: (context, day, focusedDay) {
                return _buildCalendarDay(day, true);
              },
            ),
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(DateTime day, bool isToday) {
    int steps = 0;
    if (DateFormat('yyyy-MM-dd').format(day) == DateFormat('yyyy-MM-dd').format(DateTime.now())) {
      steps = _stepsToday;
    } else {
      steps = _allHealthData.entries
          .where((e) => e.key.year == day.year && e.key.month == day.month && e.key.day == day.day)
          .fold(0, (sum, e) => e.value);
    }
    
    final bool isCompleted = steps >= 3000;

    return Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isCompleted ? Colors.orange : Colors.grey[200],
          shape: BoxShape.circle,
          border: isToday && !isCompleted ? Border.all(color: Colors.orange, width: 2) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: isCompleted ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildWarningContainer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey[400], size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your streak will reset if you miss it for 2 consecutive days.',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayPill(String dayName, String dateNum, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Text(
            dayName,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isActive ? Colors.orange : Colors.grey[400],
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              dateNum,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
