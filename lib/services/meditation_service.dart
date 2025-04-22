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
      print('Starting completeDay process for day $day');
      
      // Get current progress
      final progress = await getUserProgress();
      if (progress == null) {
        print('ERROR: User progress is null');
        return false;
      }
      
      // Check if this day is already completed
      if (progress.completedDays.contains(day)) {
        print('Day $day is already completed, nothing to do');
        return true; // Already completed
      }
      
      print('Current progress - currentDay: ${progress.currentDay}, lastCompletedDay: ${progress.lastCompletedDay}');
      print('Completed days: ${progress.completedDays}');
      
      // Update progress
      final updatedCompletedDays = List<int>.from(progress.completedDays)..add(day);
      int nextDay = progress.currentDay;
      
      // If completing current day, increment currentDay if 24 hours have passed
      if (day == progress.currentDay && progress.canUnlockNextDay()) {
        nextDay = day + 1;
        print('Unlocking next day: $nextDay');
      } else {
        print('Next day unlocking conditions not met or completing a previous day');
      }
      
      print('Updating progress in Firestore...');
      // Update in Firestore
      await _progressCollection.doc(_userId).update({
        'lastCompletedDay': day,
        'lastCompletedAt': FieldValue.serverTimestamp(),
        'completedDays': updatedCompletedDays,
        'currentDay': nextDay,
      });
      
      print('Progress updated successfully');
      
      // Add sticker for completed day - this needs to succeed
      final stickerResult = await addStickerForDay(day);
      print('Sticker added for day $day: $stickerResult');
      
      // Double check that sticker was awarded
      final stickers = await getUserStickers();
      if (stickers != null) {
        print('Sticker verification - User has ${stickers.stickers} stickers total');
        print('Has sticker for day $day: ${stickers.hasStickerForDay(day)}');
      }
      
      return true;
    } catch (e) {
      print('Error completing day: $e');
      print('Stack trace: ${StackTrace.current}');
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
    if (_userId == null) {
      print('Cannot add sticker: userId is null');
      return false;
    }
    
    try {
      print('Adding sticker for day $day - START');
      
      final stickers = await getUserStickers();
      if (stickers == null) {
        print('Cannot add sticker: stickers is null');
        return false;
      }
      
      // Check if sticker already awarded for this day
      if (stickers.hasStickerForDay(day)) {
        print('Sticker already awarded for day $day');
        return true; // Already has sticker
      }
      
      print('Adding new sticker for day $day');
      
      // Update stickers
      final updatedStickers = stickers.addStickerForDay(day);
      
      // Use set with merge to ensure all fields are present
      await _stickersCollection.doc(_userId).set({
        'userId': _userId,
        'email': _userEmail ?? '',
        'stickers': updatedStickers.stickers,
        'earnedFromDays': updatedStickers.earnedFromDays,
        'lastUpdated': FieldValue.serverTimestamp(),
        'stickerAchievements': updatedStickers.stickerAchievements,
      }, SetOptions(merge: true));
      
      print('Sticker added successfully for day $day. Total stickers: ${updatedStickers.stickers}');
      
      // Add achievement if needed (example: first sticker, 5 stickers, etc)
      if (updatedStickers.stickers == 1) {
        await _addStickerAchievement('first_sticker', 'First Sticker Earned!');
      } else if (updatedStickers.stickers == 5) {
        await _addStickerAchievement('five_stickers', 'Five Stickers Collection!');
      } else if (updatedStickers.stickers == 10) {
        await _addStickerAchievement('ten_stickers', 'Ten Stickers Master!');
      }
      
      return true;
    } catch (e) {
      print('Error adding sticker: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }
  
  // Add sticker achievement
  Future<bool> _addStickerAchievement(String achievementId, String title) async {
    if (_userId == null) return false;
    
    try {
      print('Adding sticker achievement: $achievementId - $title');
      
      final stickers = await getUserStickers();
      if (stickers == null) return false;
      
      // Check if achievement already awarded
      final achievements = stickers.stickerAchievements;
      if (achievements.containsKey(achievementId)) {
        return true; // Already has this achievement
      }
      
      // Create updated achievements map
      final updatedAchievements = Map<String, dynamic>.from(achievements);
      updatedAchievements[achievementId] = {
        'title': title,
        'earnedAt': FieldValue.serverTimestamp(),
      };
      
      // Update stickers document
      await _stickersCollection.doc(_userId).update({
        'stickerAchievements': updatedAchievements,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      print('Achievement added successfully: $achievementId');
      return true;
    } catch (e) {
      print('Error adding achievement: $e');
      return false;
    }
  }
  
  // Get all user achievements
  Future<List<Map<String, dynamic>>> getUserAchievements() async {
    if (_userId == null) return [];
    
    try {
      final stickers = await getUserStickers();
      if (stickers == null) return [];
      
      final achievements = <Map<String, dynamic>>[];
      stickers.stickerAchievements.forEach((key, value) {
        if (value is Map) {
          achievements.add({
            'id': key,
            'title': value['title'] ?? 'Unknown Achievement',
            'earnedAt': value['earnedAt'] ?? Timestamp.now(),
          });
        }
      });
      
      // Sort by earned date (newest first)
      achievements.sort((a, b) {
        final aTimestamp = a['earnedAt'] as Timestamp;
        final bTimestamp = b['earnedAt'] as Timestamp;
        return bTimestamp.compareTo(aTimestamp);
      });
      
      return achievements;
    } catch (e) {
      print('Error getting user achievements: $e');
      return [];
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
      print('Checking if both article and audio are completed for content ID: $contentId');
      
      final content = await _contentCollection.doc(contentId).get();
      if (!content.exists) {
        print('ERROR: Content document $contentId does not exist');
        return false;
      }
      
      final data = content.data() as Map<String, dynamic>;
      final day = data['day'] as int;
      
      print('Found content for day: $day');
      
      // Check if both article and audio are completed
      final articleDocRef = _firestore.collection('user_profiles').doc(_userId).collection('completed_articles').doc(contentId);
      final audioDocRef = _firestore.collection('user_profiles').doc(_userId).collection('completed_audios').doc(contentId);
      
      final articleCompleted = await articleDocRef.get();
      final audioCompleted = await audioDocRef.get();
      
      print('Article completed: ${articleCompleted.exists}');
      print('Audio completed: ${audioCompleted.exists}');
      
      if (articleCompleted.exists && audioCompleted.exists) {
        print('Both article and audio are completed for day $day. Completing day...');
        
        // Verify if day is already completed before proceeding
        final progress = await getUserProgress();
        if (progress?.completedDays.contains(day) ?? false) {
          print('Day $day is already marked as completed in user progress');
          return true;
        }
        
        // Both are completed, so complete the day
        final result = await completeDay(day);
        print('Day $day complete result: $result');
        return result;
      } else {
        print('Not both audio and article completed yet');
        if (!articleCompleted.exists) {
          print('Article not yet completed');
        }
        if (!audioCompleted.exists) {
          print('Audio not yet completed');
        }
      }
      
      return false; // Not both completed yet
    } catch (e) {
      print('Error checking completion: $e');
      print('Stack trace: ${StackTrace.current}');
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