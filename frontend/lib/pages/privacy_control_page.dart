import 'package:flutter/material.dart';

class PrivacyControlPage extends StatefulWidget {
  const PrivacyControlPage({Key? key}) : super(key: key);

  @override
  State<PrivacyControlPage> createState() => _PrivacyControlPageState();
}

class _PrivacyControlPageState extends State<PrivacyControlPage> {
  bool _usageAnalytics = false;
  bool _thirdPartyServices = false;
  bool _experiencePersonalization = false;

  Widget _buildControlItem(String title, bool value, ValueChanged<bool> onChanged) {
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
      backgroundColor: const Color(0xFF1A1A1A), // Dark background color from the mockup
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
          'Privacy Control',
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
          _buildControlItem('Usage Analytics', _usageAnalytics, (val) {
            setState(() {
              _usageAnalytics = val;
            });
          }),
          _buildControlItem('Third-Party Services', _thirdPartyServices, (val) {
            setState(() {
              _thirdPartyServices = val;
            });
          }),
          _buildControlItem('Experience Personalization', _experiencePersonalization, (val) {
            setState(() {
              _experiencePersonalization = val;
            });
          }),
        ],
      ),
    );
  }
}
