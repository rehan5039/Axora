import 'package:cloud_firestore/cloud_firestore.dart';

class UserProgress {
  final String userId;
  final String email;
  final int currentDay;
  final int lastCompletedDay;
  final Timestamp lastCompletedAt;
  final List<int> completedDays;
  
  UserProgress({
    required this.userId,
    required this.email,
    this.currentDay = 1,
    this.lastCompletedDay = 0,
    required this.lastCompletedAt,
    this.completedDays = const [],
  });
  
  factory UserProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProgress(
      userId: doc.id,
      email: data['email'] ?? '',
      currentDay: data['currentDay'] ?? 1,
      lastCompletedDay: data['lastCompletedDay'] ?? 0,
      lastCompletedAt: data['lastCompletedAt'] ?? Timestamp.now(),
      completedDays: List<int>.from(data['completedDays'] ?? []),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'email': email,
      'currentDay': currentDay,
      'lastCompletedDay': lastCompletedDay,
      'lastCompletedAt': lastCompletedAt,
      'completedDays': completedDays,
    };
  }
  
  UserProgress copyWith({
    String? userId,
    String? email,
    int? currentDay,
    int? lastCompletedDay,
    Timestamp? lastCompletedAt,
    List<int>? completedDays,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      currentDay: currentDay ?? this.currentDay,
      lastCompletedDay: lastCompletedDay ?? this.lastCompletedDay,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      completedDays: completedDays ?? this.completedDays,
    );
  }
  
  bool canUnlockNextDay() {
    if (lastCompletedDay == 0) return true;
    
    final now = Timestamp.now();
    final diff = now.seconds - lastCompletedAt.seconds;
    
    // Check if 24 hours (86400 seconds) have passed
    return diff >= 86400;
  }
  
  // Get time remaining in seconds until next day unlocks
  int getSecondsUntilNextDayUnlocks() {
    if (lastCompletedDay == 0 || canUnlockNextDay()) return 0;
    
    final now = Timestamp.now();
    final elapsedSeconds = now.seconds - lastCompletedAt.seconds;
    final remainingSeconds = 86400 - elapsedSeconds;
    
    return remainingSeconds > 0 ? remainingSeconds : 0;
  }
  
  // Get formatted string of time remaining until next day unlocks
  String getFormattedTimeRemaining() {
    final totalSeconds = getSecondsUntilNextDayUnlocks();
    if (totalSeconds <= 0) return "Ready to unlock";
    
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
  }
  
  // Check if a specific day is completed
  bool isDayCompleted(int day) {
    return completedDays.contains(day);
  }
} 