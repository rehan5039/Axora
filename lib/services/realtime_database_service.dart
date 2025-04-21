import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;

/// A service class for handling user data in Firebase Realtime Database.
/// This is the third place to store user data alongside Firestore and the external API.
class RealtimeDatabaseService {
  final FirebaseDatabase _database;
  
  // Constructor with specific database URL
  RealtimeDatabaseService() : _database = FirebaseDatabase.instance {
    try {
      // Set the database URL explicitly based on your Firebase project
      _database.databaseURL = 'https://axora-5039-default-rtdb.firebaseio.com';
    } catch (e) {
      print('Error configuring Realtime Database URL: $e');
    }
  }
  
  // Reference to the users node in the database
  DatabaseReference get _usersRef => _database.ref().child('users');
  
  // Save user data to Realtime Database
  Future<void> saveUserData(User user, {String? fullName, bool isAnonymous = false}) async {
    try {
      await _usersRef.child(user.uid).set({
        'userId': user.uid,
        'displayName': fullName ?? user.displayName ?? 'User',
        'email': user.email,
        'photoURL': user.photoURL,
        'phoneNumber': user.phoneNumber,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'lastLogin': DateTime.now().millisecondsSinceEpoch,
        'isAnonymous': isAnonymous,
        'authProvider': isAnonymous 
            ? 'anonymous' 
            : (user.providerData.isNotEmpty 
                ? user.providerData[0].providerId 
                : 'firebase'),
        'isEmailVerified': user.emailVerified,
        'userSettings': {
          'notifications': true,
          'darkMode': false,
        },
        'userProfile': {
          'bio': '',
          'location': '',
          'interests': [],
        }
      });
      
      print('User data saved to Realtime Database successfully');
    } catch (e) {
      print('Error saving user data to Realtime Database: $e');
      // Don't rethrow to prevent signup process from failing
      // Just log the error and continue
    }
  }
  
  // Update user data in Realtime Database
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      // Convert timestamps to milliseconds if needed
      final updatedData = Map<String, dynamic>.from(data);
      
      // Check if the data contains a Firestore FieldValue
      if (updatedData.containsKey('lastLogin')) {
        // For Realtime Database, we need to use a timestamp in milliseconds
        updatedData['lastLogin'] = DateTime.now().millisecondsSinceEpoch;
      }
      
      await _usersRef.child(userId).update(updatedData);
      print('User data updated in Realtime Database successfully');
    } catch (e) {
      print('Error updating user data in Realtime Database: $e');
      // Don't rethrow the error to prevent authentication flows from failing
    }
  }
  
  // Get user data from Realtime Database
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final snapshot = await _usersRef.child(userId).get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      print('Error getting user data from Realtime Database: $e');
      return null;
    }
  }
  
  // Update user profile fields
  Future<void> updateUserProfile(String userId, Map<String, dynamic> profileData) async {
    try {
      await _usersRef.child(userId).child('userProfile').update(profileData);
      await _usersRef.child(userId).update({
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error updating user profile in Realtime Database: $e');
      // Don't rethrow
    }
  }
  
  // Update user settings
  Future<void> updateUserSettings(String userId, Map<String, dynamic> settingsData) async {
    try {
      // First get the current settings
      final snapshot = await _usersRef.child(userId).child('userSettings').get();
      
      if (snapshot.exists) {
        // Merge the new settings with existing settings
        final Map<String, dynamic> currentSettings = 
            Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
        
        // Update the settings
        currentSettings.addAll(settingsData);
        
        // Update with merged settings
        await _usersRef.child(userId).child('userSettings').update(currentSettings);
        await _usersRef.child(userId).update({
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        });
        
        print('User settings updated with merged data in Realtime Database');
        return;
      }
      
      // If no existing settings, just update directly
      await _usersRef.child(userId).child('userSettings').update(settingsData);
      await _usersRef.child(userId).update({
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
      
      print('User settings updated in Realtime Database');
    } catch (e) {
      print('Error updating user settings in Realtime Database: $e');
      // Don't rethrow
    }
  }
  
  // Delete user data
  Future<void> deleteUserData(String userId) async {
    try {
      await _usersRef.child(userId).remove();
    } catch (e) {
      print('Error deleting user data from Realtime Database: $e');
      // Don't rethrow
    }
  }
  
  // Listen to user data changes
  Stream<DatabaseEvent> userDataStream(String userId) {
    try {
      return _usersRef.child(userId).onValue;
    } catch (e) {
      print('Error setting up Realtime Database stream: $e');
      // Return an empty stream in case of error
      return Stream.empty();
    }
  }
}

// Helper function to convert Firestore values to Realtime Database compatible values
dynamic convertToRealtimeDbValue(dynamic value) {
  if (value is DateTime) {
    return value.millisecondsSinceEpoch;
  }
  // We should never reach this check in normal code flow now
  // But keeping a simplified version for completeness
  if (value is FieldValue) {
    return DateTime.now().millisecondsSinceEpoch;
  }
  return value;
} 