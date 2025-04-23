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
    if (_userId == null) return null;
    
    try {
      final doc = await _progressCollection.doc(_userId).get();
      
      if (!doc.exists) {
        // Create initial progress if it doesn't exist
        // For anonymous users, we might not have an email, so use a default one
        final email = _userEmail ?? '$_userId@anonymous.user';
        print('Creating initial progress for user: $_userId with email: $email');
        
        final initialProgress = UserProgress(
          userId: _userId!,
          email: email,
          currentDay: 1,
          lastCompletedDay: 0,
          lastCompletedAt: Timestamp.now(),
          completedDays: [],
        );
        
        try {
          await _progressCollection.doc(_userId).set(initialProgress.toFirestore());
          print('Successfully created initial progress');
          return initialProgress;
        } catch (e) {
          print('Error creating initial progress: $e');
          print('Stack trace: ${StackTrace.current}');
          // Return the object anyway so the app can continue
          return initialProgress;
        }
      }
      
      return UserProgress.fromFirestore(doc);
    } catch (e) {
      print('Error getting user progress: $e');
      print('Stack trace: ${StackTrace.current}');
      
      // Create a fallback progress object to prevent null issues
      print('Creating fallback progress object due to error');
      return UserProgress(
        userId: _userId!,
        email: _userEmail ?? '$_userId@anonymous.user',
        currentDay: 1,
        lastCompletedDay: 0,
        lastCompletedAt: Timestamp.now(),
        completedDays: [],
      );
    }
  }
  
  // Update user progress when a day is completed
  Future<bool> completeDay(int day) async {
    if (_userId == null) return false;
    
    try {
      print('Starting completeDay process for day $day');
      
      // Get or create user progress
      UserProgress progress;
      final userProgress = await getUserProgress();
      
      if (userProgress == null) {
        print('Creating new progress for user during completeDay');
        final email = _userEmail ?? '$_userId@anonymous.user';
        
        progress = UserProgress(
          userId: _userId!,
          email: email,
          currentDay: 1,
          lastCompletedDay: 0,
          lastCompletedAt: Timestamp.now(),
          completedDays: [],
        );
        
        // Try to save this new progress
        try {
          await _progressCollection.doc(_userId).set(progress.toFirestore());
          print('Created initial progress successfully');
        } catch (e) {
          print('Error saving initial progress: $e');
          // Continue with the in-memory object anyway
        }
      } else {
        progress = userProgress;
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
      
      // Calculate when the next day will unlock (24 hours from now)
      final now = Timestamp.now();
      final nextDayUnlockTime = Timestamp.fromMillisecondsSinceEpoch(
        now.millisecondsSinceEpoch + (24 * 60 * 60 * 1000) // 24 hours in milliseconds
      );
      
      print('Updating progress in Firestore...');
      print('Next day unlock time: ${nextDayUnlockTime.toDate()}');
      
      // Update in Firestore
      try {
        // First make sure the doc exists
        final docExists = (await _progressCollection.doc(_userId).get()).exists;
        if (!docExists) {
          print('Progress document doesn\'t exist in Firestore, creating it first');
          await _progressCollection.doc(_userId).set(progress.toFirestore());
        }
        
        // Now update it
        await _progressCollection.doc(_userId).update({
          'lastCompletedDay': day,
          'lastCompletedAt': now,
          'completedDays': updatedCompletedDays,
          'currentDay': nextDay,
          'timeUnlocked': nextDayUnlockTime, // When the next day will be unlocked
        });
        
        print('Progress updated successfully');
      } catch (e) {
        print('Error updating progress: $e');
        print('Trying alternative method...');
        
        // Try set with merge instead
        try {
          await _progressCollection.doc(_userId).set({
            'userId': _userId,
            'email': progress.email,
            'lastCompletedDay': day,
            'lastCompletedAt': now,
            'completedDays': updatedCompletedDays,
            'currentDay': nextDay,
            'timeUnlocked': nextDayUnlockTime, // When the next day will be unlocked
          }, SetOptions(merge: true));
          print('Progress updated using alternative method');
        } catch (e) {
          print('Even alternative method failed: $e');
          // Continue anyway to try to add the sticker
        }
      }
      
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
    if (_userId == null) return null;
    
    try {
      final doc = await _stickersCollection.doc(_userId).get();
      
      if (!doc.exists) {
        // Create initial stickers if it doesn't exist
        // For anonymous users, we might not have an email, so use a default one
        final email = _userEmail ?? '$_userId@anonymous.user';
        print('Creating initial stickers document for user: $_userId with email: $email');
        
        final initialStickers = UserStickers(
          userId: _userId!,
          email: email,
          stickers: 0,
          earnedFromDays: [],
        );
        
        try {
          await _stickersCollection.doc(_userId).set(initialStickers.toFirestore());
          print('Successfully created initial stickers document');
          return initialStickers;
        } catch (e) {
          print('Error creating initial stickers document: $e');
          print('Stack trace: ${StackTrace.current}');
          // Return the object anyway so the app can continue
          return initialStickers;
        }
      }
      
      return UserStickers.fromFirestore(doc);
    } catch (e) {
      print('Error getting user stickers: $e');
      // Create a fallback stickers object to prevent null issues
      print('Creating fallback stickers object due to error');
      return UserStickers(
        userId: _userId!,
        email: _userEmail ?? '$_userId@anonymous.user',
        stickers: 0,
        earnedFromDays: [],
      );
    }
  }
  
  // Add sticker for completed day
  Future<bool> addStickerForDay(int day) async {
    if (_userId == null) {
      print('Cannot add sticker: userId is null');
      return false;
    }
    
    // Use a default email for anonymous users
    final email = _userEmail ?? '$_userId@anonymous.user';
    print('Adding sticker for day $day - START');
    print('User ID: $_userId, Email: $email');
    
    try {
      // Get or create user stickers
      UserStickers stickers;
      final userStickers = await getUserStickers();
      
      if (userStickers == null) {
        print('Cannot add sticker: stickers is null - creating new stickers document');
        stickers = UserStickers(
          userId: _userId!,
          email: email,
          stickers: 0,
          earnedFromDays: [],
        );
        
        // Try to save the new stickers document
        try {
          await _stickersCollection.doc(_userId).set(stickers.toFirestore());
          print('Created new stickers document successfully');
        } catch (e) {
          print('Failed to create initial stickers document: $e');
          print('Will try to continue with in-memory object');
        }
      } else {
        stickers = userStickers;
      }
      
      // Check if sticker already awarded for this day
      if (stickers.hasStickerForDay(day)) {
        print('Sticker already awarded for day $day');
        return true; // Already has sticker
      }
      
      print('Adding new sticker for day $day');
      
      // Update stickers
      final updatedStickers = stickers.addStickerForDay(day);
      
      print('Updated stickers object in memory:');
      print('- Total stickers: ${updatedStickers.stickers}');
      print('- Earned from days: ${updatedStickers.earnedFromDays}');
      
      // Use set with merge to ensure all fields are present
      try {
        // First make sure the document exists
        final docExists = (await _stickersCollection.doc(_userId).get()).exists;
        
        if (!docExists) {
          print('Stickers document doesn\'t exist yet, creating it first');
          await _stickersCollection.doc(_userId).set({
            'userId': _userId,
            'email': email,
            'stickers': 0,
            'earnedFromDays': [],
            'stickerAchievements': {},
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        
        // Now update with the new sticker
        await _stickersCollection.doc(_userId).set({
          'userId': _userId,
          'email': email,
          'stickers': updatedStickers.stickers,
          'earnedFromDays': updatedStickers.earnedFromDays,
          'lastUpdated': FieldValue.serverTimestamp(),
          'stickerAchievements': updatedStickers.stickerAchievements,
        }, SetOptions(merge: true));
        
        print('Sticker added successfully for day $day. Total stickers: ${updatedStickers.stickers}');
        
        // Verify the sticker was actually saved
        final verifyStickers = await getUserStickers();
        if (verifyStickers != null) {
          final stickerVerified = verifyStickers.hasStickerForDay(day);
          print('Verification - Sticker for day $day exists: $stickerVerified');
          print('Verification - Total stickers: ${verifyStickers.stickers}');
          
          if (!stickerVerified) {
            print('WARNING: Sticker verification failed - trying direct update method');
            // Try direct update instead of set with merge
            await _stickersCollection.doc(_userId).update({
              'stickers': FieldValue.increment(1),
              'earnedFromDays': FieldValue.arrayUnion([day]),
              'lastUpdated': FieldValue.serverTimestamp(),
            });
            
            // Verify again
            final finalCheck = await getUserStickers();
            if (finalCheck != null) {
              print('Final verification - Sticker for day $day exists: ${finalCheck.hasStickerForDay(day)}');
              
              // If still failing, try one more approach with a completely new document
              if (!finalCheck.hasStickerForDay(day)) {
                print('WARNING: Both methods failed. Trying to recreate stickers document');
                
                // Create a complete new document with the sticker included
                final newStickers = UserStickers(
                  userId: _userId!,
                  email: email,
                  stickers: 1,
                  earnedFromDays: [day],
                );
                
                await _stickersCollection.doc(_userId).set(newStickers.toFirestore());
                print('Complete document recreation attempted');
              }
            }
          }
        }
        
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
        print('Error saving sticker to Firestore: $e');
        print('Stack trace: ${StackTrace.current}');
        
        // Try one final desperate approach - recreate the entire document
        try {
          print('Last resort - recreating entire stickers document with the new sticker');
          final lastResortStickers = UserStickers(
            userId: _userId!,
            email: email,
            stickers: 1,
            earnedFromDays: [day],
          );
          
          await _stickersCollection.doc(_userId).set(lastResortStickers.toFirestore());
          print('Last resort approach completed');
          return true;
        } catch (e) {
          print('Even last resort failed: $e');
          return false;
        }
      }
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
    if (_userId == null) {
      print('Cannot check completion: userId is null');
      return false;
    }
    
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
        print('Both article and audio are completed for day $day. Checking if day already completed...');
        
        // Force create user progress if it doesn't exist
        UserProgress progress;
        try {
          // Get or create progress
          final userProgress = await getUserProgress();
          if (userProgress == null) {
            print('Creating emergency progress data for user');
            // This is an emergency fallback - create progress directly
            final email = _userEmail ?? '$_userId@anonymous.user';
            progress = UserProgress(
              userId: _userId!,
              email: email,
              currentDay: 1,
              lastCompletedDay: 0,
              lastCompletedAt: Timestamp.now(),
              completedDays: [],
            );
            
            // Try to save this progress
            await _progressCollection.doc(_userId).set(progress.toFirestore());
          } else {
            progress = userProgress;
          }
        } catch (e) {
          print('Error getting/creating progress: $e');
          // Continue with a new progress object
          final email = _userEmail ?? '$_userId@anonymous.user';
          progress = UserProgress(
            userId: _userId!,
            email: email,
            currentDay: 1,
            lastCompletedDay: 0,
            lastCompletedAt: Timestamp.now(),
            completedDays: [],
          );
        }
        
        // Now check if day is already completed using our progress object
        if (progress.completedDays.contains(day)) {
          print('Day $day is already marked as completed in user progress');
          
          // Check if sticker exists anyway
          final stickers = await getUserStickers();
          if (stickers != null && !stickers.hasStickerForDay(day)) {
            print('Day completed but sticker missing - adding sticker for day $day');
            await addStickerForDay(day);
            return true;
          }
          
          return true;
        }
        
        print('Day $day needs to be completed. Proceeding with completion...');
        
        // Both are completed, so complete the day
        final result = await completeDay(day);
        print('Day $day complete result: $result');
        
        if (!result) {
          print('ERROR: Failed to complete day $day. Trying again...');
          // Try one more time after a small delay
          await Future.delayed(const Duration(milliseconds: 500));
          final retryResult = await completeDay(day);
          print('Day $day completion retry result: $retryResult');
          return retryResult;
        }
        
        return result;
      } else {
        print('Not both article and audio are completed, cannot complete day');
        print('Article completed: ${articleCompleted.exists}');
        print('Audio completed: ${audioCompleted.exists}');
        return false;
      }
    } catch (e) {
      print('Error checking day completion: $e');
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
  
  // Get time remaining until next day unlock in seconds
  Future<int> getSecondsUntilNextDayUnlocks() async {
    final progress = await getUserProgress();
    if (progress == null) return 0;
    
    return progress.getSecondsUntilNextDayUnlocks();
  }
  
  // Get formatted time remaining until next day unlocks
  Future<String> getFormattedTimeRemaining() async {
    final progress = await getUserProgress();
    if (progress == null) return "00h 00m 00s";
    
    return progress.getFormattedTimeRemaining();
  }
  
  // Check if the next day can be unlocked
  Future<bool> canUnlockNextDay() async {
    final progress = await getUserProgress();
    if (progress == null) return true; // First day is always unlocked
    
    return progress.canUnlockNextDay();
  }
  
  // Get next day unlock timestamp
  Future<Timestamp> getNextDayUnlockTime() async {
    final progress = await getUserProgress();
    if (progress == null) return Timestamp.now();
    
    print('Getting next day unlock time...');
    print('Last completed at: ${progress.lastCompletedAt.toDate()}');
    
    // Calculate when the next unlock will happen (24 hours after last completed)
    final lastCompletedAt = progress.lastCompletedAt;
    final unlockTime = Timestamp.fromMillisecondsSinceEpoch(
      lastCompletedAt.millisecondsSinceEpoch + (24 * 60 * 60 * 1000)
    );
    
    print('Calculated next unlock time: ${unlockTime.toDate()}');
    
    // Check if there's already an unlock time saved in the document
    try {
      final docRef = _progressCollection.doc(_userId);
      final doc = await docRef.get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Check if we have a saved next unlock time
        if (data.containsKey('timeUnlocked') && data['timeUnlocked'] is Timestamp) {
          final savedTime = data['timeUnlocked'] as Timestamp;
          print('Found saved unlock time: ${savedTime.toDate()}');
          
          // Compare and return the later of the two times
          if (savedTime.millisecondsSinceEpoch > unlockTime.millisecondsSinceEpoch) {
            print('Using saved unlock time as it is later');
            return savedTime;
          }
        }
      }
    } catch (e) {
      print('Error retrieving saved unlock time: $e');
      // Continue with calculated time
    }
    
    return unlockTime;
  }
  
  // Update the current day if the timer has expired
  Future<bool> updateCurrentDayIfTimerExpired() async {
    try {
      if (_userId == null) {
        print('Cannot update: userId is null');
        return false;
      }
      
      print('Checking if timer has expired to update current day...');
      final progress = await getUserProgress();
      if (progress == null) {
        print('No progress data found');
        return false;
      }
      
      print('Current progress - currentDay: ${progress.currentDay}, lastCompletedDay: ${progress.lastCompletedDay}');
      
      // If 24 hours have passed since last completion and we can unlock the next day
      if (progress.canUnlockNextDay() && progress.currentDay <= progress.lastCompletedDay) {
        // Update current day
        final nextDay = progress.lastCompletedDay + 1;
        print('Timer expired, unlocking day $nextDay');
        
        // Get current server time
        final serverTimestamp = FieldValue.serverTimestamp();
        
        await _progressCollection.doc(_userId).update({
          'currentDay': nextDay,
          'timeUnlocked': serverTimestamp,
          'lastUpdated': serverTimestamp
        });
        
        print('Current day updated to $nextDay');
        return true;
      } else {
        print('Timer not expired or current day already ahead of last completed day');
        print('canUnlockNextDay: ${progress.canUnlockNextDay()}');
        print('Time since last completion (hours): ${progress.hoursSinceLastCompletion()}');
        return false;
      }
    } catch (e) {
      print('Error updating current day after timer expiry: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }
  
  // Fix any issues with the unlock time field
  Future<bool> fixUnlockTimeField() async {
    try {
      if (_userId == null) {
        print('Cannot fix unlock time: userId is null');
        return false;
      }
      
      final docRef = _progressCollection.doc(_userId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        print('No progress document to fix');
        return false;
      }
      
      final data = doc.data() as Map<String, dynamic>;
      
      // Check if there's an issue with the field
      if (data.containsKey('new-unlock-time') && !(data['new-unlock-time'] is Timestamp)) {
        print('Found invalid new-unlock-time field: ${data['new-unlock-time']}');
        
        // Calculate proper next unlock time
        final lastCompletedAt = data['lastCompletedAt'] as Timestamp;
        final unlockTime = Timestamp.fromMillisecondsSinceEpoch(
          lastCompletedAt.millisecondsSinceEpoch + (24 * 60 * 60 * 1000)
        );
        
        print('Calculated proper unlock time: ${unlockTime.toDate()}');
        
        // Update document with proper timeUnlocked field and remove the incorrect field
        final updateData = {
          'timeUnlocked': unlockTime,
          'new-unlock-time': FieldValue.delete(),
        };
        
        await docRef.update(updateData);
        print('Fixed unlock time field');
        return true;
      } else {
        print('No issues found with unlock time field');
        return false;
      }
    } catch (e) {
      print('Error fixing unlock time field: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }
} 