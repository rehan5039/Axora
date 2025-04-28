import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get current user ID and email
  String? get _userId => _auth.currentUser?.uid;
  String? get _userEmail => _auth.currentUser?.email;
  
  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _userProfilesCollection => _firestore.collection('user_profiles');
  CollectionReference get _adminsCollection => _firestore.collection('admins');
  CollectionReference get _userManagementCollection => _firestore.collection('user_management');
  CollectionReference get _meditationProgressCollection => _firestore.collection('meditation_progress');
  CollectionReference get _meditationStickersCollection => _firestore.collection('meditation_stickers');
  
  // Check if current user is admin
  Future<bool> isAdmin() async {
    if (_userId == null) return false;
    final adminDoc = await _adminsCollection.doc(_userId).get();
    return adminDoc.exists;
  }
  
  // Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      if (!await isAdmin()) {
        throw Exception('Not authorized to access user data');
      }
      
      final usersQuery = await _usersCollection.get();
      final usersList = <Map<String, dynamic>>[];
      
      for (var doc in usersQuery.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        userData['id'] = doc.id;
        
        // Check if user is admin
        final isUserAdmin = await _adminsCollection.doc(doc.id).get();
        userData['isAdmin'] = isUserAdmin.exists;
        
        // Check if user is anonymous
        userData['isAnonymous'] = userData['isAnonymous'] ?? false;
        
        usersList.add(userData);
      }
      
      return usersList;
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }
  
  // Make a user an admin
  Future<bool> makeUserAdmin(String userId, String userEmail) async {
    try {
      if (!await isAdmin()) {
        throw Exception('Not authorized to make users admin');
      }
      
      await _adminsCollection.doc(userId).set({
        'email': userEmail,
        'addedAt': FieldValue.serverTimestamp(),
        'addedBy': _userId,
      });
      
      // Log admin action
      await _userManagementCollection.add({
        'action': 'make_admin',
        'targetUserId': userId,
        'targetUserEmail': userEmail,
        'performedBy': _userId,
        'performedByEmail': _userEmail,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error making user admin: $e');
      return false;
    }
  }
  
  // Remove admin privileges
  Future<bool> removeAdminPrivileges(String userId, String userEmail) async {
    try {
      if (!await isAdmin()) {
        throw Exception('Not authorized to remove admin privileges');
      }
      
      await _adminsCollection.doc(userId).delete();
      
      // Log admin action
      await _userManagementCollection.add({
        'action': 'remove_admin',
        'targetUserId': userId,
        'targetUserEmail': userEmail,
        'performedBy': _userId,
        'performedByEmail': _userEmail,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error removing admin privileges: $e');
      return false;
    }
  }
  
  // Delete a user account
  Future<bool> deleteUser(String userId, String userEmail) async {
    try {
      if (!await isAdmin()) {
        throw Exception('Not authorized to delete users');
      }
      
      // Delete user document
      await _usersCollection.doc(userId).delete();
      
      // Delete user profile if exists
      try {
        await _userProfilesCollection.doc(userId).delete();
      } catch (e) {
        print('Error deleting user profile: $e');
      }
      
      // Delete meditation progress if exists
      try {
        await _meditationProgressCollection.doc(userId).delete();
      } catch (e) {
        print('Error deleting meditation progress: $e');
      }
      
      // Delete meditation stickers if exists
      try {
        await _meditationStickersCollection.doc(userId).delete();
      } catch (e) {
        print('Error deleting meditation stickers: $e');
      }
      
      // Remove from admins if they were an admin
      try {
        final adminDoc = await _adminsCollection.doc(userId).get();
        if (adminDoc.exists) {
          await _adminsCollection.doc(userId).delete();
        }
      } catch (e) {
        print('Error removing from admins: $e');
      }
      
      // Log admin action
      await _userManagementCollection.add({
        'action': 'delete_user',
        'targetUserId': userId,
        'targetUserEmail': userEmail,
        'performedBy': _userId,
        'performedByEmail': _userEmail,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }
  
  /// Deletes all anonymous user accounts from Firestore database
  /// 
  /// IMPORTANT: This only deletes the Firestore data associated with anonymous users.
  /// It does NOT delete the actual Firebase Authentication user accounts.
  /// Firebase Authentication users can only be deleted using the Firebase Admin SDK 
  /// via Cloud Functions or from the Firebase Console manually.
  Future<Map<String, dynamic>> deleteAllAnonymousAccounts() async {
    try {
      if (!await isAdmin()) {
        throw Exception('Not authorized to delete anonymous accounts');
      }
      
      // Get all anonymous users from users collection
      final usersQuery = await _usersCollection.where('isAnonymous', isEqualTo: true).get();
      
      // Also check for anonymous users in the user_profiles collection
      final profilesQuery = await _userProfilesCollection.where('isAnonymous', isEqualTo: true).get();
      
      int successCount = 0;
      int failureCount = 0;
      List<String> deletedIds = [];
      List<String> errorMessages = [];
      
      // Create a set of user IDs to process (from both collections)
      Set<String> userIdsToProcess = {...usersQuery.docs.map((doc) => doc.id)};
      // Add user IDs from profiles collection
      profilesQuery.docs.forEach((doc) => userIdsToProcess.add(doc.id));
      
      // Delete each anonymous user
      for (var userId in userIdsToProcess) {
        try {
          print('Attempting to delete anonymous user data for ID: $userId');
          
          // Delete user profile if exists - try direct approach first
          try {
            final profileDoc = await _userProfilesCollection.doc(userId).get();
            if (profileDoc.exists) {
              await _userProfilesCollection.doc(userId).delete();
              print('Successfully deleted user_profile for $userId');
            } else {
              print('No user_profile found for $userId - may have already been deleted');
            }
          } catch (e) {
            final errorMsg = 'Error deleting user_profile for $userId: $e';
            print(errorMsg);
            errorMessages.add(errorMsg);
          }
          
          // Delete user document if exists
          try {
            final userDoc = await _usersCollection.doc(userId).get();
            if (userDoc.exists) {
              await _usersCollection.doc(userId).delete();
              print('Successfully deleted user document for $userId');
            }
          } catch (e) {
            final errorMsg = 'Error deleting user document for $userId: $e';
            print(errorMsg);
            errorMessages.add(errorMsg);
          }
          
          // Delete meditation progress if exists
          try {
            final progressDoc = await _meditationProgressCollection.doc(userId).get();
            if (progressDoc.exists) {
              await _meditationProgressCollection.doc(userId).delete();
              print('Successfully deleted meditation_progress for $userId');
            }
          } catch (e) {
            print('Error deleting meditation_progress for $userId: $e');
          }
          
          // Delete meditation stickers if exists
          try {
            final stickersDoc = await _meditationStickersCollection.doc(userId).get();
            if (stickersDoc.exists) {
              await _meditationStickersCollection.doc(userId).delete();
              print('Successfully deleted meditation_stickers for $userId');
            }
          } catch (e) {
            print('Error deleting meditation_stickers for $userId: $e');
          }
          
          // Delete user stats if exists
          try {
            final statsDoc = await _firestore.collection('user_stats').doc(userId).get();
            if (statsDoc.exists) {
              await _firestore.collection('user_stats').doc(userId).delete();
              print('Successfully deleted user_stats for $userId');
            }
          } catch (e) {
            print('Error deleting user_stats for $userId: $e');
          }
          
          deletedIds.add(userId);
          successCount++;
          print('Successfully deleted all data for anonymous user: $userId');
        } catch (e) {
          print('Error deleting anonymous user $userId: $e');
          errorMessages.add('Error with $userId: $e');
          failureCount++;
        }
      }
      
      // Log admin action
      await _userManagementCollection.add({
        'action': 'delete_anonymous_accounts',
        'count': successCount,
        'failureCount': failureCount,
        'deletedIds': deletedIds,
        'errorMessages': errorMessages,
        'performedBy': _userId,
        'performedByEmail': _userEmail,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      return {
        'success': true,
        'successCount': successCount,
        'failureCount': failureCount,
        'deletedIds': deletedIds,
        'errorMessages': errorMessages,
        'message': 'Note: This only deletes Firestore data. The Firebase Authentication accounts still exist and must be deleted separately using Firebase Admin SDK via Cloud Functions or from the Firebase Console.',
      };
    } catch (e) {
      print('Error deleting anonymous accounts: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Get user details
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      if (!await isAdmin() && _userId != userId) {
        throw Exception('Not authorized to access user details');
      }
      
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) {
        return null;
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      userData['id'] = userDoc.id;
      
      // Get user profile data if available
      try {
        final profileDoc = await _userProfilesCollection.doc(userId).get();
        if (profileDoc.exists) {
          userData['profile'] = profileDoc.data();
        }
      } catch (e) {
        print('Error getting user profile: $e');
      }
      
      // Check if user is admin
      final isUserAdmin = await _adminsCollection.doc(userId).get();
      userData['isAdmin'] = isUserAdmin.exists;
      
      return userData;
    } catch (e) {
      print('Error getting user details: $e');
      return null;
    }
  }
  
  // Ban a user (for future implementation)
  Future<bool> banUser(String userId, String reason) async {
    try {
      if (!await isAdmin()) {
        throw Exception('Not authorized to ban users');
      }
      
      // Note: This is just recording a ban in Firestore.
      // To fully implement, you would need Firebase Admin SDK or 
      // Cloud Functions to disable the user's account.
      await _userManagementCollection.add({
        'action': 'ban_user',
        'targetUserId': userId,
        'reason': reason,
        'performedBy': _userId,
        'performedByEmail': _userEmail,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending', // Requires manual action or Cloud Function
      });
      
      return true;
    } catch (e) {
      print('Error banning user: $e');
      return false;
    }
  }
  
  // Get admin activity logs
  Future<List<Map<String, dynamic>>> getAdminActivityLogs() async {
    try {
      if (!await isAdmin()) {
        throw Exception('Not authorized to access admin logs');
      }
      
      final logsQuery = await _userManagementCollection
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();
      
      return logsQuery.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting admin activity logs: $e');
      return [];
    }
  }
} 