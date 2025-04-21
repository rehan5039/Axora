import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:axora/utils/constants.dart';

class ThemeToggleButton extends StatelessWidget {
  final double size;
  final bool showText;
  
  const ThemeToggleButton({
    Key? key, 
    this.size = 40.0,
    this.showText = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(size / 2),
        onTap: () {
          themeProvider.toggleTheme();
        },
        child: Container(
          width: showText ? null : size,
          height: size,
          padding: showText ? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0) : null,
          decoration: BoxDecoration(
            color: isDarkMode 
              ? AppColors.primaryGold.withOpacity(0.2) 
              : AppColors.primaryGreen.withOpacity(0.2),
            borderRadius: BorderRadius.circular(size / 2),
            border: Border.all(
              color: isDarkMode ? AppColors.primaryGold : AppColors.primaryGreen,
              width: 1.5,
            ),
          ),
          child: showText 
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIcon(isDarkMode),
                    const SizedBox(width: 8),
                    Text(
                      isDarkMode ? 'Dark Mode' : 'Light Mode',
                      style: TextStyle(
                        color: isDarkMode ? AppColors.darkText : AppColors.lightText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : _buildIcon(isDarkMode),
        ),
      ),
    );
  }
  
  Widget _buildIcon(bool isDarkMode) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: isDarkMode 
          ? Icon(
              Icons.dark_mode_rounded,
              key: const ValueKey('dark'),
              color: AppColors.primaryGold,
              size: size * 0.6,
            )
          : Icon(
              Icons.light_mode_rounded,
              key: const ValueKey('light'),
              color: AppColors.primaryGreen,
              size: size * 0.6,
            ),
    );
  }
} 