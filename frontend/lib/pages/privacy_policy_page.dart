import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      color: Colors.black,
      fontSize: 15,
      height: 1.3,
      fontWeight: FontWeight.w400,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Privacy',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: const Color(0xFF2B2B2B), // Thick dark separator line
            height: 4.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            
            // Indented sections
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Information Collection: We collect your name, email address, walking activity data (e.g., steps and distance via Apple Health or Google Fit), and basic device diagnostics.',
                    style: textStyle,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Data Usage: Your data is used exclusively to track walking progress, calculate reward points, and improve app stability. We strictly do not sell or utilize your health data for advertising purposes.',
                    style: textStyle,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Data Sharing: We do not sell personal information. Data is shared only with essential service providers for operational purposes or when required by law.',
                    style: textStyle,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'User Rights: You retain the right to access, modify, or request the deletion of your account and personal data. You may also revoke access to your health data at any time via your device settings.',
                    style: textStyle,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Age Restriction: This application is not intended for individuals under the age of 13.',
                    style: textStyle,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Contact Information: For inquiries regarding this policy, please contact us at: gao.gmail.com',
                    style: textStyle,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            const Text(
              'By continuing to use the application, you acknowledge and agree to this Privacy Policy.',
              style: textStyle,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
