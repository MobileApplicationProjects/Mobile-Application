import 'package:flutter/material.dart';
import 'profile_edit_page.dart';
import 'about_you_edit_page.dart';
import 'sign_in_page.dart';
import '../services/auth_service.dart';

class MenuItem {
  final String title;
  final bool isLogout;
  final VoidCallback onTap;

  MenuItem({required this.title, this.isLogout = false, required this.onTap});
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = true;

  // Data states from API
  String _userName = '';
  String _profileImageUrl = '';

  @override
  void initState() {
    super.initState();
    _fetchSettingsData();
  }

  // ดึงข้อมูลผู้ใช้สำหรับตั้งค่าจาก API
  Future<void> _fetchSettingsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      final result = await authService.getProfile();
      final profile = result['profile'];

      setState(() {
        _userName = '${profile['firstName']} ${profile['lastName']}';
        _profileImageUrl = ''; // Profile image not yet implemented
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'Unknown User';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1D1D1D),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1D), // Dark background for gaps
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 30),
            _buildMenuGroup([
              MenuItem(title: 'Profile', onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileEditPage()),
                );
              }),
              MenuItem(title: 'About you', onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutYouEditPage()),
                );
              }),
            ]),
            _buildMenuGroup([
              MenuItem(title: 'Health Apps', onTap: () {}),
              MenuItem(title: 'Push Notifications', onTap: () {}),
            ]),
            _buildMenuGroup([
              MenuItem(title: 'Privacy Controls', onTap: () {}),
            ]),
            _buildMenuGroup([
              MenuItem(title: 'Terms of Service', onTap: () {}),
              MenuItem(title: 'Privacy Policy', onTap: () {}),
            ]),
            _buildMenuGroup([
              MenuItem(
                title: 'Logout',
                isLogout: true,
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF2A2A2A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text(
                        'ออกจากระบบ',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      content: Text(
                        'คุณต้องการออกจากระบบใช่ไหม?',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('ยกเลิก', style: TextStyle(color: Colors.grey[400])),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('ออกจากระบบ', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && mounted) {
                    await AuthService().signOut();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const SignInPage()),
                        (route) => false,
                      );
                    }
                  }
                },
              ),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height:
          280, // Total height of the header area including overlapping avatar
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // White curved background
          Container(
            height: 220,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
          ),
          // Back button
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.black,
                  size: 28,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          // User Name
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Text(
                _userName,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          // Profile Avatar overlapping the bottom edge
          Positioned(
            bottom: 0,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                // ignore: prefer_const_constructors
                image: _profileImageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(_profileImageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: Colors.grey[800],
              ),
              child: _profileImageUrl.isEmpty
                  ? const Center(
                      child: Icon(Icons.person, size: 60, color: Colors.white),
                    )
                  : null,
            ),
          ),
          // Edit Overlay
          Positioned(
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.edit, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Edit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGroup(List<MenuItem> items) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          indent: 20,
          endIndent: 20,
          color: Colors.black12,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            trailing: item.isLogout
                ? const Icon(Icons.exit_to_app, color: Colors.red, size: 24)
                : const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.black,
                    size: 16,
                  ),
            onTap: item.onTap,
          );
        },
      ),
    );
  }
}
