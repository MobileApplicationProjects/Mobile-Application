import 'package:flutter/material.dart';
import 'pages/step_count_page.dart';
import 'pages/data_sync_page.dart';
import 'pages/notification_settings_page.dart';
import 'pages/privacy_control_page.dart';
import 'pages/privacy_policy_page.dart';
import 'pages/terms_of_service_page.dart';
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1D),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- APP BAR ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.settings_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- PROFILE INFO ---
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.grey[800],
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good Day!',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Dianne West',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '100',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
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
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // --- THIS WEEK CHART CARD ---
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StepCountPage(initialTab: 'W'),
                    ),
                  );
                },
                child: _buildChartCard(),
              ),

              const SizedBox(height: 24),

              // --- ACTIONS ---
              _buildActionTile(
                icon: Icons.bar_chart_rounded,
                title: 'Statistics',
                onTap: () {},
              ),
              const SizedBox(height: 16),
              _buildActionTile(
                icon: Icons.savings_rounded,
                title: 'Token History',
                onTap: () {},
              ),

              const SizedBox(height: 24),
              const Text(
                'Settings & Privacy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildActionTile(
                icon: Icons.notifications_active_rounded,
                title: 'Notification Settings',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsPage()));
                },
              ),
              const SizedBox(height: 16),
              _buildActionTile(
                icon: Icons.sync_rounded,
                title: 'Data Sync',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const DataSyncPage()));
                },
              ),
              const SizedBox(height: 16),
              _buildActionTile(
                icon: Icons.security_rounded,
                title: 'Privacy Control',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyControlPage()));
                },
              ),
              const SizedBox(height: 16),
              _buildActionTile(
                icon: Icons.policy_rounded,
                title: 'Privacy Policy',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()));
                },
              ),
              const SizedBox(height: 16),
              _buildActionTile(
                icon: Icons.article_rounded,
                title: 'Terms of Service',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsOfServicePage()));
                },
              ),

              const SizedBox(height: 24),

              // --- LEADER BOARD TROPHY ---
              _buildTrophyCard(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildChartCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'This week',
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
              _buildChartStat('Step', '10,000'),
              _buildChartStat('Calories', '900 kcal'),
              _buildChartStat('Distance', '6 km'),
              const SizedBox(width: 40),
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
                    children: [
                      _buildBar('S', 0.5, isHighlight: false),
                      _buildBar('M', 0.6, isHighlight: false),
                      _buildBar('T', 0.9, isHighlight: false),
                      _buildBar('W', 0.55, isHighlight: false),
                      _buildBar('T', 0.65, isHighlight: false),
                      _buildBar('F', 0.65, isHighlight: false),
                      _buildBar('S', 1.0, isHighlight: true),
                    ],
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
                    Text(
                      '3000',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    Text(
                      '1500',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    Text(
                      '0',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartStat(String label, String value) {
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
          width: 30, // Adjust if screen is narrow, Expanded distributes evenly
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

  Widget _buildActionTile({required IconData icon, required String title, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrophyCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/trophy.png',
                width: 60,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const SizedBox(
                  width: 60,
                  height: 60,
                  child: Icon(
                    Icons.emoji_events,
                    color: Colors.amber,
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Leader Board Trophy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMedalItem(
                  'assets/images/medal_gold.png', '1 win', Colors.amber, Icons.star),
              _buildMedalItem('assets/images/medal_silver.png', '0 win',
                  Colors.blueGrey[300]!, Icons.shield),
              _buildMedalItem('assets/images/medal_bronze.png', '3 win',
                  Colors.brown[400]!, Icons.emoji_events),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedalItem(
      String imagePath, String label, Color fallbackColor, IconData fallbackIcon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          imagePath,
          width: 80, // Enlarge the medal size
          height: 80,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: fallbackColor, width: 3),
            ),
            child: Icon(fallbackIcon, color: fallbackColor, size: 40),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16, // Increase font size to match figma
            fontWeight: FontWeight.w500, // Medium font weight
          ),
        ),
      ],
    );
  }

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
