import '../utils/language_helper.dart';

class Category {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? parentId;
  final bool active;
  final int position;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.parentId,
    this.active = true,
    this.position = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    try {
      final category = json['category'] ?? json;

      return Category(
        id: category['id']?.toString() ?? '',
        name: LanguageHelper.extractValueOrEmpty(category['name']),
        description: LanguageHelper.extractValue(category['description']),
        imageUrl: category['image_url']?.toString(),
        parentId: category['id_parent']?.toString(),
        active: category['active'] == '1' || category['active'] == true,
        position: category['position'] is int
            ? category['position']
            : int.tryParse(category['position']?.toString() ?? '0') ?? 0,
      );
    } catch (e) {
      throw Exception('Failed to parse category: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'id_parent': parentId,
      'active': active,
      'position': position,
    };
  }
}
