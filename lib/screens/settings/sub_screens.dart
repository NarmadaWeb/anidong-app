// lib/screens/settings/sub_screens.dart

import 'package:anidong/utils/app_colors.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Privacy Policy\n\nThis application does not collect any personal data. All data is stored locally on your device.\n\nDisclaimer: This app scrapes publicly available content from third-party websites. We do not host any content.',
          style: TextStyle(color: AppColors.primaryText, fontSize: 16),
        ),
      ),
    );
  }
}

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Help Center'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Frequently Asked Questions', style: TextStyle(color: AppColors.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Q: Why is the video not playing?\nA: Check your internet connection. Some servers might be down.', style: TextStyle(color: AppColors.secondaryText)),
            SizedBox(height: 12),
            Text('Q: How do I download?\nA: Click on the Download button in the player screen and select a server.', style: TextStyle(color: AppColors.secondaryText)),
          ],
        ),
      ),
    );
  }
}

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Feedback'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('We would love to hear from you!', style: TextStyle(color: AppColors.primaryText, fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              maxLines: 5,
              style: const TextStyle(color: AppColors.primaryText),
              decoration: InputDecoration(
                hintText: 'Enter your feedback here...',
                hintStyle: const TextStyle(color: AppColors.secondaryText),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback sent!')));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
