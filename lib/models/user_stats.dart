import 'package:cloud_firestore/cloud_firestore.dart';

class UserStats {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final int totalMinutes;
  final int sessionsCompleted;
  final Map<String, dynamic> lastSessionData;
  final Timestamp lastUpdated;
  
  UserStats({
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalMinutes = 0,
    this.sessionsCompleted = 0,
    this.lastSessionData = const {},
    required this.lastUpdated,
  });
  
  factory UserStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserStats(
      userId: doc.id,
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      totalMinutes: data['totalMinutes'] ?? 0,
      sessionsCompleted: data['sessionsCompleted'] ?? 0,
      lastSessionData: Map<String, dynamic>.from(data['lastSessionData'] ?? {}),
      lastUpdated: data['lastUpdated'] ?? Timestamp.now(),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalMinutes': totalMinutes,
      'sessionsCompleted': sessionsCompleted,
      'lastSessionData': lastSessionData,
      'lastUpdated': lastUpdated,
    };
  }
  
  UserStats copyWith({
    String? userId,
    int? currentStreak,
    int? longestStreak,
    int? totalMinutes,
    int? sessionsCompleted,
    Map<String, dynamic>? lastSessionData,
    Timestamp? lastUpdated,
  }) {
    return UserStats(
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      sessionsCompleted: sessionsCompleted ?? this.sessionsCompleted,
      lastSessionData: lastSessionData ?? this.lastSessionData,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  // Check if a session was completed today
  bool hasCompletedSessionToday() {
    if (lastUpdated == null) return false;
    
    final now = DateTime.now();
    final lastUpdate = lastUpdated.toDate();
    
    return now.year == lastUpdate.year && 
           now.month == lastUpdate.month && 
           now.day == lastUpdate.day;
  }
} 