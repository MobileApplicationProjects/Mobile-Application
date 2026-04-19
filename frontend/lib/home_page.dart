import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'pages/rewards_page.dart';
import 'pages/streak_page.dart';
import 'pages/leaderboard_page.dart';
import 'pages/challenge_page.dart';
import 'services/auth_service.dart';
import 'services/health_service.dart';
import 'services/challenge_service.dart';
import 'services/room_service.dart';
import 'services/notification_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'pages/map_page.dart';
import 'pages/share_page.dart';
import 'widgets/profile_avatar.dart';
import 'widgets/custom_bottom_nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _firstName = '...';
  String _role = 'user'; // 'admin' or 'user'
  int _steps = 0;
  double _calories = 0.0;
  double _distanceKm = 0.0;
  int _currentBalance = 0;
  int _streakCount = 0;
  String? _avatarUrl;
  String _userId = '';
  int _stepGoal = 5000; // loaded from DB

  Map<String, dynamic>? _latestChallenge;
  final ChallengeService _challengeService = ChallengeService();
  final RoomService _roomService = RoomService();
  final NotificationService _notificationService = NotificationService();
  bool _isClaiming = false;
  bool _isLoadingChallenge = true;

  // Leaderboard state
  List<dynamic> _rooms = [];
  List<dynamic> _leaderboardData = [];
  String _leaderboardRoomName = '';
  int _userRank = 0;
  int _userSteps = 0;
  bool _isLoadingLeaderboard = true;

  @override
  void initState() {
    super.initState();
    _initNotification();
    // Use an async method to ensure _loadProfile completes first so _userId is ready
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadProfile();
    // After profile is loaded, load the rest concurrently
    await Future.wait([
      _loadHealthData(),
      _loadLatestChallenge(),
      _loadLeaderboardForCard(),
      _loadGoal(),
      _loadBalance(),
    ]);
  }

  Future<void> _initNotification() async {
    await _notificationService.init();
    await _notificationService.requestPermissions();
  }

  Future<void> _loadHealthData() async {
    final healthData = await HealthService().fetchTodayMetrics();
    final streak = await HealthService().fetchStreak();
    if (mounted) {
      setState(() {
        _steps = healthData['steps'] ?? 5000;
        _calories = (healthData['calories'] ?? 0.0).toDouble();

        // Convert distance from meters to km and format to 1 decimal place
        double meters = (healthData['distance'] ?? 0.0).toDouble();
        _distanceKm = meters / 1000.0;
        _streakCount = streak;
      });
      // Detect completion after health data loaded
      _checkChallengeCompletion();
    }
  }

  Future<void> _loadGoal() async {
    final goal = await HealthService().fetchGoal();
    if (mounted) setState(() => _stepGoal = goal);
  }

  Future<void> _loadBalance() async {
    final balance = await AuthService().fetchBalance();
    if (mounted) setState(() => _currentBalance = balance);
  }

  Future<void> _loadLatestChallenge() async {
    setState(() => _isLoadingChallenge = true);
    try {
      final challenge = await _challengeService.getLatestChallenge();
      if (mounted) {
        setState(() {
          _latestChallenge = challenge;
          _isLoadingChallenge = false;
        });
        // Check once loaded
        if (challenge != null) _checkChallengeCompletion();
      }
    } catch (e) {
      debugPrint('Error loading latest challenge: $e');
      if (mounted) setState(() => _isLoadingChallenge = false);
    }
  }

  Future<void> _checkChallengeCompletion() async {
    if (_latestChallenge == null || _isClaiming) return;

    // Check if already claimed
    if (_latestChallenge!['user_status'] == 'Claimed') return;

    final targetType =
        _latestChallenge!['target_type']; // 'Steps', 'Distance', 'Time'
    final targetValue = (_latestChallenge!['target_value'] as num).toInt();

    bool isCompleted = false;
    if (targetType == 'Steps' && _steps >= targetValue) {
      isCompleted = true;
    } else if (targetType == 'Distance' &&
        (_distanceKm * 1000) >= targetValue) {
      isCompleted = true;
    }

    if (isCompleted) {
      _autoClaimChallenge();
    }
  }

  Future<void> _autoClaimChallenge() async {
    if (_isClaiming) return;
    setState(() => _isClaiming = true);

    try {
      final result = await _challengeService.claimChallenge(
        _latestChallenge!['id'],
      );
      if (mounted) {
        // Show notification
        await _notificationService.showNotification(
          title: 'Challenge สำเร็จ! 🎉',
          body:
              'คุณได้รับ ${_latestChallenge!['reward_amount']} Token จากภารกิจ ${_latestChallenge!['title']}',
        );

        setState(() {
          _currentBalance =
              (result['newBalance'] as num?)?.toInt() ??
              (_currentBalance +
                  (_latestChallenge!['reward_amount'] as num).toInt());
          _latestChallenge!['user_status'] = 'Claimed';
          _isClaiming = false;
        });
      }
    } catch (e) {
      debugPrint('Error claiming challenge: $e');
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  Future<void> _loadProfile() async {
    try {
      final authService = AuthService();
      final result = await authService.getProfile();
      if (mounted) {
        setState(() {
          _firstName = result['profile']['firstName'] ?? 'User';
          _role = result['profile']['role'] ?? 'user';
          _currentBalance = result['profile']['currentBalance'] ?? 0;
          _avatarUrl = result['profile']['avatarUrl'];
          _userId = result['profile']['id'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _firstName = 'User';
          _role = 'user';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1D),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
      body: SafeArea(
        child: RefreshIndicator(
          color: Colors.red[700],
          backgroundColor: Colors.white,
          onRefresh: () async {
            await Future.wait([
              _loadProfile(),
              _loadHealthData(),
              _loadLatestChallenge(),
              _loadLeaderboardForCard(),
              _loadGoal(),
              _loadBalance(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- TOP BAR SECTION ---
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfilePage(),
                      ),
                    ).then((_) {
                      // Reload when returning from Profile/Settings/Admin
                      _loadProfile();
                      _loadLatestChallenge();
                    });
                  },
                  child: Row(
                    children: [
                      ProfileAvatar(
                        avatarUrl: _avatarUrl,
                        radius: 26,
                        backgroundColor: Colors.grey[800],
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $_firstName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Keep Going',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
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
                            const SizedBox(width: 4),
                            Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.amber,
                              ),
                              child: const Icon(
                                Icons.monetization_on,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // --- TODAY ACTIVITY SECTION ---
                GestureDetector(
                  onTap: () {
                    // TODO: Link to activity page
                  },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0F0F),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildActivityRing(
                              value: _stepGoal > 0
                                  ? (_steps / _stepGoal).clamp(0.0, 1.0)
                                  : 0.0,
                              icon: Icons.directions_run_rounded,
                              iconColor: Colors.red[400]!,
                              valueText:
                                  '${_steps.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}',
                              titleText: 'Step',
                              subtitleText: 'Goal $_stepGoal',
                              ringColor: Colors.orange[800]!,
                            ),
                            _buildActivityRing(
                              value: (_calories / 500.0).clamp(
                                0.0,
                                1.0,
                              ), // Assuming 500 kcal is goal
                              icon: Icons.local_fire_department_rounded,
                              iconColor: Colors.red[400]!,
                              valueText: '${_calories.toStringAsFixed(0)} kcal',
                              titleText: 'Calories',
                              ringColor: Colors.orange[800]!,
                            ),
                            _buildActivityRing(
                              value: (_distanceKm / 5.0).clamp(
                                0.0,
                                1.0,
                              ), // Assuming 5 km is goal
                              icon: Icons.arrow_forward_rounded,
                              iconColor: Colors.red[400]!,
                              valueText: '${_distanceKm.toStringAsFixed(1)} km',
                              titleText: 'Distance',
                              ringColor: Colors.orange[800]!,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- REWARDS & STREAK SECTION ---
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RewardsPage(
                                isAdmin: _role == 'admin',
                                currentBalance: _currentBalance,
                              ),
                            ),
                          ).then((_) {
                            _loadProfile(); // Reload balance
                          });
                        },
                        child: _buildCard(
                          imagePath: 'assets/images/medal.png',
                          topText: '$_currentBalance Token',
                          bottomText: 'Rewards',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StreakPage(),
                            ),
                          ).then((_) {
                            _loadHealthData(); // Reload streak
                          });
                        },
                        child: _buildCard(
                          imagePath: 'assets/images/fire.png',
                          topText: '$_streakCount days',
                          bottomText: 'Streak',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- LEADERBOARD CARD ---
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LeaderboardPage(),
                      ),
                    ).then((_) {
                      _loadLeaderboardForCard(); // Reload leaderboard data
                    });
                  },
                  child: _buildLeaderboardCard(),
                ),

                const SizedBox(height: 24),

                // --- CHALLENGE CARD ---
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ChallengePage(isAdmin: _role == 'admin'),
                      ),
                    ).then((_) {
                      _loadLatestChallenge();
                    });
                  },
                  child: _buildChallengeCard(),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
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
                  // block ของ ring
                  value: value,
                  strokeWidth: 10, // ขนาดของ ring activity
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
          // Add spacing if no subtitle so it aligns well
          const SizedBox(height: 15),
        ],
      ],
    );
  }

  Widget _buildCard({
    required String imagePath,
    required String topText,
    required String bottomText,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF333333), Color(0xFF151515)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                imagePath,
                width: 65,
                height: 65,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  width: 65,
                  height: 65,
                  child: Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    topText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            bottomText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _loadLeaderboardForCard() async {
    setState(() => _isLoadingLeaderboard = true);
    try {
      final rooms = await _roomService.listRooms();
      _rooms = rooms;

      // Find all accepted rooms
      final acceptedRooms = rooms
          .where((r) => r['member_status'] == 'accepted')
          .toList();

      if (acceptedRooms.isNotEmpty) {
        // Fetch leaderboards for all accepted rooms concurrently
        final leaderboardsData = await Future.wait(
          acceptedRooms.map((room) async {
            try {
              final data = await _roomService.getLeaderboard(room['id']);
              final leaderboard = data['leaderboard'] as List<dynamic>? ?? [];

              int rank = 0;
              int steps = 0;
              for (int i = 0; i < leaderboard.length; i++) {
                if (leaderboard[i]['user_id'] == _userId) {
                  rank = i + 1;
                  steps = (leaderboard[i]['total_steps'] as num).toInt();
                  break;
                }
              }
              return {
                'room': room,
                'leaderboard': leaderboard,
                'rank': rank,
                'steps': steps,
              };
            } catch (e) {
              return null;
            }
          }),
        );

        // Filter out any errors during fetch
        final validResults = leaderboardsData
            .where((res) => res != null)
            .cast<Map<String, dynamic>>()
            .toList();

        if (validResults.isNotEmpty) {
          // Sort to find the room where the user has the "highest" (best) rank.
          // Rank 1 is better than Rank 2. If unranked (0), treat as worst (999999).
          // If rank is tied, sort by steps descending (largest steps first).
          validResults.sort((a, b) {
            int rankA = a['rank'] as int;
            int rankB = b['rank'] as int;
            int stepsA = a['steps'] as int;
            int stepsB = b['steps'] as int;

            if (rankA == 0) rankA = 999999;
            if (rankB == 0) rankB = 999999;

            final rankComparison = rankA.compareTo(rankB);
            if (rankComparison != 0) return rankComparison;

            return stepsB.compareTo(stepsA);
          });

          final bestResult = validResults.first;

          if (mounted) {
            setState(() {
              _leaderboardData = bestResult['leaderboard'] as List<dynamic>;
              _leaderboardRoomName = bestResult['room']['name'] ?? '';
              _userRank = bestResult['rank'] as int;
              _userSteps = bestResult['steps'] as int;
              _isLoadingLeaderboard = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _leaderboardData = [];
              _leaderboardRoomName = '';
              _userRank = 0;
              _userSteps = 0;
              _isLoadingLeaderboard = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _leaderboardData = [];
            _leaderboardRoomName = '';
            _userRank = 0;
            _userSteps = 0;
            _isLoadingLeaderboard = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading leaderboard for card: $e');
      if (mounted) setState(() => _isLoadingLeaderboard = false);
    }
  }

  Widget _buildLeaderboardCard() {
    // Loading state
    if (_isLoadingLeaderboard) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: SizedBox(
            height: 80,
            child: Center(
              child: CircularProgressIndicator(color: Colors.black),
            ),
          ),
        ),
      );
    }

    // No rooms / no data state
    final bool hasData = _leaderboardData.isNotEmpty;
    final String roomLabel = _leaderboardRoomName.isNotEmpty
        ? '($_leaderboardRoomName)'
        : '';

    // Format steps with commas
    String formatSteps(int steps) {
      return steps.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset('assets/images/chart.png', width: 40, height: 40),
              const Text(
                'Leader board',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (roomLabel.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    roomLabel,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const Spacer(),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.black,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE0E0E0), height: 1),
          const SizedBox(height: 16),
          if (!hasData)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No leaderboard data yet. Join or create a room!',
                style: TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            )
          else
            Row(
              children: [
                Text(
                  _userRank > 0 ? '$_userRank' : '-',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 16),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                      ? NetworkImage(_avatarUrl!)
                      : null,
                  child: _avatarUrl == null || _avatarUrl!.isEmpty
                      ? const Icon(Icons.person, size: 20, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                const Text(
                  '(You)',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${formatSteps(_userSteps)} Step',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDot(isActive: true),
              const SizedBox(width: 6),
              _buildDot(isActive: false),
              const SizedBox(width: 6),
              _buildDot(isActive: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard() {
    if (_isLoadingChallenge) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.black),
        ),
      );
    }

    final bool hasChallenge = _latestChallenge != null;
    final bool isClaimed =
        hasChallenge && _latestChallenge!['user_status'] == 'Claimed';

    final title = hasChallenge ? _latestChallenge!['title'] : 'ไม่มี Challenge';
    final description = hasChallenge
        ? (_latestChallenge!['description'] ?? 'ไม่มีรายละเอียด')
        : 'คุณทำภารกิจเสร็จหมดแล้ว หรือยังไม่มีภารกิจใหม่';
    final reward = hasChallenge ? _latestChallenge!['reward_amount'] : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset('assets/images/target.png', width: 40, height: 40),
              const SizedBox(width: 12),
              const Text(
                'Challenge',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (isClaimed)
                const Icon(Icons.check_circle, color: Colors.green, size: 24)
              else
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.black,
                  size: 24,
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE0E0E0), height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$reward',
                    style: TextStyle(
                      color: isClaimed
                          ? Colors.green
                          : (hasChallenge ? Colors.black : Colors.grey[400]),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasChallenge ? Colors.amber : Colors.grey[300],
                    ),
                    child: const Icon(
                      Icons.monetization_on,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDot(isActive: true),
              const SizedBox(width: 6),
              _buildDot(isActive: false),
              const SizedBox(width: 6),
              _buildDot(isActive: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDot({required bool isActive}) {
    return Container(
      height: 6,
      width: 6,
      decoration: BoxDecoration(
        color: isActive ? Colors.grey[600] : Colors.grey[400],
        shape: BoxShape.circle,
      ),
    );
  }
}
