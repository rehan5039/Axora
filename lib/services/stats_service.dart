import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:axora/models/user_stats.dart';

class StatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;
  
  // Collection references
  CollectionReference get _statsCollection => _firestore.collection('user_stats');
  
  // Get user statistics
  Future<UserStats?> getUserStats() async {
    if (_userId == null) return null;
    
    try {
      final doc = await _statsCollection.doc(_userId).get();
      
      if (!doc.exists) {
        // Create a default stats document if it doesn't exist
        final defaultStats = UserStats(
          userId: _userId!,
          lastUpdated: Timestamp.now(),
        );
        
        await _statsCollection.doc(_userId).set(defaultStats.toFirestore());
        return defaultStats;
      }
      
      return UserStats.fromFirestore(doc);
    } catch (e) {
      print('Error getting user stats: $e');
      return null;
    }
  }
  
  // Initialize user stats for a new user
  Future<bool> initializeUserStats() async {
    if (_userId == null) return false;
    
    try {
      final doc = await _statsCollection.doc(_userId).get();
      
      if (!doc.exists) {
        await _statsCollection.doc(_userId).set({
          'userId': _userId,
          'currentStreak': 0,
          'longestStreak': 0,
          'totalMinutes': 0,
          'sessionsCompleted': 0,
          'lastSessionData': {},
          'lastUpdated': Timestamp.now(),
        });
        
        return true;
      }
      
      return false; // Stats already initialized
    } catch (e) {
      print('Error initializing user stats: $e');
      return false;
    }
  }
  
  // Update session completion data and calculate streak
  Future<bool> updateSessionCompletion(int sessionDurationMinutes, {String contentId = ''}) async {
    if (_userId == null) return false;
    
    try {
      // Get current stats
      final userStatsDoc = await _statsCollection.doc(_userId).get();
      late UserStats currentStats;
      
      if (!userStatsDoc.exists) {
        // Create default stats
        currentStats = UserStats(
          userId: _userId!,
          lastUpdated: Timestamp.now(),
        );
      } else {
        currentStats = UserStats.fromFirestore(userStatsDoc);
      }
      
      // Check if this is a new day
      final now = DateTime.now();
      final lastUpdate = currentStats.lastUpdated.toDate();
      final isNewDay = now.year != lastUpdate.year || 
                      now.month != lastUpdate.month || 
                      now.day != lastUpdate.day;
      
      // Calculate new streak - only update in updateStreakForDayCompletion
      // Don't increment streak here, wait for day completion
      int newStreak = currentStats.currentStreak;
      int newLongestStreak = currentStats.longestStreak;
      
      // Update session data without changing streak
      await _statsCollection.doc(_userId).set({
        'userId': _userId,
        'totalMinutes': currentStats.totalMinutes + sessionDurationMinutes,
        'sessionsCompleted': currentStats.sessionsCompleted + 1,
        'lastSessionData': {
          'contentId': contentId,
          'duration': sessionDurationMinutes,
          'completedAt': Timestamp.now(),
        },
        'lastUpdated': Timestamp.now(),
      }, SetOptions(merge: true));
      
      return true;
    } catch (e) {
      print('Error updating session completion: $e');
      return false;
    }
  }
  
  // Update streak for day completion and sticker award
  Future<bool> updateStreakForDayCompletion(int newStreak, int newLongestStreak, {int dayNumber = 0}) async {
    if (_userId == null) return false;
    
    try {
      // Update streak data
      await _statsCollection.doc(_userId).set({
        'userId': _userId,
        'currentStreak': newStreak,
        'longestStreak': newLongestStreak,
        'lastSessionData': {
          'type': 'day_completion',
          'dayNumber': dayNumber,
          'completedAt': Timestamp.now(),
        },
        'lastUpdated': Timestamp.now(),
      }, SetOptions(merge: true));
      
      return true;
    } catch (e) {
      print('Error updating streak for day completion: $e');
      return false;
    }
  }
  
  // Update total flow lost count
  Future<bool> updateTotalFlowLost(int totalFlowLost) async {
    if (_userId == null) return false;
    
    try {
      // Update total flow lost
      await _statsCollection.doc(_userId).set({
        'userId': _userId,
        'totalFlowLost': totalFlowLost,
        'lastUpdated': Timestamp.now(),
      }, SetOptions(merge: true));
      
      return true;
    } catch (e) {
      print('Error updating total flow lost: $e');
      return false;
    }
  }
  
  // Sync current streak with flow value
  Future<bool> syncCurrentStreakWithFlow(int flowValue) async {
    if (_userId == null) return false;
    
    try {
      print('Syncing current streak with flow value: $flowValue');
      
      // Get current stats to preserve other values
      final userStats = await getUserStats();
      if (userStats == null) {
        print('No user stats found to sync with flow');
        return false;
      }
      
      // Update with new flow value as current streak
      await _statsCollection.doc(_userId).set({
        'userId': _userId,
        'currentStreak': flowValue,
        // Keep longest streak unchanged
        'lastUpdated': Timestamp.now(),
      }, SetOptions(merge: true));
      
      print('Streak successfully synced with flow value');
      return true;
    } catch (e) {
      print('Error syncing current streak with flow: $e');
      return false;
    }
  }
  
  // Reset user statistics
  Future<bool> resetUserStats() async {
    if (_userId == null) return false;
    
    try {
      await _statsCollection.doc(_userId).set({
        'userId': _userId,
        'currentStreak': 0,
        'longestStreak': 0,
        'totalMinutes': 0,
        'sessionsCompleted': 0,
        'lastSessionData': {},
        'lastUpdated': Timestamp.now(),
      });
      
      return true;
    } catch (e) {
      print('Error resetting user stats: $e');
      return false;
    }
  }
} 