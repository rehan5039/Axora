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
  Future<DocumentSnapshot> getUserById(String userId) {
    return _usersCollection.doc(userId).get();
  }
  
  // Save user data to Firestore
  Future<void> saveUserData(User user, {String? fullName}) async {
    await _usersCollection.doc(user.uid).set({
      'userId': user.uid,
      'displayName': fullName ?? user.displayName ?? 'User',
      'email': user.email,
      'photoURL': user.photoURL,
      'phoneNumber': user.phoneNumber,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
      'authProvider': user.providerData.isNotEmpty 
          ? user.providerData[0].providerId 
          : 'firebase',
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
    await _usersCollection.doc(userId).update({
      'userSettings': settingsData,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
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