import '../models/category.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class CategoryService {
  final ApiService _apiService;

  CategoryService(this._apiService);

  Future<List<Category>> getCategories({int? limit, int? offset}) async {
    try {
      final queryParams = <String, String>{
        'display': 'full',
        if (limit != null) 'limit': '$offset,$limit',
      };

      final response = await _apiService.get(
        ApiConfig.categoriesEndpoint,
        queryParameters: queryParams,
      );

      if (response['categories'] != null) {
        final categoriesData = response['categories'];
        if (categoriesData is List) {
          return categoriesData
              .map((categoryJson) => Category.fromJson(categoryJson))
              .toList();
        } else if (categoriesData is Map) {
          return [Category.fromJson(categoriesData as Map<String, dynamic>)];
        }
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  Future<Category> getCategoryById(String id) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.categoriesEndpoint}/$id',
        queryParameters: {'display': 'full'},
      );

      if (response['category'] != null) {
        return Category.fromJson(response['category']);
      }

      throw Exception('Category not found');
    } catch (e) {
      throw Exception('Failed to fetch category: $e');
    }
  }

  Future<List<Category>> getRootCategories() async {
    // Get categories with parent ID 2 (typically root categories in PrestaShop)
    try {
      final queryParams = <String, String>{
        'display': 'full',
        'filter[id_parent]': '2',
      };

      final response = await _apiService.get(
        ApiConfig.categoriesEndpoint,
        queryParameters: queryParams,
      );

      if (response['categories'] != null) {
        final categoriesData = response['categories'];
        if (categoriesData is List) {
          return categoriesData
              .map((categoryJson) => Category.fromJson(categoryJson))
              .toList();
        } else if (categoriesData is Map) {
          return [Category.fromJson(categoriesData as Map<String, dynamic>)];
        }
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch root categories: $e');
    }
  }

  /// Get subcategories for a given parent category ID
  Future<List<Category>> getSubcategories(String parentId) async {
    try {
      final queryParams = <String, String>{
        'display': 'full',
        'filter[id_parent]': parentId,
        'filter[active]': '1', // Only active categories
      };

      final response = await _apiService.get(
        ApiConfig.categoriesEndpoint,
        queryParameters: queryParams,
      );

      if (response['categories'] != null) {
        final categoriesData = response['categories'];
        if (categoriesData is List) {
          return categoriesData
              .map((categoryJson) => Category.fromJson(categoryJson))
              .toList();
        } else if (categoriesData is Map) {
          return [Category.fromJson(categoriesData as Map<String, dynamic>)];
        }
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch subcategories: $e');
    }
  }

  /// Get full category tree with subcategories
  Future<Map<String, List<Category>>> getCategoryTree() async {
    try {
      final allCategories = await getCategories();
      final Map<String, List<Category>> tree = {};

      for (var category in allCategories) {
        final parentId = category.parentId ?? '0';
        if (!tree.containsKey(parentId)) {
          tree[parentId] = [];
        }
        tree[parentId]!.add(category);
      }

      return tree;
    } catch (e) {
      throw Exception('Failed to build category tree: $e');
    }
  }

  /// Check if a category has subcategories
  Future<bool> hasSubcategories(String categoryId) async {
    try {
      final subcategories = await getSubcategories(categoryId);
      return subcategories.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
