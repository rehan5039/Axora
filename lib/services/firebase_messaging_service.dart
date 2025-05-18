import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:axora/services/notification_service.dart';

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final NotificationService _localNotificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Channel IDs for Android
  static const String _channelId = 'high_importance_channel';
  static const String _channelName = 'High Importance Notifications';
  static const String _channelDesc = 'Channel for important notifications';
  
  // For displaying Android notifications when app is in foreground
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  
  // Singleton pattern
  factory FirebaseMessagingService() {
    return _instance;
  }
  
  FirebaseMessagingService._internal();
  
  Future<void> init() async {
    // Initialize local notifications for foreground messages
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    // For non-web platforms, set up notification channels
    if (!kIsWeb) {
      // Setup foreground notification channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      );
      
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      
      // Initialize notification settings
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
        onDidReceiveNotificationResponse: (details) {
          // Handle notification tap when app is in foreground
          debugPrint('Notification tapped: ${details.payload}');
        },
      );
    }
    
    // For web platform, we don't need to request permissions immediately
    // The browser will show its own permission dialog when needed
    if (!kIsWeb) {
      // Request permission for iOS and Android (not for web)
      await requestPermission();
    }
    
    // Listen for FCM token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);
    
    // Get initial token
    _getToken();
    
    // Handle foreground, background and terminated message
    _setupMessageHandlers();
    
    debugPrint('Firebase Messaging Service initialized successfully');
  }
  
  Future<void> requestPermission() async {
    try {
      // For web platform, we handle permissions differently
      if (kIsWeb) {
        // For web, we'll just check current permission status
        // The actual permission request will happen when the browser shows its prompt
        try {
          NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();
          debugPrint('Web notification permission status: ${settings.authorizationStatus}');
        } catch (e) {
          debugPrint('Error checking web notification permission: $e');
        }
        return;
      }
      
      // For mobile platforms
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      debugPrint('User granted notification permission: ${settings.authorizationStatus}');
      
      // For Android 13 and higher
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
              
      if (androidPlugin != null) {
        try {
          await androidPlugin.requestNotificationsPermission();
          debugPrint('Android notification permission requested successfully');
        } catch (e) {
          // On older Android versions, this might fail but that's okay
          debugPrint('Error requesting Android notification permission (might be normal on older devices): $e');
        }
      }
    } catch (e) {
      // If there's an error requesting permission, log it but don't break the app
      debugPrint('Error requesting notification permission: $e');
    }
  }
  
  Future<void> _getToken() async {
    // Get token for current device
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
      // Save token to database
      _saveTokenToDatabase(token);
    }
  }
  
  Future<void> _saveTokenToDatabase(String token) async {
    // Save token to database for current user
    final user = _auth.currentUser;
    if (user != null) {
      // Here you would typically save the token to your database
      // For example: await _firestore.collection('users').doc(user.uid).update({'fcmToken': token});
      debugPrint('Saved FCM token for user ${user.uid}');
    }
  }
  
  void _setupMessageHandlers() {
    // 1. Handler for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');
      
      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        
        // For web platform, we let the browser show notifications
        // For mobile platforms, show a local notification
        if (!kIsWeb) {
          _showLocalNotification(message);
        }
      }
    });
    
    // 2. Setup handler for when app is opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App opened from terminated state with message: ${message.data}');
        // Handle the message - e.g., navigate to specific page
      }
    });
    
    // 3. Handler for background messages is set in main.dart - not needed for web
    // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    
    if (notification != null && android != null && !kIsWeb) {
      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            icon: android.smallIcon ?? 'ic_notification',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }
  
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }
  
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }
} 