import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'package:axora/screens/login_screen.dart';
import 'package:axora/screens/signup_screen.dart';
import 'package:axora/screens/forgot_password_screen.dart';
import 'package:axora/screens/home_screen.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:axora/providers/notification_provider.dart';
import 'package:axora/widgets/theme_showcase.dart';
import 'package:axora/screens/meditation_journey_screen.dart';
import 'package:axora/screens/admin_meditation_screen.dart';
import 'package:axora/screens/admin_dashboard_screen.dart';
import 'package:axora/screens/admin_user_management_screen.dart';
import 'package:axora/screens/contact_support_screen.dart';
import 'package:axora/screens/community_support_screen.dart';
import 'package:axora/screens/meditation_reminder_screen.dart';
import 'package:axora/screens/settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:axora/services/meditation_service.dart';
import 'package:axora/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  // Ensure proper widget initialization
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Ensure the binding is properly attached
  if (!widgetsBinding.debugDidSendFirstFrameEvent) {
    widgetsBinding.addPostFrameCallback((_) {
      debugPrint('First frame rendered');
    });
  }
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Set persistence to LOCAL (keeps user logged in across refreshes)
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    
    // Configure Firebase Realtime Database URL explicitly
    try {
      FirebaseDatabase.instance.databaseURL = 'https://axora-we-default-rtdb.firebaseio.com';
      debugPrint('Firebase Realtime Database URL configured successfully');
    } catch (e) {
      debugPrint('Failed to configure Firebase Realtime Database URL: $e');
    }
    
    // Initialize notification service
    await NotificationService().init();
    debugPrint('Notification service initialized successfully');
    
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }
  
  // Remove splash screen once initialization is done
  FlutterNativeSplash.remove();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Timer? _unlockCheckTimer;
  Timer? _midnightCheckTimer;
  DateTime? _lastMidnightCheck;
  final _meditationService = MeditationService();

  @override
  void initState() {
    super.initState();
    // Initialize timers
    _startUnlockCheckTimer();
    _startMidnightCheckTimer();
  }

  @override
  void dispose() {
    _unlockCheckTimer?.cancel();
    _midnightCheckTimer?.cancel();
    super.dispose();
  }

  void _startUnlockCheckTimer() {
    // Immediately check for unlocks
    if (FirebaseAuth.instance.currentUser != null) {
      try {
        debugPrint('Initial check: Checking if any days need to be unlocked...');
        _meditationService.updateCurrentDayIfTimerExpired();
      } catch (e) {
        debugPrint('Initial check: Error checking for day unlocks: $e');
      }
    }
    
    // Set up periodic timer that checks every hour for unlocks
    _unlockCheckTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      if (FirebaseAuth.instance.currentUser != null) {
        try {
          // Check for day unlocks (existing functionality)
          _meditationService.updateCurrentDayIfTimerExpired();
        } catch (e) {
          debugPrint('Periodic check: Error checking for day unlocks: $e');
        }
      }
    });
  }
  
  void _startMidnightCheckTimer() {
    // Set current date for comparison
    _lastMidnightCheck = DateTime.now();
    debugPrint('Midnight check timer initialized: ${_lastMidnightCheck!.toIso8601String()}');
    
    // Also do an initial flow check
    _checkForFlowReduction();
    
    // Check every 15 minutes for midnight transition
    _midnightCheckTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      if (FirebaseAuth.instance.currentUser != null) {
        final now = DateTime.now();
        final lastCheck = _lastMidnightCheck!;
        
        // Check if we've crossed midnight since last check
        if (now.day != lastCheck.day || now.month != lastCheck.month || now.year != lastCheck.year) {
          debugPrint('Detected day change: ${lastCheck.toIso8601String()} -> ${now.toIso8601String()}');
          
          // Update last check time
          _lastMidnightCheck = now;
          
          // Run flow reduction check at day change
          _checkForFlowReduction();
        }
      }
    });
  }
  
  void _checkForFlowReduction() async {
    if (FirebaseAuth.instance.currentUser != null) {
      try {
        debugPrint('Checking if flow should be reduced due to missed meditation...');
        final result = await _meditationService.checkAndReduceFlowIfDayMissed();
        debugPrint('Flow reduction check result: $result');
      } catch (e) {
        debugPrint('Error checking for flow reduction: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Axora',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          if (snapshot.hasData && snapshot.data != null) {
            // User is logged in
            return const HomeScreen();
          }
          
          // User is not logged in
          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/theme-showcase': (context) => const ThemeShowcase(),
        '/meditation-journey': (context) => const MeditationJourneyScreen(),
        '/admin-meditation': (context) => const AdminMeditationScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/admin-user-management': (context) => const AdminUserManagementScreen(),
        '/contact-support': (context) => const ContactSupportScreen(),
        '/community-support': (context) => const CommunitySupportScreen(),
        '/meditation-reminder': (context) => const MeditationReminderScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
