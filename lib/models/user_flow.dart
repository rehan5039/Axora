import 'package:cloud_firestore/cloud_firestore.dart';

class UserFlow {
  final String userId;
  final String email;
  final int flow;
  final List<int> earnedFromDays;
  final Map<String, dynamic> flowAchievements;
  final DateTime? lastMeditationDate;
  final int totalFlowLost;
  final int customFlow;
  final bool earnedFlowToday;
  
  UserFlow({
    required this.userId,
    required this.email,
    this.flow = 0,
    this.earnedFromDays = const [],
    this.flowAchievements = const {},
    this.lastMeditationDate,
    this.totalFlowLost = 0,
    this.customFlow = 0,
    this.earnedFlowToday = false,
  });
  
  factory UserFlow.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserFlow(
      userId: doc.id,
      email: data['email'] ?? '',
      flow: data['flow'] ?? 0,
      earnedFromDays: List<int>.from(data['earnedFromDays'] ?? []),
      flowAchievements: data['flowAchievements'] ?? {},
      lastMeditationDate: data['lastMeditationDate'] != null 
          ? (data['lastMeditationDate'] as Timestamp).toDate() 
          : null,
      totalFlowLost: data['totalFlowLost'] ?? 0,
      customFlow: data['customFlow'] ?? 0,
      earnedFlowToday: data['earnedFlowToday'] ?? false,
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'email': email,
      'flow': flow,
      'earnedFromDays': earnedFromDays,
      'flowAchievements': flowAchievements,
      'lastMeditationDate': lastMeditationDate != null 
          ? Timestamp.fromDate(lastMeditationDate!) 
          : null,
      'totalFlowLost': totalFlowLost,
      'customFlow': customFlow,
      'earnedFlowToday': earnedFlowToday,
    };
  }
  
  UserFlow copyWith({
    String? userId,
    String? email,
    int? flow,
    List<int>? earnedFromDays,
    Map<String, dynamic>? flowAchievements,
    DateTime? lastMeditationDate,
    int? totalFlowLost,
    int? customFlow,
    bool? earnedFlowToday,
  }) {
    return UserFlow(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      flow: flow ?? this.flow,
      earnedFromDays: earnedFromDays ?? this.earnedFromDays,
      flowAchievements: flowAchievements ?? this.flowAchievements,
      lastMeditationDate: lastMeditationDate ?? this.lastMeditationDate,
      totalFlowLost: totalFlowLost ?? this.totalFlowLost,
      customFlow: customFlow ?? this.customFlow,
      earnedFlowToday: earnedFlowToday ?? this.earnedFlowToday,
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
      lastMeditationDate: DateTime.now(),
    );
  }
  
  UserFlow reduceFlow() {
    // Don't reduce if flow is already 0
    if (flow <= 0) return this;
    
    // Reduce flow by 1 and increment totalFlowLost
    return copyWith(
      flow: flow - 1,
      totalFlowLost: totalFlowLost + 1,
    );
  }
  
  // Get journey flow only (excluding custom meditation flow)
  int get journeyFlow => earnedFromDays.length;
} 