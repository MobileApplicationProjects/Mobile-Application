import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _dailyChallengeReminder = false;
  bool _goalAchieved = false;
  bool _leaderBoard = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyChallengeReminder = prefs.getBool('notif_daily_challenge') ?? false;
      _goalAchieved = prefs.getBool('notif_goal_achieved') ?? false;
      _leaderBoard = prefs.getBool('notif_leaderboard') ?? false;
    });
  }

  Future<bool> _saveSetting(String key, bool value) async {
    bool finalValue = value;

    if (value == true) {
      // Request notification permission
      var status = await Permission.notification.request();
      if (!status.isGranted) {
        finalValue = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('กรุณาเปิดอนุญาตการแจ้งเตือนในตั้งค่าแอพก่อน')),
          );
        }
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, finalValue);
    return finalValue;
  }

  Widget _buildNotificationItem(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).primaryColor,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF1A1A1A,
      ), // Dark background color from the mockup
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 10),
        children: [
          _buildNotificationItem(
            'Daily Challenge Reminder',
            _dailyChallengeReminder,
            (val) async {
              bool result = await _saveSetting('notif_daily_challenge', val);
              setState(() {
                _dailyChallengeReminder = result;
              });
            },
          ),
          _buildNotificationItem('Goal Achieved', _goalAchieved, (val) async {
            bool result = await _saveSetting('notif_goal_achieved', val);
            setState(() {
              _goalAchieved = result;
            });
          }),
          _buildNotificationItem('Leader Board', _leaderBoard, (val) async {
            bool result = await _saveSetting('notif_leaderboard', val);
            setState(() {
              _leaderBoard = result;
            });
          }),
        ],
      ),
    );
  }
}
