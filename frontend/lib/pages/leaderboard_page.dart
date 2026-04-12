import 'package:flutter/material.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We use a modern purple gradient matching the mockup's vibrant tone
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
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
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
                    const SizedBox(width: 48), // Balancing the back button
                  ],
                ),
              ),

              // Location tag
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Location: ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Mahidol Salaya (private)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 10),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Podium Section (Modern Styling)
              SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Rank 2 (Left)
                    Positioned(
                      left: MediaQuery.of(context).size.width * 0.15,
                      bottom: 20,
                      child: _buildPodiumAvatar(
                        imageUrl: 'https://i.pravatar.cc/150?img=11',
                        name: 'Stelano',
                        score: '12,000',
                        medalColor: Colors.grey[300]!, // Silver
                        avatarSize: 70,
                      ),
                    ),

                    // Rank 3 (Right)
                    Positioned(
                      right: MediaQuery.of(context).size.width * 0.15,
                      bottom: 0,
                      child: _buildPodiumAvatar(
                        imageUrl: 'https://i.pravatar.cc/150?img=5',
                        name: 'Elifut',
                        score: '3,200',
                        medalColor: const Color(0xFFCD7F32), // Bronze
                        avatarSize: 65,
                      ),
                    ),

                    // Rank 1 (Center)
                    Positioned(
                      bottom: 50,
                      child: _buildPodiumAvatar(
                        imageUrl: 'https://i.pravatar.cc/150?img=47',
                        name: 'Gibbu',
                        score: '15,300',
                        medalColor: Colors.amber, // Gold
                        avatarSize: 90,
                        isRankOne: true,
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
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildRankCard(
                        rank: '4',
                        imageUrl: 'https://i.pravatar.cc/150?img=12',
                        name: 'Camren',
                        score: '2,800',
                      ),
                      const SizedBox(height: 12),
                      _buildRankCard(
                        rank: '5',
                        imageUrl: 'https://i.pravatar.cc/150?img=33',
                        name: 'Koruki',
                        score: '2,850',
                      ),
                      const SizedBox(height: 12),
                      _buildRankCard(
                        rank: '6',
                        imageUrl: 'https://i.pravatar.cc/150?img=59',
                        name: 'Chai',
                        score: '2,300',
                      ),
                      const SizedBox(height: 12),
                      _buildRankCard(
                        rank: '7',
                        imageUrl: 'https://i.pravatar.cc/150?img=44',
                        name: 'Mayrei',
                        score: '2,055',
                        isYou: true,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

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
    required Color medalColor,
    required double avatarSize,
    bool isRankOne = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isRankOne)
          const Icon(Icons.workspace_premium, color: Colors.amber, size: 40),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: CircleAvatar(
                radius: avatarSize / 2,
                backgroundImage: NetworkImage(imageUrl),
                backgroundColor: Colors.grey[800],
              ),
            ),
            Positioned(
              left: -10,
              top: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: medalColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          score,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 12,
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
          )
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
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(imageUrl),
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
                ]
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
    return Container(
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
          ),
          _buildNavItem(
            icon: Icons.location_on_rounded,
            label: 'MAP',
            isActive: false,
          ),
          _buildNavItem(
            icon: Icons.track_changes_rounded,
            label: 'CHALLENGE',
            isActive: false,
          ),
          _buildNavItem(
            icon: Icons.ios_share_rounded,
            label: 'SHARE',
            isActive: false,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    final color = isActive ? Colors.red[700]! : Colors.white;
    return Column(
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
    );
  }
}
