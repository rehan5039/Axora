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
  CollectionReference get _adminsCollection => _firestore.collection('admins');
  CollectionReference get _progressCollection => _firestore.collection('meditation_progress');
  CollectionReference get _meditationFlowCollection => _firestore.collection('meditation_flow');
  CollectionReference get _userProfilesCollection => _firestore.collection('user_profiles');
  CollectionReference get _userStatsCollection => _firestore.collection('user_stats');
  CollectionReference get _userManagementCollection => _firestore.collection('user_management');
  
  // Check if current user is admin
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    final adminDoc = await _adminsCollection.doc(user.uid).get();
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
  
  // Delete a user completely (admin only)
  Future<bool> deleteUser(String userId) async {
    try {
      if (!await isAdmin()) {
        print('Only admins can delete users');
        return false;
      }
      
      print('Starting deletion process for user: $userId');
      
      // Delete Firestore data
      // Delete user auth data and all related collections
      
      // Delete meditation progress if exists
      try {
        await _progressCollection.doc(userId).delete();
      } catch (e) {
        print('Error deleting meditation progress: $e');
      }
      
      // Delete meditation flow if exists
      try {
        await _meditationFlowCollection.doc(userId).delete();
      } catch (e) {
        print('Error deleting meditation flow: $e');
      }
      
      // Delete user profile if exists
      try {
        await _userProfilesCollection.doc(userId).delete();
      } catch (e) {
        print('Error deleting user profile: $e');
      }
      
      // Delete user stats if exists
      try {
        await _userStatsCollection.doc(userId).delete();
      } catch (e) {
        print('Error deleting user stats: $e');
      }
      
      // Delete user document itself
      try {
        await _usersCollection.doc(userId).delete();
      } catch (e) {
        print('Error deleting user document: $e');
      }
      
      // Delete from admins collection if admin
      try {
        final adminDoc = await _adminsCollection.doc(userId).get();
        if (adminDoc.exists) {
          await _adminsCollection.doc(userId).delete();
        }
      } catch (e) {
        print('Error checking/deleting admin status: $e');
      }
      
      print('Successfully deleted Firestore data for user $userId');
      
      return true;
    } catch (e) {
      print('Error in deleteUser: $e');
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
            final progressDoc = await _progressCollection.doc(userId).get();
            if (progressDoc.exists) {
              await _progressCollection.doc(userId).delete();
              print('Successfully deleted meditation_progress for $userId');
            }
          } catch (e) {
            print('Error deleting meditation_progress for $userId: $e');
          }
          
          // Delete meditation flow if exists
          try {
            final flowDoc = await _meditationFlowCollection.doc(userId).get();
            if (flowDoc.exists) {
              await _meditationFlowCollection.doc(userId).delete();
              print('Successfully deleted meditation_flow for $userId');
            }
          } catch (e) {
            print('Error deleting meditation_flow for $userId: $e');
          }
          
          // Delete user stats if exists
          try {
            final statsDoc = await _userStatsCollection.doc(userId).get();
            if (statsDoc.exists) {
              await _userStatsCollection.doc(userId).delete();
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
  
  // Reset user progress (admin only)
  Future<bool> resetUserProgress(String userId) async {
    try {
      // Check if user is admin
      if (!await isAdmin()) {
        print('Only admins can reset user progress');
        return false;
      }
      
      print('Starting progress reset for user: $userId');
      
      // Get user email for recreation
      String? userEmail;
      try {
        final userDoc = await _usersCollection.doc(userId).get();
        if (userDoc.exists) {
          userEmail = userDoc.get('email') as String?;
        }
      } catch (e) {
        print('Error getting user email: $e');
      }
      
      // Delete meditation progress if exists
      try {
        await _progressCollection.doc(userId).delete();
        print('Successfully deleted meditation_progress for $userId');
      } catch (e) {
        print('Error deleting meditation_progress for $userId: $e');
      }
      
      // Delete meditation flow if exists
      try {
        final flowDoc = await _meditationFlowCollection.doc(userId).get();
        if (flowDoc.exists) {
          await _meditationFlowCollection.doc(userId).delete();
          print('Successfully deleted meditation_flow for $userId');
        }
      } catch (e) {
        print('Error deleting meditation_flow for $userId: $e');
      }
      
      // Recreate progress with initial values if we have email
      if (userEmail != null) {
        try {
          // Create new progress document
          await _progressCollection.doc(userId).set({
            'userId': userId,
            'email': userEmail,
            'currentDay': 1,
            'lastCompletedDay': 0,
            'createdAt': FieldValue.serverTimestamp(),
            'lastCompletedAt': null,
          });
          
          // Create new flow document
          await _meditationFlowCollection.doc(userId).set({
            'userId': userId,
            'email': userEmail,
            'flow': 0,
            'earnedFromDays': [],
            'flowAchievements': {},
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          print('Successfully recreated initial documents for $userId');
        } catch (e) {
          print('Error recreating documents: $e');
          return false;
        }
      }
      
      return true;
    } catch (e) {
      print('Error in resetUserProgress: $e');
      return false;
    }
  }
  
  // Reset user account completely (admin only)
  Future<bool> resetUserAccount(String userId) async {
    try {
      // Check if user is admin
      if (!await isAdmin()) {
        print('Only admins can reset user accounts');
        return false;
      }
      
      print('Starting complete account reset for user: $userId');
      
      // Get user email for recreation
      String? userEmail;
      try {
        final userDoc = await _usersCollection.doc(userId).get();
        if (userDoc.exists) {
          userEmail = userDoc.get('email') as String?;
        }
      } catch (e) {
        print('Error getting user email: $e');
      }
      
      if (userEmail == null) {
        print('Cannot reset account without user email');
        return false;
      }
      
      // Delete meditation progress
      try {
        await _progressCollection.doc(userId).delete();
        print('Successfully deleted meditation_progress for $userId');
      } catch (e) {
        print('Error deleting meditation_progress for $userId: $e');
      }
      
      // Delete meditation flow
      try {
        await _meditationFlowCollection.doc(userId).delete();
        print('Successfully deleted meditation_flow for $userId');
      } catch (e) {
        print('Error deleting meditation_flow for $userId: $e');
      }
      
      // Delete user stats
      try {
        await _userStatsCollection.doc(userId).delete();
        print('Successfully deleted user_stats for $userId');
      } catch (e) {
        print('Error deleting user_stats for $userId: $e');
      }
      
      // Delete all completed articles and audios in user_profiles
      try {
        final articlesDocs = await _userProfilesCollection.doc(userId).collection('completed_articles').get();
        for (var doc in articlesDocs.docs) {
          await doc.reference.delete();
        }
        
        final audiosDocs = await _userProfilesCollection.doc(userId).collection('completed_audios').get();
        for (var doc in audiosDocs.docs) {
          await doc.reference.delete();
        }
        
        print('Successfully deleted all completed content for $userId');
      } catch (e) {
        print('Error deleting completed content: $e');
      }
      
      // Wait a moment to ensure deletions are processed
      await Future.delayed(Duration(milliseconds: 500));
      
      // Recreate documents with initial values
      try {
        final now = Timestamp.now();
        
        // Create new progress document with all required fields
        final progressData = {
          'userId': userId,
          'email': userEmail,
          'currentDay': 1,
          'lastCompletedDay': 0,
          'completedDays': [],
          'lastCompletedAt': now,
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        await _progressCollection.doc(userId).set(progressData);
        print('Successfully recreated progress document for $userId');
        
        // Create new flow document with all required fields
        final flowData = {
          'userId': userId,
          'email': userEmail,
          'flow': 0,
          'earnedFromDays': [],
          'flowAchievements': {},
          'lastMeditationDate': now,
          'totalFlowLost': 0,
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        await _meditationFlowCollection.doc(userId).set(flowData);
        print('Successfully recreated flow document for $userId');
        
        // Create new stats document with all required fields
        final statsData = {
          'userId': userId,
          'email': userEmail,
          'currentStreak': 0,
          'longestStreak': 0,
          'totalMinutes': 0,
          'sessionsCompleted': 0,
          'totalFlowLost': 0,
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        await _userStatsCollection.doc(userId).set(statsData);
        print('Successfully recreated stats document for $userId');
        
        // Log admin action
        await _userManagementCollection.add({
          'action': 'reset_user_account',
          'targetUserId': userId,
          'targetUserEmail': userEmail,
          'performedBy': _userId,
          'performedByEmail': _userEmail,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        return true;
      } catch (e) {
        print('Error recreating documents: $e');
        print('Detailed error: ${e.toString()}');
        return false;
      }
    } catch (e) {
      print('Error in resetUserAccount: $e');
      return false;
    }
  }
  
  // Edit user flow (admin only)
  Future<bool> editUserFlow(String userId, int newFlowValue) async {
    try {
      // Check if user is admin
      if (!await isAdmin()) {
        print('Only admins can edit user flow');
        return false;
      }
      
      if (newFlowValue < 0) {
        print('Flow value cannot be negative');
        return false;
      }
      
      print('Editing flow for user: $userId to value: $newFlowValue');
      
      // Get user email for logging
      String? userEmail;
      try {
        final userDoc = await _usersCollection.doc(userId).get();
        if (userDoc.exists) {
          userEmail = userDoc.get('email') as String?;
        }
      } catch (e) {
        print('Error getting user email: $e');
      }
      
      // Update flow in meditation_flow collection
      try {
        await _meditationFlowCollection.doc(userId).update({
          'flow': newFlowValue,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        print('Successfully updated flow for $userId to $newFlowValue');
      } catch (e) {
        print('Error updating flow: $e');
        return false;
      }
      
      // Also update the currentStreak in user_stats to keep them in sync
      try {
        await _userStatsCollection.doc(userId).update({
          'currentStreak': newFlowValue,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        print('Successfully updated currentStreak for $userId to $newFlowValue');
      } catch (e) {
        print('Error updating currentStreak: $e');
        // Continue anyway as the main flow update was successful
      }
      
      // Log admin action
      await _userManagementCollection.add({
        'action': 'edit_user_flow',
        'targetUserId': userId,
        'targetUserEmail': userEmail,
        'oldFlowValue': null, // We don't have the old value here
        'newFlowValue': newFlowValue,
        'performedBy': _userId,
        'performedByEmail': _userEmail,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error in editUserFlow: $e');
      return false;
    }
  }
} 