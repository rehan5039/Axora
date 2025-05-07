import 'package:flutter/material.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:axora/theme/app_colors.dart';
import 'package:provider/provider.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    final backgroundColor = isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
    final secondaryTextColor = isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: 7 May 2025',
              style: TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            
            _PolicySection(
              title: '1. INTRODUCTION',
              content: 'Welcome to Axora ("we," "our," or "us"). We respect your privacy and are committed to protecting your personal data. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our meditation and wellness application. Axora is a product by Risewell Labs',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            
            _PolicySection(
              title: '2. INFORMATION WE COLLECT',
              content: '2.1 Personal Information\n- Account Information: Email address, name, and authentication data when you create an account\n- Profile Information: Meditation preferences, progress, and wellness goals\n- Device Information: Device type, operating system, and unique device identifiers\n\n2.2 Usage Information\nUsage Data: Includes meditation session duration, frequency, features used, preferences selected, time spent in the app, and consistency tracking metrics.',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            
            _PolicySection(
              title: '3. HOW WE USE YOUR INFORMATION',
              content: 'We use your information to:\n- Provide and personalize your meditation experience\n- Synchronize your data across devices\n- Track your meditation progress and journey\n- Improve and optimize our application\n- Send notifications related to your meditation practice\n- Ensure the security of your account',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            
            _PolicySection(
              title: '4. DATA STORAGE AND SECURITY',
              content: 'Your data is stored securely on Firebase servers with industry-standard security measures. We implement appropriate technical and organizational measures to protect your personal information.',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            
            _PolicySection(
              title: '5. DATA SHARING',
              content: 'We do not sell your personal information to third parties. We may share data with:\n- Service providers that help us operate our application (subject to confidentiality agreements)\n- If required by law or to protect our legal rights',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            
            _PolicySection(
              title: '6. YOUR CHOICES AND RIGHTS',
              content: 'You have the right to:\n- Access your personal information\n- Request correction of inaccurate data\n- Delete your account and associated data\n- Opt-out of certain data collection\n- Control notification settings within the app',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            
            _PolicySection(
              title: '7. MISUSE & USER RESPONSIBILITY',
              content: 'Users are solely responsible for their behavior and interactions within the app. Axora disclaims any liability for misuse, unlawful activities, or violations of third-party rights committed by users. Any abuse or violation of terms may lead to restricted access or account termination.',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            
            _PolicySection(
              title: '8. CHILDREN\'S PRIVACY',
              content: 'Our application is not directed to children under 13. We do not knowingly collect personal information from children under 13.',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            
            _PolicySection(
              title: '9. CHANGES TO THIS POLICY',
              content: 'We may update this Privacy Policy periodically. We will notify you of significant changes through the app or by email.',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            
            _PolicySection(
              title: '10. CONTACT US',
              content: 'If you have questions about this Privacy Policy, please contact us at:\nEmail: axora.app@gmail.com',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            
            const SizedBox(height: 16),
            Text(
              '@Web @https://privacyandpaolicy.blogspot.com/2025/05/axora.html',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;
  final Color textColor;
  final Color secondaryTextColor;

  const _PolicySection({
    required this.title,
    required this.content,
    required this.textColor,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
} 