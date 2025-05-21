import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '269197339207-7g97lsrgqv15ub6vo87p7q2csb268cv1.apps.googleusercontent.com' : null,
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _realtimeDatabase = FirebaseDatabase.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw 'Google sign in aborted';
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Save user data to Firestore if it's a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'username': userCredential.user!.displayName,
          'email': userCredential.user!.email,
          'photoURL': userCredential.user!.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } catch (e) {
      throw e.toString();
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw e.toString();
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw e.toString();
    }
  }

  // Delete data from Firebase Realtime Database
  Future<void> deleteFromDatabase(String path) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      // Get database reference
      final DatabaseReference ref = FirebaseDatabase.instance.ref(path);
      
      // Delete data
      await ref.remove();
      
      print('Data deleted successfully from path: $path');
      return;
    } catch (e) {
      print('Error deleting data: $e');
      throw e;
    }
  }
  
  // Make current user an admin (in both Realtime Database AND Firestore)
  Future<void> addCurrentUserAsAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      // First, add to Realtime Database (this is what our existing code checks)
      final DatabaseReference adminRef = FirebaseDatabase.instance.ref('admins/${user.uid}');
      await adminRef.set(true);
      
      // Then, add to Firestore with EXPLICIT permissions to match security rules
      await FirebaseFirestore.instance.collection('admins').doc(user.uid).set({
        'isAdmin': true,
        'email': user.email,
        'addedAt': FieldValue.serverTimestamp(),
      });
      
      print('User ${user.email} (${user.uid}) added as admin in both Realtime DB and Firestore');
      return;
    } catch (e) {
      print('Error adding user as admin: $e');
      throw e;
    }
  }
  
  // Check if user is admin (checking BOTH Realtime DB and Firestore)
  Future<bool> canModifyDatabase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // Check Realtime Database admin status
      final adminRef = FirebaseDatabase.instance.ref('admins/${user.uid}');
      final rtdbSnapshot = await adminRef.get();
      
      // Check Firestore admin status
      bool firestoreAdmin = false;
      try {
        final firestoreAdminDoc = await _firestore.collection('admins').doc(user.uid).get();
        firestoreAdmin = firestoreAdminDoc.exists;
      } catch (e) {
        print('Error checking Firestore admin status: $e');
        // Continue anyway, we'll use the RTDB status
      }
      
      // Return true if user is admin in either database 
      // (ideally they should be admin in both, but this helps in transition)
      return rtdbSnapshot.exists || firestoreAdmin;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }
  
  // REALTIME DATABASE METHODS
  
  // Update data in Realtime Database
  Future<void> updateRealtimeDatabase(String path, dynamic data) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      // Check if user is admin
      if (!await canModifyDatabase()) {
        throw Exception('User does not have admin privileges');
      }
      
      // Get database reference
      final DatabaseReference ref = _realtimeDatabase.ref(path);
      
      // Update data
      await ref.set(data);
      
      print('Data updated successfully at path: $path');
      return;
    } catch (e) {
      print('Error updating data: $e');
      throw e;
    }
  }
  
  // Read data from Realtime Database at specific path
  Future<Map<String, dynamic>> getRealtimeDatabaseData(String path) async {
    try {
      final DatabaseReference ref = _realtimeDatabase.ref(path);
      final snapshot = await ref.get();
      
      if (snapshot.exists) {
        final data = snapshot.value;
        if (data is Map) {
          return Map<String, dynamic>.from(data as Map);
        } else {
          // Handle non-map data
          return {'value': data};
        }
      } else {
        return {};
      }
    } catch (e) {
      print('Error getting data: $e');
      throw e;
    }
  }
  
  // FIRESTORE DATABASE METHODS
  
  // Check if user is admin in Firestore (not just Realtime DB)
  Future<bool> isFirestoreAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // Try up to 3 times with exponential backoff
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
          return adminDoc.exists;
        } catch (e) {
          print('Attempt ${attempt + 1} failed to check Firestore admin: $e');
          
          // If this is the last attempt, rethrow
          if (attempt == 2) throw e;
          
          // Wait with exponential backoff before retrying (200ms, 400ms, etc.)
          await Future.delayed(Duration(milliseconds: 200 * (attempt + 1)));
        }
      }
      
      // Should never reach here due to retry logic
      return false;
    } catch (e) {
      print('Error checking Firestore admin status: $e');
      
      // As a fallback, check Realtime Database
      try {
        final adminRef = FirebaseDatabase.instance.ref('admins/${_auth.currentUser?.uid}');
        final snapshot = await adminRef.get();
        return snapshot.exists;
      } catch (rtdbError) {
        print('Realtime DB fallback also failed: $rtdbError');
        return false;
      }
    }
  }

  // Get Firestore collections
  Future<List<String>> getFirestoreCollections() async {
    try {
      // First, check if the user is an admin in Firestore (not just in Realtime DB)
      final isAdmin = await isFirestoreAdmin();
      
      // Collections that anyone can read (based on your security rules)
      List<String> publicCollections = [
        'meditation_content', // As per your rules, this allows read: if true
      ];
      
      // Collections that any authenticated user can read
      List<String> authenticatedUserCollections = [
        'challenges',
        'custom_meditation'
      ];
      
      // Collections that only admins can access
      List<String> adminOnlyCollections = [
        'users',
        'admins',
        'user_management',
        'meditation_progress',
        'user_stats',
        'user_meditation_progress'
      ];
      
      List<String> accessibleCollections = [];
      
      // Add collections the user can definitely access
      accessibleCollections.addAll(publicCollections);
      
      // If user is authenticated, add those collections
      if (_auth.currentUser != null) {
        accessibleCollections.addAll(authenticatedUserCollections);
      }
      
      // If user is admin, add admin collections
      if (isAdmin) {
        accessibleCollections.addAll(adminOnlyCollections);
      }
      
      // For each collection, check if it exists and has documents (with error handling)
      List<String> existingCollections = [];
      for (String collection in accessibleCollections) {
        try {
          // Try to get one document from the collection
          final query = await _firestore.collection(collection).limit(1).get();
          
          // Always include collections, even if empty (for admins)
          if (query.docs.isNotEmpty || isAdmin) {
            existingCollections.add(collection);
          }
        } catch (e) {
          // Skip collections user doesn't have permission to access
          print('No access to collection $collection: $e');
        }
      }
      
      return existingCollections;
    } catch (e) {
      print('Error getting Firestore collections: $e');
      // Return an empty list instead of throwing to avoid crashing the UI
      return [];
    }
  }
  
  // Get documents from a Firestore collection
  Future<List<Map<String, dynamic>>> getFirestoreDocuments(String collectionPath) async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection(collectionPath).get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Add document ID to the data for reference
        data['_id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting Firestore documents: $e');
      throw e;
    }
  }
  
  // Get a specific Firestore document
  Future<Map<String, dynamic>?> getFirestoreDocument(String collectionPath, String documentId) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection(collectionPath).doc(documentId).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        // Add document ID to the data for reference
        data['_id'] = doc.id;
        return data;
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting Firestore document: $e');
      throw e;
    }
  }
  
  // Update a Firestore document
  Future<void> updateFirestoreDocument(String collectionPath, String documentId, Map<String, dynamic> data) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      // Check if user is admin
      if (!await canModifyDatabase()) {
        throw Exception('User does not have admin privileges');
      }
      
      // Remove _id field if it exists as it's not part of the actual data
      data.remove('_id');
      
      await _firestore.collection(collectionPath).doc(documentId).update(data);
      print('Document updated successfully at $collectionPath/$documentId');
    } catch (e) {
      print('Error updating Firestore document: $e');
      throw e;
    }
  }
  
  // Create a new Firestore document
  Future<String> createFirestoreDocument(String collectionPath, Map<String, dynamic> data) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      // Check if user is admin
      if (!await canModifyDatabase()) {
        throw Exception('User does not have admin privileges');
      }
      
      final docRef = await _firestore.collection(collectionPath).add(data);
      print('Document created successfully at $collectionPath/${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating Firestore document: $e');
      throw e;
    }
  }
  
  // Delete a Firestore document
  Future<void> deleteFirestoreDocument(String collectionPath, String documentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      // Check if user is admin
      if (!await canModifyDatabase()) {
        throw Exception('User does not have admin privileges');
      }
      
      await _firestore.collection(collectionPath).doc(documentId).delete();
      print('Document deleted successfully at $collectionPath/$documentId');
    } catch (e) {
      print('Error deleting Firestore document: $e');
      throw e;
    }
  }
} 