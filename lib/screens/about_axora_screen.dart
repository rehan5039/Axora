import 'package:flutter/material.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:axora/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'privacy_policy_screen.dart';
import 'terms_service_screen.dart';
import 'author_information_screen.dart';
import 'app_information_screen.dart';

class AboutAxoraScreen extends StatelessWidget {
  const AboutAxoraScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    final backgroundColor = isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('About Axora'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Axora',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Version 2.0.3',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          _AboutMenuItem(
            icon: Icons.person_outline,
            title: 'Author Information',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AuthorInformationScreen(),
                ),
              );
            },
          ),
          _AboutMenuItem(
            icon: Icons.description_outlined,
            title: 'Privacy Policy',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          _AboutMenuItem(
            icon: Icons.gavel_outlined,
            title: 'Terms & Conditions',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsServiceScreen(),
                ),
              );
            },
          ),
          _AboutMenuItem(
            icon: Icons.info_outline,
            title: 'App Information',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppInformationScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AboutMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _AboutMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryBlue),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
} 