import 'package:flutter/material.dart';
import 'package:axora/utils/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:axora/services/realtime_database_service.dart';
import 'package:axora/services/user_database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RealtimeDatabaseService _realtimeDbService = RealtimeDatabaseService();
  final UserDatabaseService _firestoreService = UserDatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
        // Try to load from Firestore first
        try {
          final firestoreDoc = await _firestoreService.getUserById(user.uid);
          if (firestoreDoc.exists) {
            final data = firestoreDoc.data() as Map<String, dynamic>;
            if (data.containsKey('userSettings') && 
                data['userSettings'] is Map && 
                data['userSettings'].containsKey('darkMode')) {
              _isDarkMode = data['userSettings']['darkMode'] as bool;
              _initialized = true;
              notifyListeners();
              return;
            }
          }
        } catch (e) {
          debugPrint('Error loading theme from Firestore: $e');
        }
        
        // If Firestore fails, try Realtime Database
        final realtimeData = await _realtimeDbService.getUserData(user.uid);
        if (realtimeData != null && 
            realtimeData.containsKey('userSettings') && 
            realtimeData['userSettings'] is Map && 
            realtimeData['userSettings'].containsKey('darkMode')) {
          _isDarkMode = realtimeData['userSettings']['darkMode'] as bool;
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
    
    // Save to both Firestore and Realtime Database
    _saveThemePreference();
  }

  // Set specific theme and save to Firebase
  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode != value) {
      _isDarkMode = value;
      notifyListeners();
      
      // Save to both Firestore and Realtime Database
      _saveThemePreference();
    }
  }
  
  // Helper method to save theme preferences to all databases
  Future<void> _saveThemePreference() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final themeSettings = {'darkMode': _isDarkMode};
    
    try {
      // 1. Update in user_profiles collection in Firestore
      await _firestoreService.updateUserSettings(user.uid, themeSettings);
      
      // 2. Update in users collection in Firestore
      try {
        // First, get current user settings to preserve notifications preference
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        bool notifications = true; // Default value
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null && 
              userData.containsKey('userSettings') && 
              userData['userSettings'] is Map && 
              userData['userSettings'].containsKey('notifications')) {
            notifications = userData['userSettings']['notifications'] as bool;
          }
        }
        
        // Now update with preserved notification setting
        await _firestore.collection('users').doc(user.uid).update({
          'userSettings': {'darkMode': _isDarkMode, 'notifications': notifications},
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        debugPrint('Theme preference updated in main Firestore with notifications=$notifications');
      } catch (e) {
        // If update fails, try set with merge
        debugPrint('Update failed, trying set with merge: $e');
        await _firestore.collection('users').doc(user.uid).set({
          'userSettings': {'darkMode': _isDarkMode, 'notifications': true}, // Use default for new documents
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('Theme preference set with merge in main Firestore');
      }
      
      // 3. Update in Realtime Database
      await _realtimeDbService.updateUserSettings(user.uid, themeSettings);
      
      debugPrint('Theme preference saved successfully to all databases: isDarkMode=$_isDarkMode');
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
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