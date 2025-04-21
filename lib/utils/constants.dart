import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

class AppStyles {
  // Light theme text styles
  static TextStyle heading1Light = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.lightText,
  );

  static TextStyle heading2Light = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.lightText,
  );

  static TextStyle bodyTextLight = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.lightText,
  );

  // Dark theme text styles
  static TextStyle heading1Dark = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
  );

  static TextStyle heading2Dark = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.darkText,
  );

  static TextStyle bodyTextDark = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.darkText,
  );

  // Common button text style
  static TextStyle buttonText = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // New text highlighter styles from the image
  static TextStyle textHighlighterGreen = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Color(0xFF4A6741),
    backgroundColor: AppColors.highlightGreen.withOpacity(0.3),
  );

  static TextStyle textHighlighterBlue = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Color(0xFF456789),
    backgroundColor: AppColors.highlightBlue.withOpacity(0.3),
  );

  // Input decoration for light theme
  static InputDecoration textFieldDecorationLight({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        color: AppColors.lightTextSecondary,
        fontSize: 14,
      ),
      filled: true,
      fillColor: AppColors.lightCardBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      isDense: true,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.lightTextSecondary.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryGreen),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  // Input decoration for dark theme
  static InputDecoration textFieldDecorationDark({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        color: AppColors.darkTextSecondary,
        fontSize: 14,
      ),
      filled: true,
      fillColor: AppColors.darkCardBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      isDense: true,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.darkTextSecondary.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryGold),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
} 