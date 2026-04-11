import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

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
          'Terms of Service',
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
              'Terms and Conditions',
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
                    'General Use: By accessing KAO, you agree to use the application lawfully. Manipulating activity data or disrupting the service is strictly prohibited and may result in account termination.',
                    style: textStyle,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Account Responsibility: You are solely responsible for maintaining the confidentiality of your account credentials and for all activities conducted under your account.',
                    style: textStyle,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Tracking & Rewards: KAO utilizes device sensors to track walking progress. Reward points hold no real-world monetary value and the reward system is subject to modification or cancellation at any time.',
                    style: textStyle,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Health Disclaimer: This application is intended for fitness tracking and entertainment purposes only. It does not serve as a substitute for professional medical advice.',
                    style: textStyle,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Liability & Intellectual Property: All content within KAO is protected intellectual property. The service is provided "as is," without warranties regarding continuous availability or perfect tracking accuracy.',
                    style: textStyle,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Policy Updates: We reserve the right to modify these terms. Continued use of the application indicates your acceptance of any revisions.',
                    style: textStyle,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Contact Information: For further inquiries, please contact: gao.gmail.com',
                    style: textStyle,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            const Text(
              'By using this application, you acknowledge and agree to the full Terms and Conditions.',
              style: textStyle,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
