import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/health_service.dart';

class DataSyncPage extends StatefulWidget {
  const DataSyncPage({Key? key}) : super(key: key);

  @override
  State<DataSyncPage> createState() => _DataSyncPageState();
}

class _DataSyncPageState extends State<DataSyncPage> {
  bool _isSyncEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSyncEnabled = prefs.getBool('data_sync_enabled') ?? false;
    });
  }

  Future<void> _saveSettings(bool value) async {
    bool finalValue = value;

    if (value == true) {
      // 1. Prompt system permission
      bool authorized = await HealthService().authorize();
      if (!authorized) {
        // Fallback or deny
        finalValue = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('สิทธิ์ล้มเหลว: โปรดเปิดแอป "สุขภาพ (Health)" บน iPhone > โปรไฟล์ > แอป > แล้วอนุญาตให้แอปเข้าถึงข้อมูล'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('data_sync_enabled', finalValue);
    setState(() {
      _isSyncEnabled = finalValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Dark background color from the mockup
      appBar: AppBar(
        titleSpacing: 0, // Align closer to the back button if needed
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Manage Data Sync',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10), // Adding slightly more space if needed, though in image it's right under appbar.
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Text(
                    'Allow app to sync your data from\nhealth app on your phone',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Switch.adaptive(
                  value: _isSyncEnabled,
                  onChanged: (bool value) {
                    _saveSettings(value);
                  },
                  activeColor: Theme.of(context).primaryColor,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey[300],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
