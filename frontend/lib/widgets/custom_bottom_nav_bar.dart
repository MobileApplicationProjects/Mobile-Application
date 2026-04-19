import 'package:flutter/material.dart';
import '../pages/map_page.dart';
import '../pages/challenge_page.dart';
import '../pages/share_page.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onTabTapped(BuildContext context, int index) {
    if (currentIndex == index) return;

    Widget? targetPage;
    switch (index) {
      case 0:
        Navigator.popUntil(context, (route) => route.isFirst);
        return;
      case 1:
        targetPage = const MapPage();
        break;
      case 2:
        targetPage = const ChallengePage();
        break;
      case 3:
        targetPage = const SharePage();
        break;
    }

    if (targetPage != null) {
      if (currentIndex == 0) {
        // If coming from Home, push normally so Back button returns to Home
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => targetPage!,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } else {
        // If switching between siblings (e.g. Map to Challenge), replace current route
        // to avoid infinitely deep navigation stacks.
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => targetPage!,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    }
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
      behavior: HitTestBehavior.opaque,
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

  @override
  Widget build(BuildContext context) {
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
              isActive: currentIndex == 0,
              onTap: () => _onTabTapped(context, 0),
            ),
            _buildNavItem(
              icon: Icons.location_on_rounded,
              label: 'MAP',
              isActive: currentIndex == 1,
              onTap: () => _onTabTapped(context, 1),
            ),
            _buildNavItem(
              icon: Icons.track_changes_rounded,
              label: 'CHALLENGE',
              isActive: currentIndex == 2,
              onTap: () => _onTabTapped(context, 2),
            ),
            _buildNavItem(
              icon: Icons.ios_share_rounded,
              label: 'SHARE',
              isActive: currentIndex == 3,
              onTap: () => _onTabTapped(context, 3),
            ),
          ],
        ),
      ),
    );
  }
}
