import 'package:flutter/material.dart';
import 'package:axora/utils/constants.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class AxoraLogo extends StatelessWidget {
  final double fontSize;
  
  const AxoraLogo({
    super.key,
    this.fontSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isLightMode = !themeProvider.isDarkMode;
    final textColor = isLightMode ? AppColors.lightText : AppColors.darkText;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          color: AppColors.primaryGold,
          size: fontSize,
        ),
        Text(
          'xora',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
} 