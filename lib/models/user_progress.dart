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
  
  // Calculate how many hours have passed since the last completion
  double hoursSinceLastCompletion() {
    if (lastCompletedDay == 0) return 0;
    
    final now = Timestamp.now();
    final diffInSeconds = now.seconds - lastCompletedAt.seconds;
    
    return diffInSeconds / 3600;
  }
  
  bool canUnlockNextDay() {
    // Always allow unlocking the next day regardless of time passed
    return true;
  }
  
  // Get time remaining in seconds until next day unlocks
  int getSecondsUntilNextDayUnlocks() {
    // Always return 0 since there's no time restriction
    return 0;
  }
  
  // Get formatted string of time remaining until next day unlocks
  String getFormattedTimeRemaining() {
    // Always return 0 since there's no time restriction
    return "00h 00m 00s";
  }
  
  // Check if a specific day is completed
  bool isDayCompleted(int day) {
    return completedDays.contains(day);
  }
} 