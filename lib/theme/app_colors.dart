import 'package:flutter/material.dart';

class AppColors {
  // Primary colors from the image
  static const Color primaryGold = Color(0xFFDBAF36);    // Gold/yellow circle button color
  static const Color primaryGreen = Color(0xFF5A7D70);   // Green circle button color
  static const Color primaryBlue = Color(0xFF3F51B5);    // Keeping existing blue as accent
  
  // Light theme colors
  static const Color lightBackground = Color(0xFFF7F6F1); // Cream/off-white background 
  static const Color lightCardBackground = Colors.white;
  static const Color lightText = Color(0xFF212121);
  static const Color lightTextSecondary = Color(0xFF757575);
  
  // Dark theme colors
  static const Color darkBackground = Color(0xFF141C2F);  // Dark navy background
  static const Color darkCardBackground = Color(0xFF1E2738); // Slightly lighter navy
  static const Color darkText = Colors.white;
  static const Color darkTextSecondary = Color(0xFFBDBDBD);
  
  // Accent colors
  static const Color accent = Color(0xFF6B4EFF);
  static const Color secondary = Color(0xFF8C79FF);
  static const Color error = Color(0xFFE57373);
  static const Color success = Color(0xFF81C784);
  
  // Highlight colors from the image
  static const Color highlightGreen = Color(0xFFADC178);  // Light green highlighter
  static const Color highlightBlue = Color(0xFF90B8F8);   // Light blue highlighter

  // Button Gradient
  static const List<Color> buttonGradient = [Color(0xFF3F51B5), Color(0xFF5C6BC0)];
} 