import 'package:flutter/material.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:axora/theme/app_colors.dart';
import 'package:provider/provider.dart';

class AuthorInformationScreen extends StatefulWidget {
  const AuthorInformationScreen({Key? key}) : super(key: key);

  @override
  State<AuthorInformationScreen> createState() => _AuthorInformationScreenState();
}

class _AuthorInformationScreenState extends State<AuthorInformationScreen> {
  bool _showHiddenCredit = false;
  int _tapCount = 0;
  bool _secretSequenceActivated = false;
  DateTime? _lastTapTime;
  
  // Reset the secret tap sequence after a period of inactivity
  void _resetTapSequence() {
    if (_tapCount > 0) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _tapCount = 0;
            _secretSequenceActivated = false;
          });
        }
      });
    }
  }
  
  // Check for the special tap sequence (3 taps within 2 seconds)
  void _handleTap() {
    final now = DateTime.now();
    
    // If it's been more than 2 seconds since the last tap, reset the counter
    if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds > 2) {
      _tapCount = 0;
    }
    
    setState(() {
      _tapCount++;
      _lastTapTime = now;
      
      // Secret sequence: 3 taps
      if (_tapCount == 3) {
        _secretSequenceActivated = true;
        // Show a subtle indicator that the long press will now work
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(''),
            duration: const Duration(milliseconds: 300),
            backgroundColor: Colors.transparent,
          ),
        );
      } else {
        _resetTapSequence();
      }
    });
  }
  
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
              child: GestureDetector(
                onTap: _handleTap,
                onLongPress: () {
                  // Only show hidden credit if secret sequence has been activated
                  if (_secretSequenceActivated) {
                    // Show hidden credit after long press
                    setState(() {
                      _showHiddenCredit = true;
                    });
                  }
                },
                onLongPressStart: (_) {
                  // Only start the timer if secret sequence has been activated
                  if (_secretSequenceActivated) {
                    // Start a timer that will show the hidden credit after 10 seconds
                    Future.delayed(const Duration(seconds: 10), () {
                      if (mounted && _secretSequenceActivated) {
                        setState(() {
                          _showHiddenCredit = true;
                        });
                      }
                    });
                  }
                },
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
            ),
            
            // Hidden credit that appears after 10-second hold 

            /*
Hi, I'm Rehan.
Just a simple student with a big dream — to bring a little peace into this noisy world.

I’m not a professional developer. I didn’t have a team.
Just an idea… and the courage to start.

This app is my small gift to anyone searching for calm, for clarity, or maybe just a moment to breathe.

If you’ve discovered this hidden message,
maybe it's a sign —
that you, too, have something special inside you, waiting to be shared with the world.

Thank you for being here.
Stay kind. Stay curious. Stay calm. ✨
*/


            if (_showHiddenCredit)
              Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.primaryBlue.withOpacity(0.1) : AppColors.primaryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode ? AppColors.primaryBlue : AppColors.primaryGold,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "💡 About the Creator",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Created with heart by Rehan.\n"
                        "A young mind with a calm vision.\n"
                        "Not a developer, just a dreamer learning every day.\n\n"
                        "This app was made to help others find peace — just like I needed.\n"
                        "If you're reading this, maybe you're meant to build something too.\n\n"
                        "Very few people know this and you are one of them.\n\n"
                        "Thank you for unlocking this secret. 🙂",
                        textAlign: TextAlign.center,
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