import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:axora/models/challenge.dart';

class ChallengeService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final String _challengesPath = 'challenges';
  final String _userChallengesPath = 'userChallenges';
  
  // Get all active challenges
  Future<List<Challenge>> getActiveChallenges() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      // Get all challenges
      final snapshot = await _database.child(_challengesPath).get();
      if (!snapshot.exists) {
        return [];
      }
      
      final now = DateTime.now();
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      
      // Get user challenges progress
      final userChallengesSnapshot = await _database
          .child(_userChallengesPath)
          .child(userId)
          .get();
          
      Map<dynamic, dynamic> userChallengesData = {};
      if (userChallengesSnapshot.exists) {
        userChallengesData = userChallengesSnapshot.value as Map<dynamic, dynamic>;
      }
      
      List<Challenge> challenges = [];
      
      data.forEach((key, value) {
        final challengeData = Map<String, dynamic>.from(value as Map);
        final challenge = Challenge.fromMap(challengeData, key.toString());
        
        // Only include active challenges
        if (challenge.startDate.isBefore(now) && challenge.endDate.isAfter(now)) {
          // Add user progress if available
          if (userChallengesData.containsKey(key)) {
            final userProgress = userChallengesData[key]['progress']?.toDouble() ?? 0.0;
            final isCompleted = userChallengesData[key]['completed'] ?? false;
            
            challenges.add(challenge.copyWith(
              userProgress: userProgress,
              isCompleted: isCompleted,
            ));
          } else {
            challenges.add(challenge);
          }
        }
      });
      
      return challenges;
    } catch (e) {
      print('Error getting challenges: $e');
      return [];
    }
  }
  
  // Create a new challenge
  Future<String> createChallenge(Challenge challenge) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      final newChallengeRef = _database.child(_challengesPath).push();
      
      // Create a clean data map for storage
      final Map<String, dynamic> challengeData = {
        'title': challenge.title,
        'description': challenge.description,
        'type': challenge.type.name,
        'startDate': challenge.startDate.toIso8601String(),
        'endDate': challenge.endDate.toIso8601String(),
        'durationMinutes': challenge.durationMinutes,
        'isCompleted': challenge.isCompleted,
        'createdBy': userId,
        'isMultiSelect': challenge.isMultiSelect,
        'buttonText': challenge.buttonText,
      };
      
      // Only add pollOptions if they exist
      if (challenge.pollOptions != null && challenge.pollOptions!.isNotEmpty) {
        challengeData['pollOptions'] = challenge.pollOptions;
      }
      
      // Only add quizQuestions if they exist
      if (challenge.quizQuestions != null && challenge.quizQuestions!.isNotEmpty) {
        challengeData['quizQuestions'] = challenge.quizQuestions;
      }
      
      await newChallengeRef.set(challengeData);
      
      // For debugging, print successful write
      print('Successfully created challenge with ID: ${newChallengeRef.key}');
      
      return newChallengeRef.key!;
    } catch (e) {
      print('Error creating challenge: $e');
      throw Exception('Failed to create challenge');
    }
  }
  
  // Update a user's progress for a challenge
  Future<void> updateChallengeProgress(String challengeId, double progress) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      await _database
          .child(_userChallengesPath)
          .child(userId)
          .child(challengeId)
          .update({
        'progress': progress,
        'completed': progress >= 1.0,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating challenge progress: $e');
      throw Exception('Failed to update challenge progress');
    }
  }
  
  // Submit a vote for a poll challenge (single option)
  Future<void> submitPollVote(String challengeId, String option) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      // Get the current challenge
      final challengeSnapshot = await _database
          .child(_challengesPath)
          .child(challengeId)
          .get();
          
      if (!challengeSnapshot.exists) {
        throw Exception('Challenge not found');
      }
      
      final challengeData = Map<String, dynamic>.from(
          challengeSnapshot.value as Map);
          
      // Check if it's a poll type challenge
      if (challengeData['type'] != 'poll') {
        throw Exception('Not a poll challenge');
      }
      
      // Update the poll results
      Map<String, int> pollOptions = {};
      if (challengeData.containsKey('pollOptions')) {
        pollOptions = Map<String, int>.from(challengeData['pollOptions']);
      }
      
      if (pollOptions.containsKey(option)) {
        pollOptions[option] = (pollOptions[option] ?? 0) + 1;
      } else {
        pollOptions[option] = 1;
      }
      
      await _database
          .child(_challengesPath)
          .child(challengeId)
          .child('pollOptions')
          .set(pollOptions);
          
      // Mark as completed for this user
      await _database
          .child(_userChallengesPath)
          .child(userId)
          .child(challengeId)
          .update({
        'progress': 1.0,
        'completed': true,
        'selectedOption': option,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      print('Error submitting poll vote: $e');
      throw Exception('Failed to submit poll vote');
    }
  }
  
  // Submit votes for a multi-select poll challenge
  Future<void> submitMultiplePollVotes(String challengeId, List<String> options) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      // Get the current challenge
      final challengeSnapshot = await _database
          .child(_challengesPath)
          .child(challengeId)
          .get();
          
      if (!challengeSnapshot.exists) {
        throw Exception('Challenge not found');
      }
      
      final challengeData = Map<String, dynamic>.from(
          challengeSnapshot.value as Map);
          
      // Check if it's a poll type challenge
      if (challengeData['type'] != 'poll') {
        throw Exception('Not a poll challenge');
      }
      
      // Check if multi-select is enabled
      if (!(challengeData['isMultiSelect'] ?? false)) {
        throw Exception('This is not a multi-select poll');
      }
      
      // Update the poll results
      Map<String, int> pollOptions = {};
      if (challengeData.containsKey('pollOptions')) {
        pollOptions = Map<String, int>.from(challengeData['pollOptions']);
      }
      
      for (String option in options) {
        if (pollOptions.containsKey(option)) {
          pollOptions[option] = (pollOptions[option] ?? 0) + 1;
        } else {
          pollOptions[option] = 1;
        }
      }
      
      await _database
          .child(_challengesPath)
          .child(challengeId)
          .child('pollOptions')
          .set(pollOptions);
          
      // Mark as completed for this user
      await _database
          .child(_userChallengesPath)
          .child(userId)
          .child(challengeId)
          .update({
        'progress': 1.0,
        'completed': true,
        'selectedOptions': options,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      print('Error submitting multiple poll votes: $e');
      throw Exception('Failed to submit poll votes');
    }
  }
  
  // Submit quiz answers
  Future<void> submitQuizAnswers(String challengeId, List<Map<String, dynamic>> userAnswers, int correctAnswers) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      // Get the current challenge
      final challengeSnapshot = await _database
          .child(_challengesPath)
          .child(challengeId)
          .get();
          
      if (!challengeSnapshot.exists) {
        throw Exception('Challenge not found');
      }
      
      final challengeData = Map<String, dynamic>.from(
          challengeSnapshot.value as Map);
          
      // Check if it's a quiz type challenge
      if (challengeData['type'] != 'quiz') {
        throw Exception('Not a quiz challenge');
      }
      
      // Calculate progress (percentage of correct answers)
      final totalQuestions = (challengeData['quizQuestions'] as List).length;
      final progress = totalQuestions > 0 ? correctAnswers / totalQuestions : 0.0;
      
      // Mark as completed for this user
      await _database
          .child(_userChallengesPath)
          .child(userId)
          .child(challengeId)
          .update({
        'progress': progress,
        'completed': progress >= 0.7, // Consider completed if 70% or more correct
        'userAnswers': userAnswers,
        'correctAnswers': correctAnswers,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      print('Error submitting quiz answers: $e');
      throw Exception('Failed to submit quiz answers');
    }
  }
  
  // Delete a challenge (admin only)
  Future<void> deleteChallenge(String challengeId) async {
    try {
      await _database.child(_challengesPath).child(challengeId).remove();
    } catch (e) {
      print('Error deleting challenge: $e');
      throw Exception('Failed to delete challenge');
    }
  }
} 