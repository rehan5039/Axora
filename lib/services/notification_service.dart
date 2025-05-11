import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isInitialized = false;
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();
  
  Future<void> init() async {
    if (_isInitialized) return;
    
    tz_data.initializeTimeZones();
    
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initSettings = 
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
    );
    
    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'meditation_journey_channel',
      'Meditation Journey Notifications',
      description: 'Notifications for Meditation Journey app',
      importance: Importance.high,
    );
    
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    
    // Request notification permissions
    await requestPermissions();
    
    _isInitialized = true;
    debugPrint('Notification service initialized successfully');
  }
  
  Future<bool> _areNotificationsEnabled() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    try {
      // Try to get settings from Firestore
      final userDoc = await _firestore.collection('user_profiles').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null && 
            userData.containsKey('userSettings') && 
            userData['userSettings'] is Map && 
            userData['userSettings'].containsKey('notifications')) {
          return userData['userSettings']['notifications'] as bool;
        }
      }
      return true; // Default to enabled if no setting found
    } catch (e) {
      debugPrint('Error checking notification preference: $e');
      return true; // Default to enabled on error
    }
  }
  
  Future<void> requestPermissions() async {
    if (kIsWeb) {
      // For web, we need to handle permissions differently
      debugPrint('Running on web, notification permissions handled differently');
      return;
    }
    
    // For Android/iOS
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        
    // For Android 13 and above
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }
  
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!await _areNotificationsEnabled()) {
      debugPrint('Notifications are disabled. Skipping notification display.');
      return;
    }
    
    const AndroidNotificationDetails androidDetails = 
        AndroidNotificationDetails(
      'meditation_journey_channel',
      'Meditation Journey Notifications',
      channelDescription: 'Notifications for Meditation Journey app',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
    );
    
    const DarwinNotificationDetails iosDetails = 
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails notificationDetails = 
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }
  
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (!await _areNotificationsEnabled()) {
      debugPrint('Notifications are disabled. Skipping notification scheduling.');
      return;
    }
    
    const AndroidNotificationDetails androidDetails = 
        AndroidNotificationDetails(
      'meditation_journey_channel',
      'Meditation Journey Notifications',
      channelDescription: 'Notifications for Meditation Journey app',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
    );
    
    const DarwinNotificationDetails iosDetails = 
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails notificationDetails = 
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
  
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }
  
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
  
  /// Shows notification when a new day is unlocked in the meditation journey
  Future<void> showDayUnlockedNotification(int dayNumber) async {
    await showNotification(
      id: 1000 + dayNumber, // Unique ID based on day number
      title: 'Day $dayNumber Unlocked!',
      body: 'Your next meditation journey day is now available. Continue your practice today.',
    );
  }
  
  /// Schedules a notification for when the next day will be unlocked
  Future<void> scheduleDayUnlockNotification(int dayNumber, Duration timeRemaining) async {
    final scheduledDate = DateTime.now().add(timeRemaining);
    
    await scheduleNotification(
      id: 1000 + dayNumber, // Unique ID based on day number
      title: 'New Day Available!',
      body: 'Day $dayNumber of your meditation journey is now available.',
      scheduledDate: scheduledDate,
    );
  }
  
  /// Schedules a daily recurring meditation reminder with user's custom message
  Future<void> scheduleDailyMeditationReminder({
    required int hour,
    required int minute,
    required String userName,
    String customMessage = '',
  }) async {
    try {
      // Cancel any existing reminder first
      await cancelNotification(9000);
      
      // Calculate when to schedule notification
      final now = DateTime.now();
      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      
      // If the time for today has already passed, schedule for tomorrow
      final scheduleDateTime = scheduledTime.isBefore(now)
          ? scheduledTime.add(Duration(days: 1))
          : scheduledTime;
      
      // Create notification body with custom message if provided
      String body = 'Hi $userName, Tumhara meditation session ready hai.';
      if (customMessage.isNotEmpty) {
        body += '\n$customMessage';
      }
      
      // For web platform, we'll just log the notification instead of scheduling
      if (kIsWeb) {
        debugPrint('Web platform: Would schedule notification at $scheduleDateTime with message: $body');
        return;
      }
      
      // Schedule the notification for mobile platforms
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'meditation_journey_channel',
        'Meditation Journey Notifications',
        channelDescription: 'Notifications for Meditation Journey app',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
      );
      
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails, 
        iOS: iosDetails
      );
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        9000,
        'Meditation Reminder',
        body,
        tz.TZDateTime.from(scheduleDateTime, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      
      debugPrint('Daily meditation reminder scheduled for: $scheduleDateTime');
      return;
    } catch (e) {
      debugPrint('Error scheduling daily meditation reminder: $e');
      // Don't rethrow to prevent app crashes
    }
  }
} 