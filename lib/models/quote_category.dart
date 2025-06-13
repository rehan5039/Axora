class QuoteCategory {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final String? imageUrl;

  QuoteCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    this.imageUrl,
  });

  factory QuoteCategory.fromJson(Map<String, dynamic> json, String id) {
    return QuoteCategory(
      id: id,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconName: json['iconName'] ?? 'format_quote',
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'iconName': iconName,
      'imageUrl': imageUrl,
    };
  }
} 