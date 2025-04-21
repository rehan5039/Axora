import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axora/services/user_database_service.dart';
import 'package:axora/services/realtime_database_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserDatabaseService _userDatabaseService = UserDatabaseService();
  final RealtimeDatabaseService _realtimeDatabaseService = RealtimeDatabaseService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '906770746320-aoh8gg8krlj3el1smo6rtmrcss76uvu7.apps.googleusercontent.com' : null,
  );

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update last login timestamp in all databases
      final updateData = {'lastLogin': FieldValue.serverTimestamp()};
      
      // Update in Firestore database
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .update(updateData)
          .catchError((e) {
        // Ignore errors if the document doesn't exist (first login)
        print("Document not found for update in main database - user might be logging in for the first time");
      });
      
      // Update in the secondary Firestore database
      await _userDatabaseService.updateUserData(userCredential.user!.uid, updateData)
          .catchError((e) {
        // Ignore errors if the document doesn't exist
        print("Document not found for update in secondary database - user might be logging in for the first time");
      });
      
      // Update in Realtime Database
      await _realtimeDatabaseService.updateUserData(
          userCredential.user!.uid, 
          {'lastLogin': DateTime.now().millisecondsSinceEpoch}
      ).catchError((e) {
        print("Error updating Realtime Database - user might be logging in for the first time");
      });
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _getReadableAuthError(e.code),
      );
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword(
      String email, String password, {String? fullName}) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update the user's display name if provided
      if (fullName != null && fullName.isNotEmpty) {
        await userCredential.user!.updateDisplayName(fullName);
      }
      
      // Save user data to primary Firestore collection
      await _saveUserDataToFirestore(userCredential.user!, fullName: fullName);
      
      // Save user data to secondary Firestore database
      try {
        await _userDatabaseService.saveUserData(userCredential.user!, fullName: fullName);
      } catch (e) {
        print('Error saving to secondary database: $e');
        // Continue with sign up process even if this fails
      }
      
      // Save user data to Realtime Database - errors handled inside the service
      try {
        await _realtimeDatabaseService.saveUserData(userCredential.user!, fullName: fullName);
      } catch (e) {
        print('Error saving to Realtime Database: $e');
        // Continue with sign up process even if this fails
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _getReadableAuthError(e.code),
      );
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      GoogleSignInAccount? googleUser;
      try {
        // Wrap the Google Sign-In call in a try-catch to handle potential Future errors
        googleUser = await _googleSignIn.signIn();
      } catch (e) {
        debugPrint('Error during Google sign-in: $e');
        if (e.toString().contains('Future already completed')) {
          // If this error occurs, it likely means the sign-in process was already completed
          // or cancelled. We'll just return null to indicate no sign-in occurred.
          return null;
        }
        rethrow;
      }
      
      if (googleUser == null) {
        debugPrint('Google sign-in was cancelled by user');
        return null;
      }

      try {
        final GoogleSignInAuthentication googleAuth = 
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        
        // If this is a new user, save their data to all databases
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          // Save to main Firestore collection
          await _saveUserDataToFirestore(userCredential.user!);
          
          // Save to secondary Firestore database
          try {
            await _userDatabaseService.saveUserData(userCredential.user!);
          } catch (e) {
            debugPrint('Error saving to secondary database: $e');
            // Continue with sign in process even if this fails
          }
          
          // Save to Realtime Database
          try {
            await _realtimeDatabaseService.saveUserData(userCredential.user!);
          } catch (e) {
            debugPrint('Error saving to Realtime Database: $e');
            // Continue with sign in process even if this fails
          }
        } else {
          // Update last login timestamp in all databases
          final firestoreUpdateData = {'lastLogin': FieldValue.serverTimestamp()};
          final realtimeUpdateData = {'lastLogin': DateTime.now().millisecondsSinceEpoch};
          
          // Update Firestore
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .update(firestoreUpdateData);
          
          // Update secondary Firestore database    
          try {
            await _userDatabaseService.updateUserData(
                userCredential.user!.uid, firestoreUpdateData);
          } catch (e) {
            debugPrint('Error updating secondary database: $e');
          }
              
          // Update Realtime Database
          try {
            await _realtimeDatabaseService.updateUserData(
                userCredential.user!.uid, realtimeUpdateData);
          } catch (e) {
            debugPrint('Error updating Realtime Database: $e');
          }
        }
        
        return userCredential;
      } catch (e) {
        debugPrint('Error during authentication with Firebase: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('Google sign in failed: ${e.toString()}');
      throw Exception('Google sign in failed: ${e.toString()}');
    }
  }

  // Save user data to Firestore
  Future<void> _saveUserDataToFirestore(User user, {String? fullName}) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set({
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
    }, SetOptions(merge: true));
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _getReadableAuthError(e.code),
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Helper function to convert Firebase error codes to readable messages
  String _getReadableAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'too-many-requests':
        return 'Too many login attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'An error occurred during authentication: $code';
    }
  }
} 