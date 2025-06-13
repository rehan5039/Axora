class Quote {
  final String id;
  final String text;
  final String author;
  final String categoryId;
  final String categoryName;
  final bool isFavorite;
  final DateTime createdAt;
  final String? imageUrl;

  Quote({
    required this.id,
    required this.text,
    required this.author,
    required this.categoryId,
    required this.categoryName,
    this.isFavorite = false,
    required this.createdAt,
    this.imageUrl,
  });

  factory Quote.fromJson(Map<String, dynamic> json, String id) {
    return Quote(
      id: id,
      text: json['text'] ?? '',
      author: json['author'] ?? '',
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      isFavorite: json['isFavorite'] ?? false,
      createdAt: json['createdAt'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(json['createdAt']) 
        : DateTime.now(),
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'author': author,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'isFavorite': isFavorite,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'imageUrl': imageUrl,
    };
  }
} 