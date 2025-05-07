import 'package:flutter/material.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:axora/theme/app_colors.dart';
import 'package:provider/provider.dart';

class TermsServiceScreen extends StatelessWidget {
  const TermsServiceScreen({Key? key}) : super(key: key);

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
        title: const Text('Terms of Service'),
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
              'Terms of Service',
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
            
            _TermsSection(
              title: '1. ACCEPTANCE OF TERMS',
              content: 'By accessing or using the Axora meditation and wellness app ("App", "we", "us", or "our"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, please do not use the App.',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            
            _TermsSection(
              title: '2. USER ACCOUNTS',
              content: 'You may be required to create an account to access certain features. You agree to provide accurate, current, and complete information and to keep your account credentials secure. You are responsible for all activity under your account.',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            
            _TermsSection(
              title: '3. USE OF THE APP',
              content: 'The App is intended for personal, non-commercial use to support mindfulness, meditation, and general wellness. You agree not to:\n\nUse the App for any unlawful or harmful purpose\n\nCopy, modify, or distribute any part of the App without permission\n\nInterfere with the operation or security of the App',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            
            _TermsSection(
              title: '4. SUBSCRIPTIONS & PAYMENTS',
              content: 'Some features may be available via subscription. By purchasing a subscription, you agree to the pricing, billing, and cancellation terms disclosed in the App. All payments are processed securely via our third-party payment provider.',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            
            _TermsSection(
              title: '5. INTELLECTUAL PROPERTY',
              content: 'All content, features, and functionality in the App, including text, graphics, logos, audio, and code, are the property of Axora or its licensors and are protected by copyright and other laws.',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            
            _TermsSection(
              title: '6. TERMINATION',
              content: 'We reserve the right to suspend or terminate your access at our discretion if you violate these Terms or engage in misuse. You may delete your account at any time through the app settings.',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            
            _TermsSection(
              title: '7. LIMITATION OF LIABILITY',
              content: 'To the maximum extent permitted by law, Axora is not liable for any indirect, incidental, or consequential damages arising from your use of the App. The App is provided "as is" without warranties of any kind.',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            
            _TermsSection(
              title: '8. PRIVACY',
              content: 'Your use of the App is also governed by our Privacy Policy. Please review it to understand how we collect, use, and safeguard your information.',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            
            _TermsSection(
              title: '9. MODIFICATIONS',
              content: 'We may update these Terms from time to time. If changes are material, we will notify you via the App or email. Continued use of the App after such changes constitutes acceptance of the new Terms.',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            
            _TermsSection(
              title: '10. CONTACT',
              content: 'If you have any questions or concerns about these Terms, please contact us at:\nEmail: axora.app@gmail.com',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  final String title;
  final String content;
  final Color textColor;
  final Color secondaryTextColor;

  const _TermsSection({
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