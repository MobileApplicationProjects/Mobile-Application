import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'pages/data_sync_page.dart';
import 'pages/notification_settings_page.dart';
import 'pages/privacy_control_page.dart';
import 'pages/privacy_policy_page.dart';
import 'pages/terms_of_service_page.dart';
import 'pages/profile_edit_page.dart';
import 'pages/about_you_edit_page.dart';
import 'services/auth_service.dart';
import 'widgets/profile_avatar.dart';

class MenuItem {
  final String title;
  final bool isLogout;
  final VoidCallback onTap;

  MenuItem({required this.title, this.isLogout = false, required this.onTap});
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;

  String _userName = '';
  String? _avatarUrl;
  
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  // ดึงข้อมูลส่วนตัวของผู้ใช้ (Profile) จาก API
  Future<void> _fetchProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      final result = await authService.getProfile();
      final profile = result['profile'];

      setState(() {
        _userName = '${profile['firstName']} ${profile['lastName']}';
        _avatarUrl = profile['avatarUrl'];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'Unknown User';
          _avatarUrl = null;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 800);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImage = picked;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _saveAvatar() async {
    if (_selectedImage == null) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSaving = true);
    try {
      final url = await AuthService().uploadAndSetAvatar(_selectedImage!);
      setState(() {
        _avatarUrl = url;
        _selectedImage = null;
        _imageBytes = null;
        _isSaving = false;
      });
      messenger.showSnackBar(const SnackBar(content: Text('อัพโหลดรูปโปรไฟล์สำเร็จ!')));
    } catch (e) {
      setState(() => _isSaving = false);
      messenger.showSnackBar(SnackBar(content: Text('อัพโหลดไม่สำเร็จ: $e')));
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              const Text('เลือกรูปจาก', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Colors.white),
                title: const Text('คลังรูปภาพ', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                title: const Text('กล้อง', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1D1D1D),
        body: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1D), // Dark background for gaps
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(),
            
            // Save Button (Appears when image is picked)
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAvatar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 8,
                    shadowColor: Colors.red.withOpacity(0.5),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24, width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'บันทึกรูปโปรไฟล์ใหม่',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                ),
              ),

            const SizedBox(height: 30),
            
            _buildMenuGroup([
              MenuItem(title: 'Profile', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileEditPage()))),
              MenuItem(title: 'About you', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutYouEditPage()))),
            ]),
            _buildMenuGroup([
              MenuItem(title: 'Health Apps', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DataSyncPage()))),
              MenuItem(title: 'Push Notifications', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsPage()))),
            ]),
            _buildMenuGroup([
              MenuItem(title: 'Privacy Controls', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyControlPage()))),
            ]),
            _buildMenuGroup([
              MenuItem(title: 'Terms of Service', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsOfServicePage()))),
              MenuItem(title: 'Privacy Policy', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()))),
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
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
      height: 280, 
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
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 28),
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
            child: GestureDetector(
              onTap: _showImageSourcePicker,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: Colors.grey[800],
                    ),
                    child: ProfileAvatar(
                      avatarUrl: _avatarUrl,
                      imageBytes: _imageBytes,
                      radius: 96,
                    ),
                  ),
                  // Edit Overlay
                  Positioned(
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
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
