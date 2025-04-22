import 'package:cloud_firestore/cloud_firestore.dart';

class UserStickers {
  final String userId;
  final String email;
  final int stickers;
  final List<int> earnedFromDays;
  final Map<String, dynamic> stickerAchievements;
  
  UserStickers({
    required this.userId,
    required this.email,
    this.stickers = 0,
    this.earnedFromDays = const [],
    this.stickerAchievements = const {},
  });
  
  factory UserStickers.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserStickers(
      userId: doc.id,
      email: data['email'] ?? '',
      stickers: data['stickers'] ?? 0,
      earnedFromDays: List<int>.from(data['earnedFromDays'] ?? []),
      stickerAchievements: data['stickerAchievements'] ?? {},
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'email': email,
      'stickers': stickers,
      'earnedFromDays': earnedFromDays,
      'stickerAchievements': stickerAchievements,
    };
  }
  
  UserStickers copyWith({
    String? userId,
    String? email,
    int? stickers,
    List<int>? earnedFromDays,
    Map<String, dynamic>? stickerAchievements,
  }) {
    return UserStickers(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      stickers: stickers ?? this.stickers,
      earnedFromDays: earnedFromDays ?? this.earnedFromDays,
      stickerAchievements: stickerAchievements ?? this.stickerAchievements,
    );
  }
  
  bool hasStickerForDay(int day) {
    return earnedFromDays.contains(day);
  }
  
  UserStickers addStickerForDay(int day) {
    if (hasStickerForDay(day)) return this;
    
    final updatedEarnedFromDays = List<int>.from(earnedFromDays)..add(day);
    return copyWith(
      stickers: stickers + 1,
      earnedFromDays: updatedEarnedFromDays,
    );
  }
} 