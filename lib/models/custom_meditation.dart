import 'package:cloud_firestore/cloud_firestore.dart';

class CustomMeditation {
  final String id;
  final String title;
  final String description;
  final int durationMinutes;
  final Map<String, dynamic> audio;
  final Map<String, dynamic>? article;
  final Timestamp createdAt;
  final bool isActive;

  CustomMeditation({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.audio,
    this.article,
    required this.createdAt,
    this.isActive = true,
  });

  factory CustomMeditation.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      
      // Extract audio data
      Map<String, dynamic> audioData;
      if (data['audio'] is Map) {
        audioData = Map<String, dynamic>.from(data['audio'] as Map);
      } else {
        audioData = {
          'title': 'No audio', 
          'url': '', 
          'durationInSeconds': 0
        };
      }
      
      // Extract article data (now optional)
      Map<String, dynamic>? articleData;
      if (data['article'] is Map) {
        articleData = Map<String, dynamic>.from(data['article'] as Map);
      } else {
        articleData = null;
      }
      
      return CustomMeditation(
        id: doc.id,
        title: data['title'] as String? ?? 'Untitled Meditation',
        description: data['description'] as String? ?? '',
        durationMinutes: data['durationMinutes'] as int? ?? 0,
        audio: audioData,
        article: articleData,
        createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
        isActive: data['isActive'] as bool? ?? true,
      );
    } catch (e) {
      print('Error parsing custom meditation document ${doc.id}: $e');
      // Return a default meditation as fallback
      return CustomMeditation(
        id: doc.id,
        title: 'Error Loading Content',
        description: 'There was an error loading this content',
        durationMinutes: 0,
        audio: {'title': 'Error', 'url': '', 'durationInSeconds': 0},
        article: null,
        createdAt: Timestamp.now(),
        isActive: false,
      );
    }
  }

  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'title': title,
      'description': description,
      'durationMinutes': durationMinutes,
      'audio': audio,
      'createdAt': createdAt,
      'isActive': isActive,
    };
    
    // Only add article if it exists
    if (article != null) {
      data['article'] = article;
    }
    
    return data;
  }
}

class CustomMeditationAudio {
  final String title;
  final String url;
  final int durationInSeconds;
  final String? audioScript;
  
  CustomMeditationAudio({
    required this.title,
    required this.url,
    required this.durationInSeconds,
    this.audioScript,
  });
  
  factory CustomMeditationAudio.fromMap(Map<String, dynamic> map) {
    return CustomMeditationAudio(
      title: map['title'] ?? '',
      url: map['url'] ?? '',
      durationInSeconds: map['durationInSeconds'] ?? 0,
      // Check both keys for audio script for backward compatibility
      audioScript: map['audio-script'] ?? map['audioScript'],
    );
  }
  
  Map<String, dynamic> toMap() {
    final map = {
      'title': title,
      'url': url,
      'durationInSeconds': durationInSeconds,
    };
    
    // Always use the same key for audioScript
    if (audioScript != null && audioScript!.isNotEmpty) {
      map['audio-script'] = audioScript!;
    }
    
    return map;
  }
}

class CustomMeditationArticle {
  final String title;
  final String content;
  
  CustomMeditationArticle({
    required this.title,
    required this.content,
  });
  
  factory CustomMeditationArticle.fromMap(Map<String, dynamic> map) {
    return CustomMeditationArticle(
      title: map['title'] ?? '',
      content: map['content'] ?? '',
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
    };
  }
} 