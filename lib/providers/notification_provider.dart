import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axora/services/user_database_service.dart';
import 'package:axora/services/realtime_database_service.dart';
import 'package:axora/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserDatabaseService _firestoreService = UserDatabaseService();
  final RealtimeDatabaseService _realtimeDbService = RealtimeDatabaseService();
  final NotificationService _notificationService = NotificationService();
  
  bool _notificationsEnabled = true;
  
  NotificationProvider() {
    _loadNotificationPreference();
  }
  
  bool get notificationsEnabled => _notificationsEnabled;
  
  void toggleNotifications() {
    _notificationsEnabled = !_notificationsEnabled;
    _saveNotificationPreference();
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
      
      // If notifications are disabled, cancel all notifications
      if (!_notificationsEnabled) {
        await _notificationService.cancelAllNotifications();
        debugPrint('All notifications cancelled');
      }
      
      debugPrint('Notification preference saved successfully to all databases: enabled=$_notificationsEnabled');
    } catch (e) {
      debugPrint('Error saving notification preference: $e');
    }
  }
} 