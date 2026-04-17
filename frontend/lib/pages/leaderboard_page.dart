import 'package:flutter/material.dart';
import '../services/room_service.dart';
import '../services/auth_service.dart';
import '../widgets/create_room_dialog.dart';
import '../widgets/profile_avatar.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final RoomService _roomService = RoomService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  String _currentUserId = '';
  List<dynamic> _rooms = [];
  dynamic _selectedRoom;
  List<dynamic> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      final profileResponse = await _authService.getProfile();
      _currentUserId = profileResponse['profile']['id'];
      await _loadRooms();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);
    try {
      final rooms = await _roomService.listRooms();
      setState(() {
        _rooms = rooms;
        if (_rooms.isNotEmpty && _selectedRoom == null) {
          _selectedRoom = _rooms.first;
        } else if (_rooms.isNotEmpty && _selectedRoom != null) {
          // Re-select the room to keep state
          _selectedRoom = _rooms.firstWhere(
            (r) => r['id'] == _selectedRoom['id'],
            orElse: () => _rooms.first,
          );
        }
      });
      if (_selectedRoom != null) {
        await _loadLeaderboard(_selectedRoom['id']);
      } else {
        setState(() {
          _leaderboard = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading rooms: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLeaderboard(String roomId) async {
    setState(() => _isLoading = true);
    try {
      final data = await _roomService.getLeaderboard(roomId);
      setState(() {
        _leaderboard = data['leaderboard'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateRoomDialog() {
    // Capture the scaffold messenger before potentially losing context
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => CreateRoomDialog(
        onSubmit: (name, duration, invites) async {
          Navigator.pop(dialogContext);
          if (!mounted) return;
          setState(() => _isLoading = true);
          try {
            await _roomService.createRoom(
              name: name,
              durationDays: duration,
              invites: invites,
            );
            messenger.showSnackBar(
              const SnackBar(content: Text('Room created successfully!')),
            );
            if (!mounted) return;
            await _loadRooms();
          } catch (e) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            messenger.showSnackBar(SnackBar(content: Text(e.toString())));
          }
        },
      ),
    );
  }

  Future<void> _acceptInvite() async {
    if (_selectedRoom == null) return;
    setState(() => _isLoading = true);
    try {
      await _roomService.acceptInvite(_selectedRoom['id']);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invite accepted!')));
      await _loadRooms();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar Equivalent
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Leaderboard',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                      ),
                      onPressed: _showCreateRoomDialog,
                    ),
                  ],
                ),
              ),

              // Room Selector
              if (_rooms.isEmpty && !_isLoading)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.groups,
                          size: 80,
                          color: Colors.white54,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'You are not in any rooms.',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _showCreateRoomDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                          ),
                          child: const Text(
                            'Create a Room',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              else ...[
                // Room Dropdown
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<dynamic>(
                      dropdownColor: Colors.black87,
                      value: _selectedRoom,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      isExpanded: true,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedRoom = newValue;
                        });
                        _loadLeaderboard(newValue['id']);
                      },
                      items: _rooms.map<DropdownMenuItem<dynamic>>((room) {
                        bool isInvited = room['member_status'] == 'invited';
                        return DropdownMenuItem<dynamic>(
                          value: room,
                          child: Text(
                            '${room['name']} ${isInvited ? '(Invite)' : ''}',
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                if (_selectedRoom != null &&
                    _selectedRoom['member_status'] == 'invited')
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: _acceptInvite,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                      ),
                      child: const Text(
                        'Accept Invite to View Leaderboard',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else ...[
                  const SizedBox(height: 32),
                  // Podium Section (Modern Styling)
                  SizedBox(
                    height: 260,
                    child: _leaderboard.isEmpty
                        ? const Center(
                            child: Text(
                              'No data yet',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              // Rank 2 (Left)
                              if (_leaderboard.length > 1)
                                Positioned(
                                  left:
                                      MediaQuery.of(context).size.width * 0.12,
                                  bottom: 20,
                                  child: _buildPodiumAvatar(
                                    imageUrl:
                                        _leaderboard[1]['avatar_url'] ??
                                        'https://i.pravatar.cc/150?u=${_leaderboard[1]['user_id']}',
                                    name:
                                        _leaderboard[1]['username'] ??
                                        _leaderboard[1]['first_name'],
                                    score: '${_leaderboard[1]['total_steps']}',
                                    rank: 2,
                                    avatarSize: 100,
                                  ),
                                ),

                              // Rank 3 (Right)
                              if (_leaderboard.length > 2)
                                Positioned(
                                  right:
                                      MediaQuery.of(context).size.width * 0.12,
                                  bottom: 0,
                                  child: _buildPodiumAvatar(
                                    imageUrl:
                                        _leaderboard[2]['avatar_url'] ??
                                        'https://i.pravatar.cc/150?u=${_leaderboard[2]['user_id']}',
                                    name:
                                        _leaderboard[2]['username'] ??
                                        _leaderboard[2]['first_name'],
                                    score: '${_leaderboard[2]['total_steps']}',
                                    rank: 3,
                                    avatarSize: 95,
                                  ),
                                ),

                              // Rank 1 (Center)
                              if (_leaderboard.isNotEmpty)
                                Positioned(
                                  bottom: 50,
                                  child: _buildPodiumAvatar(
                                    imageUrl:
                                        _leaderboard[0]['avatar_url'] ??
                                        'https://i.pravatar.cc/150?u=${_leaderboard[0]['user_id']}',
                                    name:
                                        _leaderboard[0]['username'] ??
                                        _leaderboard[0]['first_name'],
                                    score: '${_leaderboard[0]['total_steps']}',
                                    rank: 1,
                                    avatarSize: 140,
                                  ),
                                ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 32),

                  // Ranks List
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _leaderboard.length > 3
                            ? _leaderboard.length - 3
                            : 0,
                        itemBuilder: (context, index) {
                          final userIndex = index + 3;
                          final u = _leaderboard[userIndex];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildRankCard(
                              rank: '${userIndex + 1}',
                              imageUrl:
                                  u['avatar_url'] ??
                                  'https://i.pravatar.cc/150?u=${u['user_id']}',
                              name: u['username'] ?? u['first_name'],
                              score: '${u['total_steps']}',
                              isYou: u['user_id'] == _currentUserId,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],

              // Bottom Navigation Bar
              _buildBottomNavigationBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumAvatar({
    required String imageUrl,
    required String name,
    required String score,
    required int rank,
    required double avatarSize,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // The Avatar
            ProfileAvatar(
              radius: avatarSize / 2,
              avatarUrl: imageUrl,
              backgroundColor: Colors.grey[800],
            ),

            // Rank Medals (All floating on top of the head)
            if (rank == 1)
              Positioned(
                top: -65,
                child: Image.asset(
                  'assets/images/crown.png', // The Crown image
                  width: 120,
                  height: 120,
                  errorBuilder: (c, e, s) => const Icon(
                    Icons.workspace_premium,
                    color: Colors.amber,
                    size: 60,
                  ),
                ),
              ),
            if (rank == 2)
              Positioned(
                top: -35,
                child: Image.asset(
                  'assets/images/medal_silver.png',
                  width: 55,
                  height: 55,
                  errorBuilder: (c, e, s) => const Icon(
                    Icons.workspace_premium,
                    color: Colors.grey,
                    size: 40,
                  ),
                ),
              ),
            if (rank == 3)
              Positioned(
                top: -35,
                child: Image.asset(
                  'assets/images/medal_bronze.png',
                  width: 55,
                  height: 55,
                  errorBuilder: (c, e, s) => const Icon(
                    Icons.workspace_premium,
                    color: Colors.orange,
                    size: 40,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        Text(
          score,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildRankCard({
    required String rank,
    required String imageUrl,
    required String name,
    required String score,
    bool isYou = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isYou ? 0.2 : 0.05),
            blurRadius: isYou ? 12 : 5,
            offset: const Offset(0, 4),
          ),
        ],
        border: isYou ? Border.all(color: Colors.amber, width: 2) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              rank,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ProfileAvatar(
            radius: 20,
            avatarUrl: imageUrl,
            backgroundColor: Colors.grey[200],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: isYou ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
                if (isYou) ...[
                  const SizedBox(width: 6),
                  Text(
                    '(You)',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            score,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.directions_run_rounded, color: Colors.grey[800], size: 18),
        ],
      ),
    );
  }

  // Consistent Bottom Navigation Bar
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
              onTap: () => Navigator.pop(context),
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
