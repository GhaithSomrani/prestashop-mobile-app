/// Model for PrestaShop manufacturer (brand)
class Manufacturer {
  final String id;
  final String name;
  final String description;
  final String? shortDescription;
  final String? logoUrl;
  final bool active;
  final String? metaTitle;
  final String? metaDescription;

  Manufacturer({
    required this.id,
    required this.name,
    required this.description,
    this.shortDescription,
    this.logoUrl,
    this.active = true,
    this.metaTitle,
    this.metaDescription,
  });

  factory Manufacturer.fromJson(Map<String, dynamic> json) {
    return Manufacturer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      shortDescription: json['short_description']?.toString(),
      logoUrl: json['logo_url']?.toString(),
      active: json['active'] == '1' || json['active'] == true,
      metaTitle: json['meta_title']?.toString(),
      metaDescription: json['meta_description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'short_description': shortDescription,
      'logo_url': logoUrl,
      'active': active ? '1' : '0',
      'meta_title': metaTitle,
      'meta_description': metaDescription,
    };
  }
}
