import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:axora/screens/login_screen.dart';
import 'package:axora/screens/signup_screen.dart';
import 'package:axora/screens/forgot_password_screen.dart';
import 'package:axora/screens/home_screen.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:axora/widgets/theme_showcase.dart';
import 'package:axora/screens/meditation_journey_screen.dart';
import 'package:axora/screens/admin_meditation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Axora',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      initialRoute: '/login',
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
