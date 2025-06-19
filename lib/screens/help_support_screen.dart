import 'package:flutter/material.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:axora/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'about_axora_screen.dart';
import 'contact_support_screen.dart';
import 'community_support_screen.dart';
import 'feedback_screen.dart';
import 'faq_screen.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    final backgroundColor = isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _SupportMenuItem(
            icon: Icons.email_outlined,
            title: 'Contact Support',
            subtitle: 'Get help with your account or app issues',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContactSupportScreen(),
                ),
              );
            },
          ),
          _SupportMenuItem(
            icon: Icons.forum_outlined,
            title: 'Community Support',
            subtitle: 'Chat with other users and get help from the community',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CommunitySupportScreen(),
                ),
              );
            },
          ),
          _SupportMenuItem(
            icon: Icons.help_outline,
            title: 'FAQ',
            subtitle: 'Frequently asked questions about meditation',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FAQScreen(),
                ),
              );
            },
          ),
          _SupportMenuItem(
            icon: Icons.menu_book_outlined,
            title: 'User Guide',
            subtitle: 'Learn how to use Axora meditation app',
            onTap: () {
              // Navigate to User Guide screen when implemented
            },
          ),
          _SupportMenuItem(
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            subtitle: 'Help us improve the Axora experience',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FeedbackScreen(),
                ),
              );
            },
          ),
          _SupportMenuItem(
            icon: Icons.info_outline,
            title: 'About Axora',
            subtitle: 'View app information and legal details',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutAxoraScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SupportMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    final secondaryTextColor = isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
      leading: Icon(icon, color: AppColors.primaryBlue, size: 28),
      title: Text(
        title, 
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: secondaryTextColor,
          fontSize: 14,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
} 