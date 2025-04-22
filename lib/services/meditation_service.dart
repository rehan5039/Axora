import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:axora/models/meditation_content.dart';
import 'package:axora/models/user_progress.dart';
import 'package:axora/models/user_stickers.dart';

class MeditationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get current user ID and email
  String? get _userId => _auth.currentUser?.uid;
  String? get _userEmail => _auth.currentUser?.email;
  
  // Collection references
  CollectionReference get _contentCollection => _firestore.collection('meditation_content');
  CollectionReference get _progressCollection => _firestore.collection('meditation_progress');
  CollectionReference get _stickersCollection => _firestore.collection('meditation_stickers');
  CollectionReference get _adminsCollection => _firestore.collection('admins');
  
  // Check if current user is admin
  Future<bool> isAdmin() async {
    if (_userId == null) return false;
    final adminDoc = await _adminsCollection.doc(_userId).get();
    return adminDoc.exists;
  }
  
  // Add admin
  Future<bool> addAdmin(String adminEmail) async {
    try {
      // Only existing admins can add new admins
      if (!await isAdmin()) return false;

      // Get user by email
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: adminEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) return false;

      final userId = userQuery.docs.first.id;
      await _adminsCollection.doc(userId).set({
        'email': adminEmail,
        'addedAt': FieldValue.serverTimestamp(),
        'addedBy': _userId,
      });

      return true;
    } catch (e) {
      print('Error adding admin: $e');
      return false;
    }
  }
  
  // Get meditation content for a specific day
  Future<MeditationContent?> getMeditationContentForDay(int day) async {
    try {
      final querySnapshot = await _contentCollection
          .where('day', isEqualTo: day)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      return MeditationContent.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      print('Error getting meditation content: $e');
      return null;
    }
  }
  
  // Get all meditation content
  Future<List<MeditationContent>> getAllMeditationContent() async {
    try {
      print('Fetching all meditation content from Firestore...');
      print('Collection path: ${_contentCollection.path}');
      
      // First, check if collection exists and has documents
      final collectionRef = _firestore.collection('meditation_content');
      final querySnapshot = await collectionRef.get();
      
      print('Retrieved ${querySnapshot.docs.length} meditation content documents');
      
      if (querySnapshot.docs.isEmpty) {
        print('WARNING: No documents found in meditation_content collection');
        
        // Check if a specific Day-1 document exists directly
        final day1DocRef = collectionRef.doc('Day-1');
        final day1Doc = await day1DocRef.get();
        
        if (day1Doc.exists) {
          print('Found Day-1 document directly: ${day1Doc.data()}');
          
          try {
            final content = MeditationContent.fromFirestore(day1Doc);
            return [content];
          } catch (e) {
            print('Error parsing Day-1 document: $e');
          }
        } else {
          print('Day-1 document does not exist either');
        }
        
        // For debugging: Log the collection path
        print('Collection path being queried: ${collectionRef.path}');
        
        return [];
      }
      
      // Debug the retrieved documents
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        print('Document ID: ${doc.id}, Data: $data');
        
        // Check if document has the required fields
        if (data['day'] == null) {
          print('WARNING: Document ${doc.id} is missing required field "day"');
        }
        if (data['title'] == null) {
          print('WARNING: Document ${doc.id} is missing required field "title"');
        }
        if (data['article'] == null) {
          print('WARNING: Document ${doc.id} is missing required field "article"');
        }
        if (data['audio'] == null) {
          print('WARNING: Document ${doc.id} is missing required field "audio"');
        }
      }
      
      // Convert documents to MeditationContent objects
      final meditationContents = querySnapshot.docs
          .where((doc) => doc.data().containsKey('day')) // Filter out invalid documents
          .map((doc) {
            try {
              return MeditationContent.fromFirestore(doc);
            } catch (e) {
              print('Error parsing document ${doc.id}: $e');
              return null;
            }
          })
          .where((content) => content != null)
          .cast<MeditationContent>()
          .toList();
      
      print('Successfully parsed ${meditationContents.length} meditation content documents');
      return meditationContents;
    } catch (e) {
      print('Error getting all meditation content: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }
  
  // Add meditation content (admin only)
  Future<bool> addMeditationContent({
    required int day,
    required String title,
    required ArticleContent article,
    required AudioContent audio,
  }) async {
    try {
      // Check if user is admin
      if (!await isAdmin()) {
        print('User is not authorized to add meditation content');
        return false;
      }

      print('Adding new meditation content to Firestore...');
      print('Collection path: ${_contentCollection.path}');
      
      final docRef = await _contentCollection.add({
        'day': day,
        'title': title,
        'article': article.toMap(),
        'audio': audio.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _userEmail,
        'isActive': true,
      });
      
      print('Document added successfully with ID: ${docRef.id}');
      return true;
    } catch (e) {
      print('Error adding meditation content: $e');
      return false;
    }
  }
  
  // Update meditation content
  Future<bool> updateMeditationContent({
    required String contentId,
    required String title,
    required ArticleContent article,
    required AudioContent audio,
    required bool isActive,
  }) async {
    try {
      final docRef = _firestore.collection('meditation_content').doc(contentId);
      
      await docRef.update({
        'title': title,
        'article': article.toMap(),
        'audio': audio.toMap(),
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error updating meditation content: $e');
      return false;
    }
  }
  
  // Get user progress with email
  Future<UserProgress?> getUserProgress() async {
    if (_userId == null || _userEmail == null) return null;
    
    try {
      final doc = await _progressCollection.doc(_userId).get();
      
      if (!doc.exists) {
        // Create initial progress if it doesn't exist
        final initialProgress = UserProgress(
          userId: _userId!,
          email: _userEmail!,
          currentDay: 1,
          lastCompletedDay: 0,
          lastCompletedAt: Timestamp.now(),
          completedDays: [],
        );
        
        await _progressCollection.doc(_userId).set(initialProgress.toFirestore());
        return initialProgress;
      }
      
      return UserProgress.fromFirestore(doc);
    } catch (e) {
      print('Error getting user progress: $e');
      return null;
    }
  }
  
  // Update user progress when a day is completed
  Future<bool> completeDay(int day) async {
    if (_userId == null) return false;
    
    try {
      // Get current progress
      final progress = await getUserProgress();
      if (progress == null) return false;
      
      // Check if this day is already completed
      if (progress.completedDays.contains(day)) {
        return true; // Already completed
      }
      
      // Update progress
      final updatedCompletedDays = List<int>.from(progress.completedDays)..add(day);
      int nextDay = progress.currentDay;
      
      // If completing current day, increment currentDay if 24 hours have passed
      if (day == progress.currentDay && progress.canUnlockNextDay()) {
        nextDay = day + 1;
      }
      
      await _progressCollection.doc(_userId).update({
        'lastCompletedDay': day,
        'lastCompletedAt': FieldValue.serverTimestamp(),
        'completedDays': updatedCompletedDays,
        'currentDay': nextDay,
      });
      
      // Add sticker for completed day
      await addStickerForDay(day);
      
      return true;
    } catch (e) {
      print('Error completing day: $e');
      return false;
    }
  }
  
  // Get user stickers with email
  Future<UserStickers?> getUserStickers() async {
    if (_userId == null || _userEmail == null) return null;
    
    try {
      final doc = await _stickersCollection.doc(_userId).get();
      
      if (!doc.exists) {
        // Create initial stickers if it doesn't exist
        final initialStickers = UserStickers(
          userId: _userId!,
          email: _userEmail!,
          stickers: 0,
          earnedFromDays: [],
        );
        
        await _stickersCollection.doc(_userId).set(initialStickers.toFirestore());
        return initialStickers;
      }
      
      return UserStickers.fromFirestore(doc);
    } catch (e) {
      print('Error getting user stickers: $e');
      return null;
    }
  }
  
  // Add sticker for completed day
  Future<bool> addStickerForDay(int day) async {
    if (_userId == null) return false;
    
    try {
      final stickers = await getUserStickers();
      if (stickers == null) return false;
      
      // Check if sticker already awarded for this day
      if (stickers.hasStickerForDay(day)) {
        return true; // Already has sticker
      }
      
      // Update stickers
      final updatedStickers = stickers.addStickerForDay(day);
      
      await _stickersCollection.doc(_userId).update({
        'stickers': updatedStickers.stickers,
        'earnedFromDays': updatedStickers.earnedFromDays,
      });
      
      return true;
    } catch (e) {
      print('Error adding sticker: $e');
      return false;
    }
  }
  
  // Check if user can access a specific day
  Future<bool> canAccessDay(int day) async {
    if (_userId == null) return false;
    
    try {
      final progress = await getUserProgress();
      if (progress == null) return day == 1; // Only day 1 is accessible for new users
      
      return day <= progress.currentDay;
    } catch (e) {
      print('Error checking day access: $e');
      return false;
    }
  }
  
  // Track article completion
  Future<bool> markArticleAsCompleted(String contentId) async {
    if (_userId == null) return false;
    
    try {
      final content = await _contentCollection.doc(contentId).get();
      if (!content.exists) return false;
      
      final data = content.data() as Map<String, dynamic>;
      final day = data['day'] as int;
      
      // We'll consider the day complete when both article and audio are marked as completed
      // This method only marks the article as read
      
      // Track in user's progress
      await _firestore.collection('user_profiles').doc(_userId).collection('completed_articles').doc(contentId).set({
        'contentId': contentId,
        'day': day,
        'completedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error marking article as completed: $e');
      return false;
    }
  }
  
  // Track audio completion
  Future<bool> markAudioAsCompleted(String contentId) async {
    if (_userId == null) return false;
    
    try {
      final content = await _contentCollection.doc(contentId).get();
      if (!content.exists) return false;
      
      final data = content.data() as Map<String, dynamic>;
      final day = data['day'] as int;
      
      // Track in user's progress
      await _firestore.collection('user_profiles').doc(_userId).collection('completed_audios').doc(contentId).set({
        'contentId': contentId,
        'day': day,
        'completedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error marking audio as completed: $e');
      return false;
    }
  }
  
  // Check if both article and audio are completed and complete the day if they are
  Future<bool> checkAndCompleteDayIfBothCompleted(String contentId) async {
    if (_userId == null) return false;
    
    try {
      final content = await _contentCollection.doc(contentId).get();
      if (!content.exists) return false;
      
      final data = content.data() as Map<String, dynamic>;
      final day = data['day'] as int;
      
      // Check if both article and audio are completed
      final articleCompleted = await _firestore.collection('user_profiles').doc(_userId).collection('completed_articles').doc(contentId).get();
      final audioCompleted = await _firestore.collection('user_profiles').doc(_userId).collection('completed_audios').doc(contentId).get();
      
      if (articleCompleted.exists && audioCompleted.exists) {
        // Both are completed, so complete the day
        return await completeDay(day);
      }
      
      return false; // Not both completed yet
    } catch (e) {
      print('Error checking completion: $e');
      return false;
    }
  }
  
  // Add new meditation content with explicit document ID
  Future<bool> addMeditationContentWithId({
    required int day,
    required String title,
    required ArticleContent article,
    required AudioContent audio,
    String? documentId,
  }) async {
    try {
      print('Adding new meditation content with explicit ID to Firestore...');
      final docId = documentId ?? 'Day-$day';
      print('Using document ID: $docId');
      
      // Use set with merge to update if exists or create if not
      await _contentCollection.doc(docId).set({
        'day': day,
        'title': title,
        'article': article.toMap(),
        'audio': audio.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      }, SetOptions(merge: true));
      
      print('Document set successfully with ID: $docId');
      return true;
    } catch (e) {
      print('Error adding meditation content with ID: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }
  
  // Update audio URL for meditation content
  Future<bool> updateMeditationAudioUrl({
    required String documentId,
    required String audioUrl,
  }) async {
    try {
      await _contentCollection.doc(documentId).update({
        'audio.url': audioUrl,
      });
      print('Successfully updated audio URL for document: $documentId');
      return true;
    } catch (e) {
      print('Error updating audio URL: $e');
      return false;
    }
  }
  
  // Delete meditation content
  Future<bool> deleteMeditationContent(String contentId) async {
    try {
      // Check if user is admin
      if (!await isAdmin()) {
        print('User is not authorized to delete meditation content');
        return false;
      }

      await _contentCollection.doc(contentId).delete();
      print('Successfully deleted meditation content: $contentId');
      return true;
    } catch (e) {
      print('Error deleting meditation content: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }
} 