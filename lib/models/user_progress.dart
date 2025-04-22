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
} 