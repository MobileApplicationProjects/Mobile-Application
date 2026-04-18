import 'package:flutter/material.dart';
import 'pages/settings_page.dart';
import 'pages/statistics_page.dart';
import 'pages/token_history_page.dart';
import 'pages/leaderboard_page.dart';
import 'pages/step_count_page.dart';
import 'services/auth_service.dart';
import 'services/health_service.dart';
import 'widgets/profile_avatar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;

  String _firstName = '';
  String _lastName = '';
  String? _avatarUrl;
  int _currentBalance = 0;
  int _steps = 0;
  double _calories = 0.0;
  double _distanceKm = 0.0;

  int _goldTrophies = 0;
  int _silverTrophies = 0;
  int _bronzeTrophies = 0;

  // Weekly bar chart data
  List<double> _weeklySteps = [0, 0, 0, 0, 0, 0, 0];
  List<String> _weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  int _activeDay = 6;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final authService = AuthService();
      final result = await authService.getProfile();
      final profile = result['profile'];

      final summary = await HealthService().fetchSummary('W');

      if (mounted) {
        setState(() {
          _firstName = profile['firstName'] ?? '';
          _lastName = profile['lastName'] ?? '';
          _avatarUrl = profile['avatarUrl'];
          _currentBalance = profile['currentBalance'] ?? 0;
          _goldTrophies = profile['goldTrophies'] ?? 0;
          _silverTrophies = profile['silverTrophies'] ?? 0;
          _bronzeTrophies = profile['bronzeTrophies'] ?? 0;
          
          if (summary != null) {
            _steps = (summary['steps'] as num?)?.toInt() ?? 0;
            _calories = (summary['calories'] as num?)?.toDouble() ?? 0.0;
            _distanceKm = (summary['distance'] as num?)?.toDouble() ?? 0.0;
            
            final bars = (summary['chartBars'] as List?)?.cast<Map<String, dynamic>>() ?? [];
            if (bars.isNotEmpty) {
              _weeklySteps = bars.map((b) => (b['value'] as num).toDouble()).toList();
              _weekDays = bars.map((b) => b['label']?.toString() ?? '').toList();
              _activeDay = bars.length - 1;
            }
          }
          _isLoading = false;
        });
        // Refresh balance from wallet (source of truth)
        final balance = await authService.fetchBalance();
        if (mounted) setState(() => _currentBalance = balance);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _firstName = 'User';
          _lastName = '';
          _isLoading = false;
        });
      }
    }
  }

  String get _fullName => '$_firstName $_lastName'.trim();

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1D1D1D),
        body: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1D),
      body: SafeArea(
        child: Column(
          children: [
            // ─── App Bar ───
            _buildAppBar(),

            // ─── Scrollable Content ───
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // User info row
                    _buildUserInfoRow(),
                    const SizedBox(height: 16),

                    // "This week" activity chart card
                    _buildWeeklyCard(),
                    const SizedBox(height: 12),

                    // Statistics button
                    _buildMenuTile(
                      icon: Icons.bar_chart_rounded,
                      label: 'Statistics',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StatisticsPage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Token History button
                    _buildMenuTile(
                      icon: Icons.history_rounded,
                      label: 'Token History',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TokenHistoryPage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Leader Board Trophy section
                    _buildTrophySection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  App Bar: ← Profile ⚙
  // ─────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 26,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.settings_rounded,
              color: Colors.white,
              size: 26,
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
              // Refresh profile in case avatar / name changed in Settings
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  User info: avatar + "Good Day! Name" + token
  // ─────────────────────────────────────────────
  Widget _buildUserInfoRow() {
    return Row(
      children: [
        ProfileAvatar(
          avatarUrl: _avatarUrl,
          radius: 28,
          backgroundColor: Colors.grey[800],
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Day!',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            Text(
              _fullName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Token balance pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Text(
                '$_currentBalance',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber,
                ),
                child: const Icon(
                  Icons.monetization_on,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  "This week" card with bar chart
  // ─────────────────────────────────────────────
  Widget _buildWeeklyCard() {
    final maxStep = _weeklySteps.reduce((a, b) => a > b ? a : b);
    const double barMaxHeight = 90.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const StepCountPage(initialTab: 'W'),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(20),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'This week',
            style: TextStyle(
              color: Colors.red[400],
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),

          // Stats row: Step | Calories | Distance
          Row(
            children: [
              _buildStatLabel(
                'Step',
                _steps
                    .toString()
                    .replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ','),
              ),
              const SizedBox(width: 24),
              _buildStatLabel(
                'Calories',
                '${_calories.toStringAsFixed(0)} kcal',
              ),
              const SizedBox(width: 24),
              _buildStatLabel(
                'Distance',
                '${_distanceKm.toStringAsFixed(1)} km',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bar chart
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_weeklySteps.length, (i) {
              final ratio = maxStep > 0 ? _weeklySteps[i] / maxStep : 0.0;
              final isActive = i == _activeDay;
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Bar
                  Container(
                    width: 30,
                    height: (barMaxHeight * ratio).clamp(4.0, barMaxHeight),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.amber[600]
                          : Colors.red[800],
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Day label
                  Text(
                    _weekDays[i],
                    style: TextStyle(
                      color: isActive
                          ? Colors.amber[500]
                          : Colors.grey[600],
                      fontSize: 11,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildStatLabel(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  Menu tile (Statistics / Token History)
  // ─────────────────────────────────────────────
  Widget _buildMenuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Leader Board Trophy section
  // ─────────────────────────────────────────────
  Widget _buildTrophySection() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LeaderboardPage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/images/trophy.png',
                  width: 36,
                  height: 36,
                  errorBuilder: (ctx, err, st) => const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.amber,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Leader Board Trophy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTrophyItem(
                  imagePath: 'assets/images/gold_medal.png',
                  fallbackColor: Colors.amber,
                  label: '$_goldTrophies win',
                ),
                _buildTrophyItem(
                  imagePath: 'assets/images/silver_medal.png',
                  fallbackColor: Colors.grey,
                  label: '$_silverTrophies win',
                ),
                _buildTrophyItem(
                  imagePath: 'assets/images/bronze_medal.png',
                  fallbackColor: Colors.orange,
                  label: '$_bronzeTrophies win',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrophyItem({
    required String imagePath,
    required Color fallbackColor,
    required String label,
  }) {
    return Column(
      children: [
        Image.asset(
          imagePath,
          width: 58,
          height: 58,
          errorBuilder: (ctx, err, st) => Icon(
            Icons.emoji_events_rounded,
            color: fallbackColor,
            size: 52,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
