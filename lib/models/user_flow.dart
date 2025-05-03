import 'package:cloud_firestore/cloud_firestore.dart';

class UserFlow {
  final String userId;
  final String email;
  final int flow;
  final List<int> earnedFromDays;
  final Map<String, dynamic> flowAchievements;
  
  UserFlow({
    required this.userId,
    required this.email,
    this.flow = 0,
    this.earnedFromDays = const [],
    this.flowAchievements = const {},
  });
  
  factory UserFlow.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserFlow(
      userId: doc.id,
      email: data['email'] ?? '',
      flow: data['flow'] ?? 0,
      earnedFromDays: List<int>.from(data['earnedFromDays'] ?? []),
      flowAchievements: data['flowAchievements'] ?? {},
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'email': email,
      'flow': flow,
      'earnedFromDays': earnedFromDays,
      'flowAchievements': flowAchievements,
    };
  }
  
  UserFlow copyWith({
    String? userId,
    String? email,
    int? flow,
    List<int>? earnedFromDays,
    Map<String, dynamic>? flowAchievements,
  }) {
    return UserFlow(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      flow: flow ?? this.flow,
      earnedFromDays: earnedFromDays ?? this.earnedFromDays,
      flowAchievements: flowAchievements ?? this.flowAchievements,
    );
  }
  
  bool hasFlowForDay(int day) {
    return earnedFromDays.contains(day);
  }
  
  UserFlow addFlowForDay(int day) {
    if (hasFlowForDay(day)) return this;
    
    final updatedEarnedFromDays = List<int>.from(earnedFromDays)..add(day);
    return copyWith(
      flow: flow + 1,
      earnedFromDays: updatedEarnedFromDays,
    );
  }
} 