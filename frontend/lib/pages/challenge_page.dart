import 'package:flutter/material.dart';
import '../services/challenge_service.dart';
import '../services/auth_service.dart';
import '../admin/admin_add_challenge_page.dart';
import 'package:intl/intl.dart';

class ChallengePage extends StatefulWidget {
  final bool isAdmin;
  const ChallengePage({super.key, this.isAdmin = false});

  @override
  State<ChallengePage> createState() => _ChallengePageState();
}

class _ChallengePageState extends State<ChallengePage> {
  final ChallengeService _challengeService = ChallengeService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _challenges = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isAdmin = widget.isAdmin;
    _loadChallenges();
    if (!_isAdmin) _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final response = await _authService.getProfile();
      final profile = response['profile'] ?? {};
      final isAdmin = (profile['role'] == 'admin');
      if (mounted && isAdmin != _isAdmin) {
        setState(() => _isAdmin = isAdmin);
      }
    } catch (_) {}
  }

  Future<void> _loadChallenges() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _challengeService.getChallenges();
      if (mounted) {
        setState(() {
          _challenges = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatDeadline(dynamic deadline) {
    if (deadline == null) return 'No limit date';
    try {
      final dt = DateTime.parse('$deadline');
      return 'By ${DateFormat('dd/MM/yyyy HH:mm a').format(dt)}';
    } catch (_) {
      return '$deadline';
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
          'Challenge',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                backgroundColor: Colors.red[700],
                label: const Text(
                  'ADMIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadChallenges,
          color: Colors.red[700],
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(50),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                else if (_error != null)
                  _buildErrorState()
                else if (_challenges.isEmpty)
                  _buildEmptyState()
                else
                  ..._challenges.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildChallengeItem(
                      challenge: c,
                      title: c['title'] ?? '',
                      description: c['description'] ?? '',
                      dateStr: _formatDeadline(c['deadline']),
                      tokenReward: '${c['reward_amount'] ?? 0}',
                    ),
                  )).toList(),

                // Admin Add Button
                if (_isAdmin && !_isLoading) ...[
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminAddChallengePage(),
                        ),
                      );
                      if (result == true) {
                        _loadChallenges();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red[800]!, Colors.red[600]!],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_circle_outline, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'Add New Challenge',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Text(
          'No challenges available',
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.grey[600], size: 48),
            const SizedBox(height: 12),
            Text('Failed to load data', style: TextStyle(color: Colors.grey[400])),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadChallenges,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeItem({
    required Map<String, dynamic> challenge,
    required String title,
    required String description,
    required String dateStr,
    required String tokenReward,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                 shape: BoxShape.circle,
                 color: Colors.red[50],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/target.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.my_location_rounded, size: 28, color: Colors.red[400]),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_month, color: Colors.grey[500], size: 12),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tokenReward,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 20,
                      height: 20,
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
                if (_isAdmin) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminAddChallengePage(challenge: challenge),
                        ),
                      );
                      if (result == true) {
                        _loadChallenges();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red[700],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
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
            _buildNavItem(icon: Icons.home_rounded, label: 'HOME', isActive: false),
            _buildNavItem(icon: Icons.location_on_rounded, label: 'MAP', isActive: false),
            _buildNavItem(icon: Icons.track_changes_rounded, label: 'CHALLENGE', isActive: true),
            _buildNavItem(icon: Icons.ios_share_rounded, label: 'SHARE', isActive: false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required bool isActive}) {
    final color = isActive ? Colors.red[700]! : Colors.white;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
