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
import 'package:axora/widgets/theme_showcase.dart';
import 'package:axora/screens/meditation_journey_screen.dart';
import 'package:axora/screens/admin_meditation_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:axora/services/meditation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Set persistence to LOCAL (keeps user logged in across refreshes)
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    
    // Configure Firebase Realtime Database URL explicitly
    try {
      FirebaseDatabase.instance.databaseURL = 'https://axora-5039-default-rtdb.firebaseio.com';
      debugPrint('Firebase Realtime Database URL configured successfully');
    } catch (e) {
      debugPrint('Failed to configure Firebase Realtime Database URL: $e');
      // Continue app initialization even if this fails
    }
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
    // Continue with app initialization even if Firebase initialization fails
  }
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
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
  final _meditationService = MeditationService();

  @override
  void initState() {
    super.initState();
    // Check for day unlocks every hour
    _startUnlockCheckTimer();
  }

  @override
  void dispose() {
    _unlockCheckTimer?.cancel();
    super.dispose();
  }

  void _startUnlockCheckTimer() {
    // Cancel any existing timer
    _unlockCheckTimer?.cancel();
    
    // Check for unlocks every 15 minutes
    _unlockCheckTimer = Timer.periodic(const Duration(minutes: 15), (_) async {
      // Only check if the user is logged in
      if (FirebaseAuth.instance.currentUser != null) {
        try {
          debugPrint('Scheduled check: Checking if any days need to be unlocked...');
          final result = await _meditationService.updateCurrentDayIfTimerExpired();
          if (result) {
            debugPrint('Scheduled check: Successfully unlocked next day!');
          }
        } catch (e) {
          debugPrint('Scheduled check: Error checking for day unlocks: $e');
        }
      }
    });
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
      },
    );
  }
}
