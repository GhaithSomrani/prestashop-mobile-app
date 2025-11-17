import 'package:flutter/foundation.dart';
import '../models/category.dart';
import '../services/category_service.dart';

class CategoryProvider with ChangeNotifier {
  final CategoryService _categoryService;

  CategoryProvider(this._categoryService);

  List<Category> _categories = [];
  Category? _selectedCategory;
  bool _isLoading = false;
  String? _error;

  List<Category> get categories => _categories;
  Category? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _categoryService.getRootCategories();
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error fetching categories: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCategoryById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedCategory = await _categoryService.getCategoryById(id);
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error fetching category: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCategory(Category category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void clearSelectedCategory() {
    _selectedCategory = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
