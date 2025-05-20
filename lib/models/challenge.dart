import 'package:flutter/material.dart';

enum ChallengeType {
  meditation,
  poll,
  task,
  quiz
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final DateTime startDate;
  final DateTime endDate;
  final int durationMinutes; // For meditation challenges
  final Map<String, int>? pollOptions; // For poll challenges
  final List<Map<String, dynamic>>? quizQuestions; // For quiz challenges
  final double? userProgress; // Progress for the current user (0.0 to 1.0)
  final bool isCompleted;
  final String createdBy;
  final bool isMultiSelect; // Whether poll allows multiple selections
  final String buttonText; // Custom text for action button

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.startDate,
    required this.endDate,
    this.durationMinutes = 0,
    this.pollOptions,
    this.quizQuestions,
    this.userProgress = 0.0,
    this.isCompleted = false,
    required this.createdBy,
    this.isMultiSelect = false, // Default to single-select polls
    this.buttonText = 'Complete Challenge', // Default button text
  });

  factory Challenge.fromMap(Map<String, dynamic> map, String id) {
    // Handle quiz questions
    List<Map<String, dynamic>>? quizQuestions;
    if (map['quizQuestions'] != null) {
      quizQuestions = List<Map<String, dynamic>>.from(
          (map['quizQuestions'] as List).map((q) => Map<String, dynamic>.from(q)));
    }
    
    return Challenge(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: ChallengeType.values.byName(map['type'] ?? 'meditation'),
      startDate: DateTime.parse(map['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(map['endDate'] ?? DateTime.now().add(const Duration(days: 7)).toIso8601String()),
      durationMinutes: map['durationMinutes'] ?? 5,
      pollOptions: map['pollOptions'] != null ? Map<String, int>.from(map['pollOptions']) : null,
      quizQuestions: quizQuestions,
      userProgress: map['userProgress']?.toDouble() ?? 0.0,
      isCompleted: map['isCompleted'] ?? false,
      createdBy: map['createdBy'] ?? '',
      isMultiSelect: map['isMultiSelect'] ?? false,
      buttonText: map['buttonText'] ?? 'Complete Challenge',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'durationMinutes': durationMinutes,
      'pollOptions': pollOptions,
      'quizQuestions': quizQuestions,
      'isCompleted': isCompleted,
      'createdBy': createdBy,
      'isMultiSelect': isMultiSelect,
      'buttonText': buttonText,
    };
  }

  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    ChallengeType? type,
    DateTime? startDate,
    DateTime? endDate,
    int? durationMinutes,
    Map<String, int>? pollOptions,
    List<Map<String, dynamic>>? quizQuestions,
    double? userProgress,
    bool? isCompleted,
    String? createdBy,
    bool? isMultiSelect,
    String? buttonText,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      pollOptions: pollOptions ?? this.pollOptions,
      quizQuestions: quizQuestions ?? this.quizQuestions,
      userProgress: userProgress ?? this.userProgress,
      isCompleted: isCompleted ?? this.isCompleted,
      createdBy: createdBy ?? this.createdBy,
      isMultiSelect: isMultiSelect ?? this.isMultiSelect,
      buttonText: buttonText ?? this.buttonText,
    );
  }
} 