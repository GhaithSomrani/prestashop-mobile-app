import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService;

  ProductProvider(this._productService);

  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  Product? _selectedProduct;
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  List<Product> get featuredProducts => _featuredProducts;
  Product? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  Future<void> fetchProducts({
    int? limit,
    int? offset,
    String? categoryId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _productService.getProducts(
        limit: limit,
        offset: offset,
        categoryId: categoryId,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error fetching products: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFeaturedProducts() async {
    try {
      _featuredProducts = await _productService.getFeaturedProducts();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching featured products: $e');
      }
    }
  }

  Future<void> fetchProductById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedProduct = await _productService.getProductById(id);
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error fetching product: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      _products = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _productService.searchProducts(query);
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error searching products: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProductsByCategory(String categoryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _productService.getProductsByCategory(categoryId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error fetching products by category: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSelectedProduct() {
    _selectedProduct = null;
    notifyListeners();
  }
}
