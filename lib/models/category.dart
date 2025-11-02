import 'package:json_annotation/json_annotation.dart';

part 'category.g.dart';

@JsonSerializable()
class Category {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'description')
  final String? description;

  @JsonKey(name: 'link_rewrite')
  final String? linkRewrite;

  @JsonKey(name: 'id_parent')
  final int parentId;

  @JsonKey(name: 'level_depth')
  final int levelDepth;

  @JsonKey(name: 'active', defaultValue: true)
  final bool active;

  @JsonKey(name: 'is_root_category', defaultValue: false)
  final bool isRootCategory;

  @JsonKey(name: 'nb_products_recursive', defaultValue: 0)
  final int productCount;

  @JsonKey(name: 'associations', defaultValue: {})
  final CategoryAssociations associations;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.linkRewrite,
    required this.parentId,
    required this.levelDepth,
    this.active = true,
    this.isRootCategory = false,
    this.productCount = 0,
    this.associations = const CategoryAssociations(),
  });

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryToJson(this);

  // Helper properties
  bool get hasSubcategories => associations.categories?.isNotEmpty ?? false;

  List<Category> get subcategories => associations.categories ?? [];

  String get imageUrl {
    final image = associations.image;
    if (image != null) {
      return '${image.src}?${image.id}';
    }
    return '';
  }
}

@JsonSerializable()
class CategoryAssociations {
  @JsonKey(name: 'categories', defaultValue: [])
  final List<Category>? categories;

  @JsonKey(name: 'products', defaultValue: [])
  final List<CategoryProductRef>? products;

  @JsonKey(name: 'image', defaultValue: null)
  final CategoryImage? image;

  const CategoryAssociations({
    this.categories,
    this.products,
    this.image,
  });

  factory CategoryAssociations.fromJson(Map<String, dynamic> json) => _$CategoryAssociationsFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryAssociationsToJson(this);
}

@JsonSerializable()
class CategoryProductRef {
  @JsonKey(name: 'id')
  final int id;

  const CategoryProductRef({required this.id});

  factory CategoryProductRef.fromJson(Map<String, dynamic> json) => _$CategoryProductRefFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryProductRefToJson(this);
}

@JsonSerializable()
class CategoryImage {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'src')
  final String src;

  const CategoryImage({
    required this.id,
    required this.src,
  });

  factory CategoryImage.fromJson(Map<String, dynamic> json) => _$CategoryImageFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryImageToJson(this);
}