import 'package:flutter/material.dart';
import 'package:axora/utils/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:axora/services/realtime_database_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RealtimeDatabaseService _databaseService = RealtimeDatabaseService();
  bool _initialized = false;

  ThemeProvider() {
    _loadThemeFromPreferences();
  }

  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _initialized;

  // Load theme preference from Firebase
  Future<void> _loadThemeFromPreferences() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userData = await _databaseService.getUserData(user.uid);
        if (userData != null && 
            userData.containsKey('userSettings') && 
            userData['userSettings'] is Map && 
            userData['userSettings'].containsKey('darkMode')) {
          _isDarkMode = userData['userSettings']['darkMode'] as bool;
          _initialized = true;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }

  // Toggle theme and save to Firebase
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    
    // Save to Firebase if user is logged in
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _databaseService.updateUserSettings(
          user.uid, 
          {'darkMode': _isDarkMode}
        );
      }
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  // Set specific theme and save to Firebase
  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode != value) {
      _isDarkMode = value;
      notifyListeners();
      
      // Save to Firebase if user is logged in
      try {
        final user = _auth.currentUser;
        if (user != null) {
          await _databaseService.updateUserSettings(
            user.uid, 
            {'darkMode': _isDarkMode}
          );
        }
      } catch (e) {
        debugPrint('Error saving theme preference: $e');
      }
    }
  }

  ThemeData get themeData {
    return _isDarkMode ? _darkTheme : _lightTheme;
  }

  static final _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    primaryColor: AppColors.primaryGreen,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.lightText),
      titleTextStyle: TextStyle(
        color: AppColors.lightText,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardTheme(
      color: AppColors.lightCardBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: AppColors.primaryGreen),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryGreen,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.lightCardBackground,
      labelStyle: const TextStyle(color: AppColors.lightText),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightCardBackground,
      selectedItemColor: AppColors.primaryGreen,
      unselectedItemColor: AppColors.lightTextSecondary,
    ),
    colorScheme: ColorScheme.light(
      primary: AppColors.primaryGreen,
      secondary: AppColors.primaryGold,
      tertiary: AppColors.primaryBlue,
      background: AppColors.lightBackground,
      error: AppColors.error,
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(color: AppColors.lightText),
      displayMedium: GoogleFonts.poppins(color: AppColors.lightText),
      displaySmall: GoogleFonts.poppins(color: AppColors.lightText),
      headlineLarge: GoogleFonts.poppins(color: AppColors.lightText),
      headlineMedium: GoogleFonts.poppins(color: AppColors.lightText),
      headlineSmall: GoogleFonts.poppins(color: AppColors.lightText),
      titleLarge: GoogleFonts.poppins(color: AppColors.lightText),
      titleMedium: GoogleFonts.poppins(color: AppColors.lightText),
      titleSmall: GoogleFonts.poppins(color: AppColors.lightText),
      bodyLarge: GoogleFonts.poppins(color: AppColors.lightText),
      bodyMedium: GoogleFonts.poppins(color: AppColors.lightText),
      bodySmall: GoogleFonts.poppins(color: AppColors.lightText),
    ),
  );

  static final _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    primaryColor: AppColors.primaryGold,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.darkText),
      titleTextStyle: TextStyle(
        color: AppColors.darkText,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardTheme(
      color: AppColors.darkCardBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: AppColors.primaryGold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryGold,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkCardBackground,
      labelStyle: const TextStyle(color: AppColors.darkText),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkCardBackground,
      selectedItemColor: AppColors.primaryGold,
      unselectedItemColor: AppColors.darkTextSecondary,
    ),
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryGold,
      secondary: AppColors.primaryGreen,
      tertiary: AppColors.primaryBlue,
      background: AppColors.darkBackground,
      error: AppColors.error,
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(color: AppColors.darkText),
      displayMedium: GoogleFonts.poppins(color: AppColors.darkText),
      displaySmall: GoogleFonts.poppins(color: AppColors.darkText),
      headlineLarge: GoogleFonts.poppins(color: AppColors.darkText),
      headlineMedium: GoogleFonts.poppins(color: AppColors.darkText),
      headlineSmall: GoogleFonts.poppins(color: AppColors.darkText),
      titleLarge: GoogleFonts.poppins(color: AppColors.darkText),
      titleMedium: GoogleFonts.poppins(color: AppColors.darkText),
      titleSmall: GoogleFonts.poppins(color: AppColors.darkText),
      bodyLarge: GoogleFonts.poppins(color: AppColors.darkText),
      bodyMedium: GoogleFonts.poppins(color: AppColors.darkText),
      bodySmall: GoogleFonts.poppins(color: AppColors.darkText),
    ),
  );
} 