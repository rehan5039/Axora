import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A service class for handling user data in a secondary database.
/// This allows us to store user data separately from the authentication data.
class UserDatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection reference for users
  final CollectionReference _usersCollection = 
      FirebaseFirestore.instance.collection('user_profiles');
  
  // Get a user by ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    final docSnapshot = await _usersCollection.doc(userId).get();
    return docSnapshot.exists ? docSnapshot.data() as Map<String, dynamic>? : null;
  }
  
  // Save user data to Firestore
  Future<void> saveUserData(User user, {String? fullName, bool isAnonymous = false}) async {
    await _usersCollection.doc(user.uid).set({
      'userId': user.uid,
      'displayName': fullName ?? user.displayName ?? 'User',
      'email': user.email,
      'photoURL': user.photoURL,
      'phoneNumber': user.phoneNumber,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
      'isAnonymous': isAnonymous,
      'authProvider': isAnonymous 
          ? 'anonymous' 
          : (user.providerData.isNotEmpty 
              ? user.providerData[0].providerId 
              : 'firebase'),
      // Additional fields that could be useful
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
    }, SetOptions(merge: true));
  }
  
  // Update user data
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    await _usersCollection.doc(userId).update(data);
  }
  
  // Update user profile fields
  Future<void> updateUserProfile(String userId, Map<String, dynamic> profileData) async {
    await _usersCollection.doc(userId).update({
      'userProfile': profileData,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
  
  // Update user settings
  Future<void> updateUserSettings(String userId, Map<String, dynamic> settingsData) async {
    try {
      // First get the current settings
      final docSnapshot = await _usersCollection.doc(userId).get();
      
      if (docSnapshot.exists) {
        final userData = docSnapshot.data() as Map<String, dynamic>;
        if (userData.containsKey('userSettings') && userData['userSettings'] is Map) {
          // Merge the new settings with existing settings
          final Map<String, dynamic> currentSettings = Map<String, dynamic>.from(
              userData['userSettings'] as Map<String, dynamic>);
          
          // Update the settings
          currentSettings.addAll(settingsData);
          
          // Update the document with merged settings
          await _usersCollection.doc(userId).update({
            'userSettings': currentSettings,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
          
          print('User settings updated with merged data in Firestore');
          return;
        }
      }
      
      // If we can't merge, just update directly
      await _usersCollection.doc(userId).update({
        'userSettings': settingsData,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user settings in Firestore: $e');
      // Rethrow to allow the caller to handle the error
      rethrow;
    }
  }
  
  // Delete user data
  Future<void> deleteUserData(String userId) async {
    await _usersCollection.doc(userId).delete();
  }
  
  // Get a stream of user data changes
  Stream<DocumentSnapshot> userDataStream(String userId) {
    return _usersCollection.doc(userId).snapshots();
  }
  
  // Get all users (with pagination)
  Future<QuerySnapshot> getAllUsers({int limit = 20, DocumentSnapshot? startAfter}) {
    Query query = _usersCollection.orderBy('createdAt', descending: true).limit(limit);
    
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    
    return query.get();
  }
  
  // Search users by name
  Future<QuerySnapshot> searchUsersByName(String name) {
    // Note: This is a simple implementation. For production, consider using Algolia or other search solutions
    return _usersCollection
        .where('displayName', isGreaterThanOrEqualTo: name)
        .where('displayName', isLessThanOrEqualTo: name + '\uf8ff')
        .get();
  }
} 