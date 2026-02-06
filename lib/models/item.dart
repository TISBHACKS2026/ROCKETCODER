class Item {
  final String id;
  final String sellerEmail;
  final String title;
  final String? description;
  final String? category;
  final int conditionRating;
  final String? imageUrl;
  final bool isSwapped;
  final DateTime createdAt;

  Item({
    required this.id,
    required this.sellerEmail,
    required this.title,
    this.description,
    this.category,
    required this.conditionRating,
    this.imageUrl,
    this.isSwapped = false,
    required this.createdAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,

      sellerEmail: json['seller_email'] as String,
      title: json['title'] as String,
      description: json['description'],
      category: json['category'],

      conditionRating: json['condition_rating'] is int
          ? json['condition_rating']
          : 3,
      imageUrl: json['image_url'],
      isSwapped: json['is_swapped'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_email': sellerEmail,
      'title': title,
      'description': description,
      'category': category,
      'condition_rating': conditionRating,
      'image_url': imageUrl,
      'is_swapped': isSwapped,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get conditionString {
    switch (conditionRating) {
      case 5: return 'New';
      case 4: return 'Like New';
      case 3: return 'Used';
      case 2: return 'Fair';
      case 1: return 'Poor';
      default: return 'Used';
    }
  }
}