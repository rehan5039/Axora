import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axora/services/user_database_service.dart';
import 'package:axora/services/realtime_database_service.dart';
import 'package:axora/services/notification_service.dart';
import 'package:axora/services/firebase_messaging_service.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserDatabaseService _firestoreService = UserDatabaseService();
  final RealtimeDatabaseService _realtimeDbService = RealtimeDatabaseService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseMessagingService _fcmService = FirebaseMessagingService();
  
  bool _notificationsEnabled = true;
  
  NotificationProvider() {
    _loadNotificationPreference();
  }
  
  bool get notificationsEnabled => _notificationsEnabled;
  
  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    await _saveNotificationPreference();
    
    // When toggling notifications, request permissions if enabling
    if (_notificationsEnabled) {
      await _fcmService.requestPermission();
    }
    
    notifyListeners();
  }
  
  Future<void> _loadNotificationPreference() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      // Try to get settings from Firestore
      final userDoc = await _firestore.collection('user_profiles').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null && 
            userData.containsKey('userSettings') && 
            userData['userSettings'] is Map && 
            userData['userSettings'].containsKey('notifications')) {
          _notificationsEnabled = userData['userSettings']['notifications'] as bool;
          notifyListeners();
          debugPrint('Loaded notification preference: $_notificationsEnabled');
        }
      }
    } catch (e) {
      debugPrint('Error loading notification preference: $e');
    }
  }
  
  Future<void> _saveNotificationPreference() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final notificationSettings = {'notifications': _notificationsEnabled};
    
    try {
      // 1. Update in user_profiles collection in Firestore
      await _firestoreService.updateUserSettings(user.uid, notificationSettings);
      
      // 2. Update in users collection in Firestore (maintain compatibility)
      try {
        // First, get current user settings to preserve theme preference
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        bool darkMode = false; // Default value
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null && 
              userData.containsKey('userSettings') && 
              userData['userSettings'] is Map && 
              userData['userSettings'].containsKey('darkMode')) {
            darkMode = userData['userSettings']['darkMode'] as bool;
          }
        }
        
        // Now update with preserved theme setting
        await _firestore.collection('users').doc(user.uid).update({
          'userSettings': {'darkMode': darkMode, 'notifications': _notificationsEnabled},
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        debugPrint('Notification preference updated in main Firestore with darkMode=$darkMode');
      } catch (e) {
        // If update fails, try set with merge
        debugPrint('Update failed, trying set with merge: $e');
        await _firestore.collection('users').doc(user.uid).set({
          'userSettings': {'darkMode': false, 'notifications': _notificationsEnabled}, // Use default for theme
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('Notification preference set with merge in main Firestore');
      }
      
      // 3. Update in Realtime Database
      await _realtimeDbService.updateUserSettings(user.uid, notificationSettings);
      
      // 4. Handle topic subscriptions based on preference
      if (_notificationsEnabled) {
        // Subscribe to relevant topics
        await _fcmService.subscribeToTopic('meditation_reminders');
        await _fcmService.subscribeToTopic('all_users');
      } else {
        // Unsubscribe from topics and cancel local notifications
        await _fcmService.unsubscribeFromTopic('meditation_reminders');
        await _fcmService.unsubscribeFromTopic('all_users');
        await _notificationService.cancelAllNotifications();
        debugPrint('All notifications cancelled');
      }
      
      debugPrint('Notification preference saved successfully to all databases: enabled=$_notificationsEnabled');
    } catch (e) {
      debugPrint('Error saving notification preference: $e');
    }
  }
  
  /// Request notification permissions explicitly
  Future<void> requestNotificationPermission() async {
    try {
      await _fcmService.requestPermission();
      // Ensure notifications are enabled in our app settings regardless of permission result
      if (!_notificationsEnabled) {
        _notificationsEnabled = true;
        await _saveNotificationPreference();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error in NotificationProvider.requestNotificationPermission: $e');
      // Still enable notifications in our app settings even if permission request fails
      // This way at least local notifications will work
      if (!_notificationsEnabled) {
        _notificationsEnabled = true;
        await _saveNotificationPreference();
        notifyListeners();
      }
    }
  }
} 