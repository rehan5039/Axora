import 'package:cloud_firestore/cloud_firestore.dart';

class MeditationContent {
  final String id;
  final int day;
  final String title;
  final Map<String, dynamic> article;
  final Map<String, dynamic> audio;
  final Timestamp createdAt;
  final bool isActive;
  final List<Map<String, dynamic>> articlePages;

  MeditationContent({
    required this.id,
    required this.day,
    required this.title,
    required this.article,
    required this.audio,
    required this.createdAt,
    this.isActive = true,
    this.articlePages = const [],
  });
  
  // Simple constructor for creating a MeditationContent with just a day number
  MeditationContent.withDay({required this.day})
    : id = 'Day-$day',
      title = 'Day $day',
      article = {'title': 'Day $day', 'content': ''},
      audio = {'title': 'Day $day', 'url': '', 'durationInSeconds': 0},
      createdAt = Timestamp.now(),
      isActive = true,
      articlePages = [];

  factory MeditationContent.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      print('Parsing document ${doc.id} with data: $data');
      
      // Extract day value and handle different formats
      int dayValue;
      if (data['day'] is int) {
        dayValue = data['day'] as int;
      } else if (data['day'] is String) {
        dayValue = int.tryParse(data['day'] as String) ?? 0;
        print('Warning: day field was a string, converted to int: ${data['day']} -> $dayValue');
      } else {
        dayValue = 0;
        print('Warning: day field is missing or not a valid format, using default: 0');
      }
      
      // Extract article data
      Map<String, dynamic> articleData;
      if (data['article'] is Map) {
        articleData = Map<String, dynamic>.from(data['article'] as Map);
      } else {
        articleData = {'title': 'No article', 'content': 'No content available'};
        print('Warning: article field is missing or invalid format in document ${doc.id}');
      }
      
      // Extract audio data
      Map<String, dynamic> audioData;
      if (data['audio'] is Map) {
        audioData = Map<String, dynamic>.from(data['audio'] as Map);
      } else {
        audioData = {'title': 'No audio', 'url': '', 'durationInSeconds': 0};
        print('Warning: audio field is missing or invalid format in document ${doc.id}');
      }
      
      // Extract additional article pages
      List<Map<String, dynamic>> pages = [];
      if (data['articlePages'] is List) {
        pages = List<Map<String, dynamic>>.from(
          (data['articlePages'] as List).map((page) => 
            page is Map ? Map<String, dynamic>.from(page) : {'title': 'Error', 'content': 'Invalid page format'}
          )
        );
      }
      
      final content = MeditationContent(
        id: doc.id,
        day: dayValue,
        title: data['title'] as String? ?? 'Untitled Meditation',
        article: articleData,
        audio: audioData,
        createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
        isActive: data['isActive'] as bool? ?? true,
        articlePages: pages,
      );
      
      print('Successfully parsed document ${doc.id} as MeditationContent: Day ${content.day}, Title: ${content.title}');
      return content;
    } catch (e) {
      print('Error parsing document ${doc.id}: $e');
      print('Stack trace: ${StackTrace.current}');
      // Return a default meditation content as fallback
      return MeditationContent(
        id: doc.id,
        day: 0,
        title: 'Error Loading Content',
        article: {'title': 'Error', 'content': 'There was an error loading this content'},
        audio: {'title': 'Error', 'url': '', 'durationInSeconds': 0},
        createdAt: Timestamp.now(),
        isActive: false,
        articlePages: [],
      );
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'day': day,
      'title': title,
      'article': article,
      'audio': audio,
      'createdAt': createdAt,
      'isActive': isActive,
      'articlePages': articlePages,
    };
  }
  
  // Get all article pages including the main article as the first page
  List<ArticleContent> getAllPages() {
    List<ArticleContent> allPages = [ArticleContent.fromMap(article)];
    
    for (var page in articlePages) {
      allPages.add(ArticleContent.fromMap(page));
    }
    
    return allPages;
  }
  
  // Get the number of pages (main article + additional pages)
  int get pageCount => 1 + articlePages.length;
  
  // Get a specific page (0 = main article, 1+ = additional pages)
  ArticleContent getPage(int pageIndex) {
    if (pageIndex == 0) {
      return ArticleContent.fromMap(article);
    } else if (pageIndex > 0 && pageIndex <= articlePages.length) {
      return ArticleContent.fromMap(articlePages[pageIndex - 1]);
    } else {
      return ArticleContent(
        title: 'Page Not Found',
        content: 'The requested page does not exist.',
      );
    }
  }
}

class ArticleContent {
  final String title;
  final String content;
  final String buttonText;
  
  ArticleContent({
    required this.title,
    required this.content,
    this.buttonText = 'Mark as Read',
  });
  
  factory ArticleContent.fromMap(Map<String, dynamic> map) {
    return ArticleContent(
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      buttonText: map['button'] ?? 'Mark as Read',
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'button': buttonText,
    };
  }
}

class AudioContent {
  final String title;
  final String url;
  final int durationInSeconds;
  final String audioScript;
  
  AudioContent({
    required this.title,
    required this.url,
    required this.durationInSeconds,
    this.audioScript = '',
  });
  
  factory AudioContent.fromMap(Map<String, dynamic> map) {
    return AudioContent(
      title: map['title'] ?? '',
      url: map['url'] ?? '',
      durationInSeconds: map['durationInSeconds'] ?? 0,
      audioScript: map['audio-script'] ?? '',
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'url': url,
      'durationInSeconds': durationInSeconds,
      'audio-script': audioScript,
    };
  }
} 