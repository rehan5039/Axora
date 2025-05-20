import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:axora/models/meditation_content.dart';
import 'package:axora/models/user_progress.dart';
import 'package:axora/models/user_flow.dart';
import 'package:axora/services/stats_service.dart';
import 'package:axora/models/custom_meditation.dart';

class MeditationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get current user ID and email
  String? get _userId => _auth.currentUser?.uid;
  String? get _userEmail => _auth.currentUser?.email;
  
  // Collection references
  CollectionReference get _contentCollection => _firestore.collection('meditation_content');
  CollectionReference get _progressCollection => _firestore.collection('meditation_progress');
  CollectionReference get _flowCollection => _firestore.collection('meditation_flow');
  CollectionReference get _adminsCollection => _firestore.collection('admins');
  CollectionReference get _customMeditationCollection => _firestore.collection('custom_meditation');
  
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
  Future<List<MeditationContent>> getAllMeditationContent({bool forAdmin = false}) async {
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
      var meditationContents = querySnapshot.docs
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
      
      // Filter out inactive content when not in admin mode
      if (!forAdmin) {
        meditationContents = meditationContents.where((content) => content.isActive).toList();
        print('Filtered to ${meditationContents.length} active meditation content documents');
      } else {
        print('Admin mode: showing all content including inactive');
      }
      
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
    bool isActive = true,
    List<Map<String, dynamic>> articlePages = const [],
  }) async {
    try {
      // Check if user is admin
      if (!await isAdmin()) {
        print('User is not authorized to add meditation content');
        return false;
      }

      print('Adding new meditation content to Firestore...');
      print('Collection path: ${_contentCollection.path}');
      
      // Create a consistent document ID format: "Day-X"
      final docId = 'Day-$day';
      print('Using document ID: $docId');
      
      // Use set instead of add to specify the document ID
      await _contentCollection.doc(docId).set({
        'day': day,
        'title': title,
        'article': article.toMap(),
        'audio': audio.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _userEmail,
        'isActive': isActive,
        'articlePages': articlePages,
      });
      
      print('Document added successfully with ID: $docId');
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
      
      // Check if user has already completed a day today (if completing a new day)
      if (day > progress.lastCompletedDay && progress.lastCompletedDay > 0) {
        // Check if user can complete a new day today based on client date
        final canCompleteToday = await canCompleteNewDayToday();
        if (!canCompleteToday) {
          print('User has already completed a day today, cannot complete another day');
          return false;
        }
      }
      
      print('Current progress - currentDay: ${progress.currentDay}, lastCompletedDay: ${progress.lastCompletedDay}');
      print('Completed days: ${progress.completedDays}');
      
      // Update progress
      final updatedCompletedDays = List<int>.from(progress.completedDays)..add(day);
      int nextDay = progress.currentDay;
      
      // If completing current day, increment currentDay
      if (day == progress.currentDay) {
        nextDay = day + 1;
        print('Unlocking next day: $nextDay');
      } else {
        print('Completing a previous day');
      }
      
      // Calculate when the next day will unlock (24 hours from now - keeping this for backward compatibility)
      final now = Timestamp.now();
      
      print('Updating progress in Firestore...');
      
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
          }, SetOptions(merge: true));
          print('Progress updated using alternative method');
        } catch (e) {
          print('Even alternative method failed: $e');
          // Continue anyway to try to add the flow
        }
      }
      
      // Add flow for completed day - this needs to succeed
      final flowResult = await addFlowForDay(day);
      print('Flow added for day $day: $flowResult');
      
      // Double check that flow was awarded
      final flow = await getUserFlow();
      if (flow != null) {
        print('Flow verification - User has ${flow.flow} flow total');
        print('Has flow for day $day: ${flow.hasFlowForDay(day)}');
      }
      
      return true;
    } catch (e) {
      print('Error completing day: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }
  
  // Get user flow with email
  Future<UserFlow?> getUserFlow() async {
    if (_userId == null) return null;
    
    try {
      final doc = await _flowCollection.doc(_userId).get();
      
      if (!doc.exists) {
        // Create initial flow if it doesn't exist
        // For anonymous users, we might not have an email, so use a default one
        final email = _userEmail ?? '$_userId@anonymous.user';
        print('Creating initial flow document for user: $_userId with email: $email');
        
        final initialFlow = UserFlow(
          userId: _userId!,
          email: email,
          flow: 0,
          earnedFromDays: [],
          lastMeditationDate: DateTime.now(),
        );
        
        try {
          await _flowCollection.doc(_userId).set(initialFlow.toFirestore());
          print('Successfully created initial flow document');
          return initialFlow;
        } catch (e) {
          print('Error creating initial flow document: $e');
          print('Stack trace: ${StackTrace.current}');
          // Return the object anyway so the app can continue
          return initialFlow;
        }
      }
      
      return UserFlow.fromFirestore(doc);
    } catch (e) {
      print('Error getting user flow: $e');
      // Create a fallback flow object to prevent null issues
      print('Creating fallback flow object due to error');
      return UserFlow(
        userId: _userId!,
        email: _userEmail ?? '$_userId@anonymous.user',
        flow: 0,
        earnedFromDays: [],
        lastMeditationDate: DateTime.now(),
      );
    }
  }
  
  // Add flow for completed day
  Future<bool> addFlowForDay(int day) async {
    if (_userId == null) {
      print('Cannot add flow: userId is null');
      return false;
    }
    
    // Use a default email for anonymous users
    final email = _userEmail ?? '$_userId@anonymous.user';
    print('Adding flow for day $day - START');
    print('User ID: $_userId, Email: $email');
    
    try {
      // Check if user already earned flow today
      final earnedToday = await _hasEarnedFlowToday();
      
      if (earnedToday) {
        print('User has already earned flow today, cannot earn more flow for day $day');
        
        // Update the lastMeditationDate to today even though no flow is added
        await _flowCollection.doc(_userId).update({
          'lastMeditationDate': Timestamp.now(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        
        return true; // Consider it successful but no flow added
      }
      
      // Get or create user flow
      UserFlow flow;
      final userFlow = await getUserFlow();
      
      if (userFlow == null) {
        print('Cannot add flow: flow is null - creating new flow document');
        flow = UserFlow(
          userId: _userId!,
          email: email,
          flow: 0,
          earnedFromDays: [],
          lastMeditationDate: DateTime.now(),
        );
        
        // Try to save the new flow document
        try {
          await _flowCollection.doc(_userId).set(flow.toFirestore());
          print('Created new flow document successfully');
        } catch (e) {
          print('Failed to create initial flow document: $e');
          print('Will try to continue with in-memory object');
        }
      } else {
        flow = userFlow;
      }
      
      // Check if flow already awarded for this day
      if (flow.hasFlowForDay(day)) {
        print('Flow already awarded for day $day');
        
        // Even if flow was already awarded, update the lastMeditationDate to today
        // This is important for the flow reduction system
        await _flowCollection.doc(_userId).update({
          'lastMeditationDate': Timestamp.now(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        
        return true; // Already has flow
      }
      
      print('Adding new flow for day $day');
      
      // Update flow
      final updatedFlow = flow.addFlowForDay(day);
      
      print('Updated flow object in memory:');
      print('- Total flow: ${updatedFlow.flow}');
      print('- Earned from days: ${updatedFlow.earnedFromDays}');
      
      // Use set with merge to ensure all fields are present
      try {
        // First make sure the document exists
        final docExists = (await _flowCollection.doc(_userId).get()).exists;
        
        if (!docExists) {
          print('Flow document doesn\'t exist yet, creating it first');
          await _flowCollection.doc(_userId).set({
            'userId': _userId,
            'email': email,
            'flow': 0,
            'earnedFromDays': [],
            'flowAchievements': {},
            'lastMeditationDate': Timestamp.now(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        
        // Now update with the new flow and mark that flow was earned today
        await _flowCollection.doc(_userId).set({
          'userId': _userId,
          'email': email,
          'flow': updatedFlow.flow,
          'earnedFromDays': updatedFlow.earnedFromDays,
          'lastMeditationDate': Timestamp.now(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'flowAchievements': updatedFlow.flowAchievements,
          'earnedFlowToday': true, // Mark that flow was earned today
        }, SetOptions(merge: true));
        
        print('Flow added successfully for day $day. Total flow: ${updatedFlow.flow}');
        
        // Verify the flow was actually saved
        final verifyFlow = await getUserFlow();
        if (verifyFlow != null) {
          final flowVerified = verifyFlow.hasFlowForDay(day);
          print('Verification - Flow for day $day exists: $flowVerified');
          print('Verification - Total flow: ${verifyFlow.flow}');
          
          if (!flowVerified) {
            print('WARNING: Flow verification failed - trying direct update method');
            // Try direct update instead of set with merge
            await _flowCollection.doc(_userId).update({
              'flow': FieldValue.increment(1),
              'earnedFromDays': FieldValue.arrayUnion([day]),
              'lastMeditationDate': Timestamp.now(),
              'lastUpdated': FieldValue.serverTimestamp(),
              'earnedFlowToday': true,
            });
            
            // Verify again
            final finalCheck = await getUserFlow();
            if (finalCheck != null) {
              print('Final verification - Flow for day $day exists: ${finalCheck.hasFlowForDay(day)}');
              
              // If still failing, try one more approach with a completely new document
              if (!finalCheck.hasFlowForDay(day)) {
                print('WARNING: Both methods failed. Trying to recreate flow document');
                
                // Create a complete new document with the flow included
                final newFlow = UserFlow(
                  userId: _userId!,
                  email: email,
                  flow: 1,
                  earnedFromDays: [day],
                  lastMeditationDate: DateTime.now(),
                  earnedFlowToday: true,
                );
                
                await _flowCollection.doc(_userId).set(newFlow.toFirestore());
                print('Complete document recreation attempted');
              }
            }
          }
        }
        
        // Add achievement if needed (example: first flow, 5 flow, etc)
        if (updatedFlow.flow == 1) {
          await _addFlowAchievement('first_flow', 'First Flow Earned!');
        } else if (updatedFlow.flow == 5) {
          await _addFlowAchievement('five_flow', 'Five Flow Collection!');
        } else if (updatedFlow.flow == 10) {
          await _addFlowAchievement('ten_flow', 'Ten Flow Master!');
        }
        
        return true;
      } catch (e) {
        print('Error saving flow to Firestore: $e');
        print('Stack trace: ${StackTrace.current}');
        
        // Try one final desperate approach - recreate the entire document
        try {
          print('Last resort - recreating entire flow document with the new flow');
          final lastResortFlow = UserFlow(
            userId: _userId!,
            email: email,
            flow: 1,
            earnedFromDays: [day],
            lastMeditationDate: DateTime.now(),
            earnedFlowToday: true,
          );
          
          await _flowCollection.doc(_userId).set(lastResortFlow.toFirestore());
          print('Last resort document recreation completed');
          return true;
        } catch (finalError) {
          print('Final attempt failed: $finalError');
          return false;
        }
      }
    } catch (e) {
      print('Error adding flow for day $day: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }
  
  // Private helper method to add flow achievements
  Future<void> _addFlowAchievement(String achievementId, String title) async {
    if (_userId == null) return;
    
    try {
      // Check if user already has this achievement
      final userFlow = await getUserFlow();
      if (userFlow == null) return;
      
      final achievements = userFlow.flowAchievements;
      if (achievements.containsKey(achievementId)) {
        print('User already has achievement: $achievementId');
        return;
      }
      
      // Add the achievement
      print('Adding flow achievement: $achievementId - $title');
      await _flowCollection.doc(_userId).update({
        'flowAchievements.$achievementId': {
          'title': title,
          'earnedAt': FieldValue.serverTimestamp(),
        }
      });
      
      print('Successfully added flow achievement: $achievementId');
    } catch (e) {
      print('Error adding flow achievement: $e');
    }
  }
  
  // For admin: Get all user flow
  Future<List<UserFlow>> getAllUserFlow() async {
    try {
      // Only admins can get all user flow
      if (!await isAdmin()) return [];
      
      final querySnapshot = await _flowCollection.get();
      return querySnapshot.docs
          .map((doc) => UserFlow.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting all user flow: $e');
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
          
          // Check if flow exists anyway
          final flow = await getUserFlow();
          if (flow != null && !flow.hasFlowForDay(day)) {
            print('Day completed but flow missing - adding flow for day $day');
            await addFlowForDay(day);
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
    bool isActive = true,
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
        'isActive': isActive,
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
    
    // Check if the timer has expired and the next day could be unlocked
    final timeExpired = progress.canUnlockNextDay();
    if (timeExpired) {
      print('Timer has expired - can unlock next day');
      
      // Automatically try to update the current day field right here
      if (progress.currentDay <= progress.lastCompletedDay) {
        final nextDay = progress.lastCompletedDay + 1;
        try {
          print('Auto-updating currentDay to $nextDay');
          await _progressCollection.doc(_userId).update({
            'currentDay': nextDay,
            'lastUpdated': FieldValue.serverTimestamp()
          });
          print('Current day auto-updated to $nextDay');
        } catch (e) {
          print('Error auto-updating current day: $e');
        }
      }
    }
    
    return timeExpired;
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
  
  // Update the current day if needed (formerly time-based)
  Future<bool> updateCurrentDayIfTimerExpired() async {
    try {
      if (_userId == null) {
        print('Cannot update: userId is null');
        return false;
      }
      
      print('Checking for day unlocks...');
      final progress = await getUserProgress();
      final flow = await getUserFlow();
      
      if (progress == null) {
        print('No progress data found');
        return false;
      }
      
      print('Current progress - currentDay: ${progress.currentDay}, lastCompletedDay: ${progress.lastCompletedDay}');
      print('User has ${flow?.flow ?? 0} total flow (${flow?.journeyFlow ?? 0} journey flow, ${flow?.customFlow ?? 0} custom flow)');
      
      // Check if we should unlock based on flow (now we'll only count journey flow)
      if (flow != null && flow.earnedFromDays.isNotEmpty) {
        // Use the journeyFlow getter to get only flow from meditation journey
        final journeyFlowCount = flow.journeyFlow;
        
        if (journeyFlowCount > 0 && progress.currentDay < journeyFlowCount + 1) {
          final nextDay = journeyFlowCount + 1;
          print('Unlocking day $nextDay based on journey flow count ($journeyFlowCount)');
          
          // Get current server time
          final serverTimestamp = FieldValue.serverTimestamp();
          
          // Update progress with fixes - set both currentDay and lastCompletedDay if needed
          Map<String, dynamic> updates = {
            'currentDay': nextDay,
            'lastUpdated': serverTimestamp
          };
          
          // Fix lastCompletedDay if it's inconsistent with journey flow
          if (progress.lastCompletedDay < journeyFlowCount) {
            updates['lastCompletedDay'] = journeyFlowCount;
            print('Fixing lastCompletedDay to match journey flow count: $journeyFlowCount');
          }
          
          await _progressCollection.doc(_userId).update(updates);
          print('Current day updated to $nextDay based on journey flow');
          return true;
        }
      }
      
      // Always unlock the next day if lastCompletedDay > 0
      final nextDay = progress.lastCompletedDay + 1;
      if (progress.lastCompletedDay > 0 && progress.currentDay < nextDay) {
        print('Unlocking day $nextDay');
        
        // Get current server time
        final serverTimestamp = FieldValue.serverTimestamp();
        
        // Update the user's progress with the new current day
        await _progressCollection.doc(_userId).update({
          'currentDay': nextDay,
          'lastUpdated': serverTimestamp
        });
        
        print('Current day updated to $nextDay');
        return true;
      }
      
      print('No days to unlock at this time');
      return false;
    } catch (e) {
      print('Error updating current day: $e');
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
  
  // Force unlock a specific day if it should be available
  Future<bool> forceUnlockDay(int day) async {
    try {
      if (_userId == null) {
        print('Cannot force unlock: userId is null');
        return false;
      }
      
      print('Force unlocking day $day');
      final progress = await getUserProgress();
      final flow = await getUserFlow();
      
      if (progress == null) {
        print('No progress data found');
        return false;
      }
      
      // Relaxed logic to make unlocking more reliable
      bool canUnlock = true; // Default to allowing unlock
      
      // Basic validation - only unlock next day or a day user should have access to
      if (day > progress.currentDay + 1) {
        // Don't allow unlocking more than one day ahead
        canUnlock = false;
        print('Cannot unlock day $day - it is more than one day ahead of current day ${progress.currentDay}');
      } else if (day <= progress.lastCompletedDay) {
        // Don't need to unlock days that are already completed
        print('Day $day is already completed, no need to unlock');
        return true;
      }
      
      if (!canUnlock) {
        print('Cannot force unlock day $day - validation failed');
        return false;
      }
      
      // Force the current day to be the requested day
      final serverTimestamp = FieldValue.serverTimestamp();
      
      // Update both the currentDay and lastCompletedDay if needed
      Map<String, dynamic> updates = {
        'currentDay': day,
        'timeUnlocked': serverTimestamp,
        'lastUpdated': serverTimestamp
      };
      
      // If day is exactly lastCompletedDay + 1, update lastCompletedDay to day-1 to ensure proper sequence
      if (day == progress.lastCompletedDay + 1 && day > 1 && !progress.completedDays.contains(day - 1)) {
        updates['completedDays'] = FieldValue.arrayUnion([day - 1]);
        print('Adding day ${day - 1} to completedDays array for proper sequence');
      }
      
      await _progressCollection.doc(_userId).update(updates);
      
      print('Successfully force unlocked day $day');
      return true;
    } catch (e) {
      print('Error force unlocking day: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Create fallback content for day 1 (for testing/debugging)
  Future<void> _createFallbackContent() async {
    try {
      await addMeditationContent(
        day: 1,
        title: 'Welcome to Meditation',
        article: ArticleContent(
          title: 'Getting Started with Meditation',
          content: 'This is a fallback content created because no content was found in the database. '
                  'Please contact the administrator to add proper meditation content. '
                  'In the meantime, you can use this simple meditation to get started. '
                  'Find a comfortable position, close your eyes, and focus on your breath for a few minutes.',
          buttonText: 'Mark as Read',
        ),
        audio: AudioContent(
          title: 'Simple Breathing Meditation',
          url: 'https://sample-videos.com/audio/mp3/crowd-cheering.mp3', // Sample public audio URL
          durationInSeconds: 120,
          audioScript: 'This is a simple breathing meditation. Breathe in... Breathe out...',
        ),
      );
    } catch (e) {
      print('Error creating fallback content: $e');
    }
  }

  // Method for completion verification
  Future<bool> verifyDayCompletion(int day) async {
    try {
      // Check if user has the flow for this day
      final flow = await getUserFlow();
      if (flow != null) {
        print('Flow verification - User has ${flow.flow} flow total');
        print('Has flow for day $day: ${flow.hasFlowForDay(day)}');
      }
      
      return true;
    } catch (e) {
      print('Error completing day: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Check if user can complete a new day today based on client-side date
  Future<bool> canCompleteNewDayToday() async {
    if (_userId == null) return false;
    
    try {
      // Get the user's progress
      final progress = await getUserProgress();
      if (progress == null) return true; // First day is always allowed
      
      // If user hasn't completed any day yet, always allow the first completion
      if (progress.lastCompletedDay == 0) return true;
      
      // Get the current client-side date (without time)
      final currentDate = DateTime.now();
      final today = DateTime(currentDate.year, currentDate.month, currentDate.day);
      
      // Get the last completion date from Firestore (stored as timestamp)
      final lastCompletionTimestamp = progress.lastCompletedAt;
      final lastCompletionDate = DateTime(
        lastCompletionTimestamp.toDate().year,
        lastCompletionTimestamp.toDate().month,
        lastCompletionTimestamp.toDate().day
      );
      
      // Check if the last completion was on a different day
      // If it's a different day, allow new completion
      return today.isAfter(lastCompletionDate);
    } catch (e) {
      print('Error checking if user can complete new day: $e');
      return false;
    }
  }

  // Get unlock time settings for the user
  Future<dynamic> getUnlockTimeSettings() async {
    // Since we removed time restrictions, return null
    return null;
  }

  // Save unlock time settings for the user
  Future<bool> saveUnlockTimeSettings(dynamic timeSettings) async {
    // Since we removed time restrictions, just return success
    return true;
  }

  // Check if user missed a day of meditation and reduce flow if needed
  Future<bool> checkAndReduceFlowIfDayMissed() async {
    if (_userId == null) return false;
    
    try {
      print('Checking if flow should be reduced due to missed meditation day...');
      
      // Get the user's flow
      final userFlow = await getUserFlow();
      if (userFlow == null || userFlow.flow <= 0) {
        print('User has no flow to reduce');
        return false;
      }
      
      // Reset the earnedFlowToday flag at the beginning of each new day
      final flowDoc = await _flowCollection.doc(_userId).get();
      if (flowDoc.exists) {
        final data = flowDoc.data() as Map<String, dynamic>;
        if (data.containsKey('earnedFlowToday') && data['earnedFlowToday'] == true) {
          // Get today's date (without time)
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          // Get the last meditation date (without time)
          final lastMeditationTimestamp = data['lastMeditationDate'] as Timestamp?;
          if (lastMeditationTimestamp != null) {
            final lastMeditationDate = lastMeditationTimestamp.toDate();
            final lastMeditationDay = DateTime(
              lastMeditationDate.year,
              lastMeditationDate.month,
              lastMeditationDate.day
            );
            
            // If the lastMeditationDate is not today, reset earnedFlowToday
            if (!lastMeditationDay.isAtSameMomentAs(today)) {
              print('Resetting earnedFlowToday flag for a new day');
              await _flowCollection.doc(_userId).update({
                'earnedFlowToday': false,
              });
            }
          }
        }
      }
      
      // If there's no last meditation date, we can't determine if a day was missed
      if (userFlow.lastMeditationDate == null) {
        print('No last meditation date found, cannot determine if day was missed');
        
        // Update the lastMeditationDate to today to start tracking
        await _flowCollection.doc(_userId).update({
          'lastMeditationDate': Timestamp.now(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        
        print('Updated lastMeditationDate to now to begin tracking');
        return false;
      }
      
      // Get today's date (without time)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Get yesterday's date (for comparison)
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      
      // Get the last meditation date (without time)
      final lastMeditation = userFlow.lastMeditationDate!;
      final lastMeditationDay = DateTime(
        lastMeditation.year,
        lastMeditation.month,
        lastMeditation.day
      );
      
      print('Today: $today');
      print('Yesterday: $yesterday');
      print('Last meditation day: $lastMeditationDay');
      
      // Check if the last meditation was yesterday or earlier
      if (lastMeditationDay.isBefore(yesterday)) {
        // The user missed at least one day of meditation
        // Calculate how many days were missed
        final difference = today.difference(lastMeditationDay).inDays;
        
        // Cap the reduction to 1 per day check
        final reductionAmount = 1;
        
        print('User missed $difference days of meditation, reducing flow by $reductionAmount');
        
        // Reduce the flow
        final updatedFlow = userFlow.reduceFlow();
        
        // Update in Firestore - IMPORTANT: also update lastMeditationDate to today
        // This prevents multiple reductions for the same missed day
        await _flowCollection.doc(_userId).update({
          'flow': updatedFlow.flow,
          'lastMeditationDate': Timestamp.now(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'totalFlowLost': updatedFlow.totalFlowLost,
        });
        
        // Update the stats service with the total flow lost
        final statsService = StatsService();
        await statsService.updateTotalFlowLost(updatedFlow.totalFlowLost);
        
        // Also sync the current streak with the new flow value
        await statsService.syncCurrentStreakWithFlow(updatedFlow.flow);
        
        print('Flow reduced from ${userFlow.flow} to ${updatedFlow.flow}');
        print('Updated lastMeditationDate to prevent multiple reductions');
        print('Total flow lost: ${updatedFlow.totalFlowLost}');
        print('Current streak synced with flow value: ${updatedFlow.flow}');
        return true;
      } else if (lastMeditationDay.isAtSameMomentAs(yesterday)) {
        print('Last meditation was yesterday, no reduction needed yet');
        return false;
      } else if (lastMeditationDay.isAtSameMomentAs(today)) {
        print('User already meditated today, no reduction needed');
        return false; 
      } else {
        print('Unusual date comparison result - for safety, no flow reduction');
        print('User did not miss a meditation day, no flow reduction needed');
        return false;
      }
    } catch (e) {
      print('Error checking and reducing flow: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // For testing: Force reduce flow regardless of lastMeditationDate
  Future<bool> manuallyReduceFlowForTesting() async {
    if (_userId == null) return false;
    
    try {
      print('Manually reducing flow for testing...');
      
      // Get the user's flow
      final userFlow = await getUserFlow();
      if (userFlow == null || userFlow.flow <= 0) {
        print('User has no flow to reduce');
        return false;
      }
      
      // Reduce the flow
      final updatedFlow = userFlow.reduceFlow();
      
      // Update in Firestore - also update lastMeditationDate
      await _flowCollection.doc(_userId).update({
        'flow': updatedFlow.flow,
        'lastMeditationDate': Timestamp.now(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'totalFlowLost': updatedFlow.totalFlowLost,
      });
      
      // Update the stats service with the total flow lost
      final statsService = StatsService();
      await statsService.updateTotalFlowLost(updatedFlow.totalFlowLost);
      
      // Also sync the current streak with the new flow value
      await statsService.syncCurrentStreakWithFlow(updatedFlow.flow);
      
      print('Flow manually reduced from ${userFlow.flow} to ${updatedFlow.flow}');
      print('Updated lastMeditationDate for consistency');
      print('Total flow lost: ${updatedFlow.totalFlowLost}');
      print('Current streak synced with flow value: ${updatedFlow.flow}');
      return true;
    } catch (e) {
      print('Error manually reducing flow: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Add a new page to meditation content (admin only)
  Future<bool> addArticlePage({
    required String contentId,
    required ArticleContent page,
  }) async {
    try {
      // Check if user is admin
      if (!await isAdmin()) {
        print('User is not authorized to add article pages');
        return false;
      }

      // Get the document reference
      final docRef = _contentCollection.doc(contentId);
      
      // Get the current document
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        print('Meditation content document not found: $contentId');
        return false;
      }
      
      // Update the document with the new page
      await docRef.update({
        'articlePages': FieldValue.arrayUnion([page.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _userEmail,
      });
      
      return true;
    } catch (e) {
      print('Error adding article page: $e');
      return false;
    }
  }
  
  // Update an existing article page (admin only)
  Future<bool> updateArticlePage({
    required String contentId,
    required int pageIndex,
    required ArticleContent updatedPage,
  }) async {
    try {
      // Check if user is admin
      if (!await isAdmin()) {
        print('User is not authorized to update article pages');
        return false;
      }
      
      // Get the document reference
      final docRef = _contentCollection.doc(contentId);
      
      // Get the current document
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        print('Meditation content document not found: $contentId');
        return false;
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      
      // If pageIndex is 0, we're updating the main article
      if (pageIndex == 0) {
        await docRef.update({
          'article': updatedPage.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _userEmail,
        });
        return true;
      }
      
      // For other pages, we need to update the specific page in the array
      if (!data.containsKey('articlePages') || 
          data['articlePages'] is! List || 
          (data['articlePages'] as List).length < pageIndex) {
        print('Article page not found at index: $pageIndex');
        return false;
      }
      
      // Get current pages
      List<dynamic> currentPages = data['articlePages'] as List;
      
      // Create a new list with the updated page
      List<Map<String, dynamic>> updatedPages = [];
      for (int i = 0; i < currentPages.length; i++) {
        if (i == pageIndex - 1) {
          updatedPages.add(updatedPage.toMap());
        } else {
          updatedPages.add(Map<String, dynamic>.from(currentPages[i] as Map));
        }
      }
      
      // Update the document
      await docRef.update({
        'articlePages': updatedPages,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _userEmail,
      });
      
      return true;
    } catch (e) {
      print('Error updating article page: $e');
      return false;
    }
  }
  
  // Remove an article page (admin only)
  Future<bool> removeArticlePage({
    required String contentId,
    required int pageIndex,
  }) async {
    try {
      // Check if user is admin
      if (!await isAdmin()) {
        print('User is not authorized to remove article pages');
        return false;
      }
      
      // Cannot remove the main article (pageIndex 0)
      if (pageIndex == 0) {
        print('Cannot remove the main article (pageIndex 0)');
        return false;
      }
      
      // Get the document reference
      final docRef = _contentCollection.doc(contentId);
      
      // Get the current document
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        print('Meditation content document not found: $contentId');
        return false;
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      
      // Check if the article pages exist
      if (!data.containsKey('articlePages') || 
          data['articlePages'] is! List || 
          (data['articlePages'] as List).length < pageIndex) {
        print('Article page not found at index: $pageIndex');
        return false;
      }
      
      // Get current pages
      List<dynamic> currentPages = data['articlePages'] as List;
      
      // Create a new list without the removed page
      List<Map<String, dynamic>> updatedPages = [];
      for (int i = 0; i < currentPages.length; i++) {
        if (i != pageIndex - 1) {
          updatedPages.add(Map<String, dynamic>.from(currentPages[i] as Map));
        }
      }
      
      // Update the document
      await docRef.update({
        'articlePages': updatedPages,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _userEmail,
      });
      
      return true;
    } catch (e) {
      print('Error removing article page: $e');
      return false;
    }
  }

  // CUSTOM MEDITATION METHODS
  
  // Get all custom meditation content
  Future<List<CustomMeditation>> getCustomMeditations() async {
    try {
      print('Fetching all custom meditation content from Firestore...');
      
      final querySnapshot = await _customMeditationCollection
          .where('isActive', isEqualTo: true)
          .get();
      
      print('Retrieved ${querySnapshot.docs.length} custom meditation documents');
      
      if (querySnapshot.docs.isEmpty) {
        print('No custom meditation documents found');
        return [];
      }
      
      // Convert documents to CustomMeditation objects
      var customMeditations = querySnapshot.docs
          .map((doc) => CustomMeditation.fromFirestore(doc))
          .toList();
      
      // Sort by duration (shortest first)
      customMeditations.sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
      
      print('Successfully parsed ${customMeditations.length} custom meditation documents');
      return customMeditations;
    } catch (e) {
      print('Error getting custom meditations: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }
  
  // Get custom meditation by ID
  Future<CustomMeditation?> getCustomMeditationById(String id) async {
    try {
      final doc = await _customMeditationCollection.doc(id).get();
      
      if (!doc.exists) {
        return null;
      }
      
      return CustomMeditation.fromFirestore(doc);
    } catch (e) {
      print('Error getting custom meditation by ID: $e');
      return null;
    }
  }
  
  // Add custom meditation (admin only)
  Future<bool> addCustomMeditation({
    required String title,
    required String description,
    required int durationMinutes,
    required CustomMeditationAudio audio,
    CustomMeditationArticle? article,
    bool isActive = true,
  }) async {
    try {
      // Check if user is admin
      if (!await isAdmin()) {
        print('User is not authorized to add custom meditation content');
        return false;
      }

      print('Adding new custom meditation to Firestore...');
      
      // Generate a unique document ID with timestamp to allow multiple items with same duration
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final docId = 'custom-$durationMinutes-minutes-$timestamp';
      print('Using document ID: $docId');
      
      // Create a data map with audio information properly converted
      final Map<String, dynamic> data = {
        'title': title,
        'description': description,
        'durationMinutes': durationMinutes,
        'audio': audio.toMap(), // This will now properly include audio-script if present
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _userEmail,
        'isActive': isActive,
      };
      
      // Add article only if it's not null
      if (article != null) {
        data['article'] = article.toMap();
      }
      
      // Use set instead of add to specify the document ID
      await _customMeditationCollection.doc(docId).set(data);
      
      print('Custom meditation document added successfully with ID: $docId');
      return true;
    } catch (e) {
      print('Error adding custom meditation: $e');
      return false;
    }
  }
  
  // Update custom meditation (admin only)
  Future<bool> updateCustomMeditation({
    required String id,
    required String title,
    required String description,
    required int durationMinutes,
    required CustomMeditationAudio audio,
    CustomMeditationArticle? article,
    required bool isActive,
  }) async {
    try {
      // Check if user is admin
      if (!await isAdmin()) {
        print('User is not authorized to update custom meditation content');
        return false;
      }
      
      final docRef = _customMeditationCollection.doc(id);
      
      // First get existing document to verify changes
      final existingDoc = await docRef.get();
      if (!existingDoc.exists) {
        print('Cannot update: document does not exist');
        return false;
      }
      
      print('Updating custom meditation with ID: $id');
      print('Audio script provided: ${audio.audioScript != null ? 'Yes (${audio.audioScript!.length} chars)' : 'No'}');
      
      // Create a data map, ensuring audio script is properly included
      final Map<String, dynamic> data = {
        'title': title,
        'description': description,
        'durationMinutes': durationMinutes,
        'audio': audio.toMap(), // This will include audio-script if present
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _userEmail,
      };
      
      // Add article only if it's not null
      if (article != null) {
        data['article'] = article.toMap();
      } else {
        // If article is null and we're updating, remove the article field
        data['article'] = FieldValue.delete();
      }
      
      // Log the audio data being sent
      print('Audio data being saved: ${data['audio']}');
      
      await docRef.update(data);
      print('Custom meditation updated successfully');
      
      return true;
    } catch (e) {
      print('Error updating custom meditation: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }
  
  // Check if user already earned flow today
  Future<bool> _hasEarnedFlowToday() async {
    if (_userId == null) return false;
    
    try {
      // Get the user's flow
      final userFlow = await getUserFlow();
      if (userFlow == null || userFlow.lastMeditationDate == null) {
        return false; // No flow document or last meditation date
      }
      
      // Get today's date (without time)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Get the last meditation date (without time)
      final lastMeditationDate = userFlow.lastMeditationDate!;
      final lastMeditationDay = DateTime(
        lastMeditationDate.year,
        lastMeditationDate.month,
        lastMeditationDate.day
      );
      
      // Check if the last meditation was today
      if (lastMeditationDay.isAtSameMomentAs(today)) {
        // Check if earnedFlowToday flag is set
        final flowDoc = await _flowCollection.doc(_userId).get();
        final data = flowDoc.data() as Map<String, dynamic>? ?? {};
        
        return data['earnedFlowToday'] == true;
      }
      
      return false;
    } catch (e) {
      print('Error checking if user earned flow today: $e');
      return false;
    }
  }
  
  // Record completion of custom meditation
  Future<bool> completeCustomMeditation(String id) async {
    if (_userId == null) return false;
    
    try {
      // Get the meditation to confirm it exists
      final meditation = await getCustomMeditationById(id);
      if (meditation == null) {
        print('Cannot complete custom meditation: meditation not found');
        return false;
      }
      
      // Check if the user has a flow document
      final flowDoc = await _flowCollection.doc(_userId).get();
      bool flowAdded = false;
      
      // Check if user already earned flow today
      final earnedToday = await _hasEarnedFlowToday();
      
      if (!flowDoc.exists) {
        // User doesn't have a flow document yet, create one and add flow
        print('Creating new flow document for user');
        await _flowCollection.doc(_userId).set({
          'userId': _userId,
          'email': _userEmail ?? '$_userId@anonymous.user',
          'flow': 1, // Add 1 flow point
          'earnedFromDays': [],
          'lastMeditationDate': FieldValue.serverTimestamp(),
          'customFlow': 1, // Track in customFlow as well
          'totalFlowLost': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'earnedFlowToday': true, // Mark that flow was earned today
        });
        flowAdded = true;
      } else if (!earnedToday) {
        // User has a flow document but hasn't earned flow today, so add flow
        await _flowCollection.doc(_userId).update({
          'flow': FieldValue.increment(1),
          'customFlow': FieldValue.increment(1),
          'lastMeditationDate': FieldValue.serverTimestamp(),
          'earnedFlowToday': true,
        });
        flowAdded = true;
      } else {
        // User already earned flow today, just update the lastMeditationDate
        await _flowCollection.doc(_userId).update({
          'lastMeditationDate': FieldValue.serverTimestamp(),
        });
      }
      
      if (flowAdded) {
        print('Added 1 flow point for completing custom meditation');
      } else {
        print('Completed custom meditation (no flow points added - already earned today)');
      }
      
      return true;
    } catch (e) {
      print('Error completing custom meditation: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }
  
  // Create initial custom meditations (only for empty database)
  Future<void> createInitialCustomMeditations() async {
    try {
      // Check if there are existing custom meditations
      final existing = await getCustomMeditations();
      if (existing.isNotEmpty) {
        print('Custom meditations already exist, skipping initialization');
        return;
      }
      
      // Create 5-minute meditation
      await addCustomMeditation(
        title: '5-Minute Breathing',
        description: 'A quick breathing meditation to center yourself',
        durationMinutes: 5,
        audio: CustomMeditationAudio(
          title: '5-Minute Breathing',
          url: 'https://example.com/meditations/5min.mp3',
          durationInSeconds: 300,
        ),
        article: CustomMeditationArticle(
          title: 'Quick Breathing Techniques',
          content: 'This short meditation focuses on breathing techniques that can be done anywhere to quickly center yourself.',
        ),
      );
      
      // Create 10-minute meditation
      await addCustomMeditation(
        title: '10-Minute Body Scan',
        description: 'A body awareness meditation',
        durationMinutes: 10,
        audio: CustomMeditationAudio(
          title: '10-Minute Body Scan',
          url: 'https://example.com/meditations/10min.mp3',
          durationInSeconds: 600,
        ),
        article: CustomMeditationArticle(
          title: 'Body Awareness Practice',
          content: 'This meditation guides you through a body scan to increase awareness and reduce tension throughout your body.',
        ),
      );
      
      // Create 15-minute meditation
      await addCustomMeditation(
        title: '15-Minute Mindfulness',
        description: 'A mindfulness practice for stress relief',
        durationMinutes: 15,
        audio: CustomMeditationAudio(
          title: '15-Minute Mindfulness',
          url: 'https://example.com/meditations/15min.mp3',
          durationInSeconds: 900,
        ),
        article: CustomMeditationArticle(
          title: 'Mindfulness for Daily Life',
          content: 'Learn mindfulness techniques that can be incorporated into your daily routine to reduce stress and increase focus.',
        ),
      );
      
      // Create 30-minute meditation
      await addCustomMeditation(
        title: '30-Minute Deep Meditation',
        description: 'A deep meditation practice for inner peace',
        durationMinutes: 30,
        audio: CustomMeditationAudio(
          title: '30-Minute Deep Meditation',
          url: 'https://example.com/meditations/30min.mp3',
          durationInSeconds: 1800,
        ),
        article: CustomMeditationArticle(
          title: 'Deep Meditation Practice',
          content: 'This longer meditation allows you to go deeper into your practice and experience profound states of peace and clarity.',
        ),
      );
      
      print('Successfully created initial custom meditations');
    } catch (e) {
      print('Error creating initial custom meditations: $e');
    }
  }

  // Retrieve all available durations from custom meditations
  Future<List<int>> getAvailableDurations() async {
    try {
      // Get only active custom meditations
      final querySnapshot = await _firestore
          .collection('custom_meditation')
          .where('isActive', isEqualTo: true)
          .get();
      
      print('Found ${querySnapshot.docs.length} active meditation documents');
      
      // Extract unique durations
      final durations = querySnapshot.docs
          .map((doc) => CustomMeditation.fromFirestore(doc).durationMinutes)
          .toSet()
          .toList();
      
      // Sort durations in ascending order
      durations.sort();
      
      print('Available durations: $durations');
      return durations;
    } catch (e) {
      print('Error getting available durations: $e');
      return [];
    }
  }

  // Get meditations filtered by duration
  Future<List<CustomMeditation>> getMeditationsByDuration(int duration) async {
    try {
      final querySnapshot = await _firestore
          .collection('custom_meditation')
          .where('durationMinutes', isEqualTo: duration)
          .where('isActive', isEqualTo: true)
          .get();
      
      print('Found ${querySnapshot.docs.length} meditations for duration $duration');
      
      final meditations = querySnapshot.docs
          .map((doc) => CustomMeditation.fromFirestore(doc))
          .toList();
      
      // Sort by creation date (newest first)
      meditations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return meditations;
    } catch (e) {
      print('Error getting meditations by duration: $e');
      return [];
    }
  }

  // Get user's meditation progress
  Future<Map<String, dynamic>> getUserMeditationProgress() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return {
          'total_flow_earned': 0,
          'total_meditations_completed': 0,
          'total_minutes_meditated': 0,
          'completed_meditations': <String>[],
        };
      }
      
      final userProgressDoc = await _firestore
          .collection('user_meditation_progress')
          .doc(user.uid)
          .get();
      
      if (!userProgressDoc.exists) {
        return {
          'total_flow_earned': 0,
          'total_meditations_completed': 0,
          'total_minutes_meditated': 0,
          'completed_meditations': <String>[],
        };
      }
      
      final data = userProgressDoc.data() as Map<String, dynamic>;
      
      // Ensure completed_meditations is present and is a List<String>
      if (!data.containsKey('completed_meditations')) {
        data['completed_meditations'] = <String>[];
      } else {
        data['completed_meditations'] = List<String>.from(data['completed_meditations']);
      }
      
      return data;
    } catch (e) {
      print('Error getting user meditation progress: $e');
      return {
        'total_flow_earned': 0,
        'total_meditations_completed': 0,
        'total_minutes_meditated': 0,
        'completed_meditations': <String>[],
      };
    }
  }
  
  // Check if a meditation is completed by the current user
  Future<bool> isMeditationCompleted(String meditationId) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return false;
      }
      
      final userProgressDoc = await _firestore
          .collection('user_meditation_progress')
          .doc(user.uid)
          .get();
      
      if (!userProgressDoc.exists) {
        return false;
      }
      
      final completedMeditations = List<String>.from(
          userProgressDoc.data()?['completed_meditations'] ?? []);
      
      return completedMeditations.contains(meditationId);
    } catch (e) {
      print('Error checking if meditation is completed: $e');
      return false;
    }
  }
} 