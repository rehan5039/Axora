import 'package:flutter/material.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:axora/theme/app_colors.dart';
import 'package:provider/provider.dart';

class AuthorInformationScreen extends StatelessWidget {
  const AuthorInformationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    final backgroundColor = isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
    final cardColor = isDarkMode ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Author Information'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 120,
                height: 120,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person,
                  size: 64,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            
            Center(
              child: Text(
                'Saad Kalburge',
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
                'Lead Developer',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? AppColors.primaryGold : AppColors.primaryGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            Card(
              color: cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.business,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Risewell',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'About the Developer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Saad Kalburge is the primary developer of Axora. '
                      'With a passion for creating meaningful applications that improve people\'s lives, '
                      'Saad developed Axora to help users practice mindfulness and meditation in an accessible way.',
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withOpacity(0.9),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'About Risewell',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Risewell is dedicated to creating applications that focus on mental wellbeing and personal growth. '
                      'Our mission is to leverage technology to help people lead more mindful, balanced, and fulfilled lives.',
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withOpacity(0.9),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Card(
              color: cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.code,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Development Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      icon: Icons.check_circle_outline,
                      title: 'Axora App',
                      subtitle: 'Complete app design and development',
                      textColor: textColor,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.check_circle_outline,
                      title: 'UI/UX Design',
                      subtitle: 'Custom interface and user experience',
                      textColor: textColor,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.check_circle_outline,
                      title: 'Backend Integration',
                      subtitle: 'Firebase and cloud services implementation',
                      textColor: textColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.primaryBlue,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: textColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 