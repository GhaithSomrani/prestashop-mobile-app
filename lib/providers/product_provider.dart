import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/combination.dart';
import '../models/feature.dart';
import '../services/product_service.dart';
import '../services/filter_service.dart';
import '../config/api_config.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService;
  final FilterService _filterService;

  ProductProvider(this._productService, this._filterService);

  // Product lists
  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  List<Product> _latestProducts = [];
  List<Product> _relatedProducts = [];
  Product? _selectedProduct;

  // Combinations and features for selected product
  List<Combination> _productCombinations = [];
  List<ProductFeature> _productFeatures = [];

  // Pagination state
  int _currentOffset = 0;
  final int _pageSize = ApiConfig.defaultLimit; // 20 products per page
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // Filter state
  DynamicFilterData? _filterData;

  // Loading and error states
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Product> get products => _products;
  List<Product> get featuredProducts => _featuredProducts;
  List<Product> get latestProducts => _latestProducts;
  List<Product> get relatedProducts => _relatedProducts;
  Product? get selectedProduct => _selectedProduct;
  List<Combination> get productCombinations => _productCombinations;
  List<ProductFeature> get productFeatures => _productFeatures;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  bool get hasError => _error != null;
  DynamicFilterData? get filterData => _filterData;

  /// Fetch products with pagination support (initial load)
  Future<void> fetchProducts({
    String? categoryId,
    String? searchQuery,
    String? manufacturerId,
    double? minPrice,
    double? maxPrice,
    bool filterInStock = true,
    String? sortBy,
    bool reset = true,
  }) async {
    if (reset) {
      _isLoading = true;
      _currentOffset = 0;
      _hasMore = true;
      _products = [];
    }

    _error = null;
    notifyListeners();

    try {
      final newProducts = await _productService.getProducts(
        limit: _pageSize,
        offset: _currentOffset,
        categoryId: categoryId,
        searchQuery: searchQuery,
        manufacturerId: manufacturerId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        filterInStock: filterInStock,
        sortBy: sortBy,
      );

      if (reset) {
        _products = newProducts;
      } else {
        _products.addAll(newProducts);
      }

      // Update offset for next load
      _currentOffset += _pageSize;

      // Check if there are more products
      if (newProducts.length < _pageSize) {
        _hasMore = false;
      }

      // Generate filters from products
      if (reset && _products.isNotEmpty) {
        _filterData = await _filterService.generateFiltersFromProducts(_products);
      }

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

  /// Load more products (for infinite scroll)
  Future<void> loadMoreProducts({
    String? categoryId,
    String? searchQuery,
    String? manufacturerId,
    double? minPrice,
    double? maxPrice,
    bool filterInStock = true,
    String? sortBy,
  }) async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final newProducts = await _productService.getProducts(
        limit: _pageSize,
        offset: _currentOffset,
        categoryId: categoryId,
        searchQuery: searchQuery,
        manufacturerId: manufacturerId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        filterInStock: filterInStock,
        sortBy: sortBy,
      );

      _products.addAll(newProducts);
      _currentOffset += _pageSize;

      // Check if there are more products
      if (newProducts.length < _pageSize) {
        _hasMore = false;
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading more products: $e');
      }
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Fetch products by category with pagination
  Future<void> fetchProductsByCategory(
    String categoryId, {
    bool filterInStock = true,
    String? sortBy,
    bool reset = true,
  }) async {
    return fetchProducts(
      categoryId: categoryId,
      filterInStock: filterInStock,
      sortBy: sortBy,
      reset: reset,
    );
  }

  /// Load more products for category
  Future<void> loadMoreCategoryProducts(
    String categoryId, {
    bool filterInStock = true,
    String? sortBy,
  }) async {
    return loadMoreProducts(
      categoryId: categoryId,
      filterInStock: filterInStock,
      sortBy: sortBy,
    );
  }

  /// Search products with pagination
  Future<void> searchProducts(
    String query, {
    bool reset = true,
  }) async {
    if (query.isEmpty) {
      _products = [];
      _currentOffset = 0;
      _hasMore = true;
      notifyListeners();
      return;
    }

    return fetchProducts(
      searchQuery: query,
      reset: reset,
    );
  }

  /// Load more search results
  Future<void> loadMoreSearchResults(String query) async {
    return loadMoreProducts(searchQuery: query);
  }

  /// Fetch featured products
  Future<void> fetchFeaturedProducts() async {
    try {
      _featuredProducts = await _productService.getFeaturedProducts(limit: 10);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching featured products: $e');
      }
    }
  }

  /// Fetch latest products
  Future<void> fetchLatestProducts() async {
    try {
      _latestProducts = await _productService.getLatestProducts(limit: 10);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching latest products: $e');
      }
    }
  }

  /// Fetch product by ID with all details
  Future<void> fetchProductById(String id) async {
    _isLoading = true;
    _error = null;
    _productCombinations = [];
    _productFeatures = [];
    notifyListeners();

    try {
      _selectedProduct = await _productService.getProductById(id);

      // Fetch combinations if product has variants
      if (_selectedProduct!.defaultCombinationId != null) {
        _productCombinations = await _productService.getProductCombinationsAsCombinationModels(id);
      }

      // Fetch product features
      _productFeatures = await _productService.getProductFeatures(id);

      // Fetch related products
      if (_selectedProduct!.categoryId != '0') {
        _relatedProducts = await _productService.getRelatedProducts(
          id,
          _selectedProduct!.categoryId,
          limit: 10,
        );
      }

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

  /// Apply filters to current product list
  void applyClientSideFilters({
    List<String>? selectedBrands,
    List<String>? selectedColors,
    List<String>? selectedSizes,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    bool? onSaleOnly,
  }) {
    final allProducts = List<Product>.from(_products);
    _products = _filterService.applyFilters(
      allProducts,
      selectedBrands: selectedBrands,
      selectedColors: selectedColors,
      selectedSizes: selectedSizes,
      minPrice: minPrice,
      maxPrice: maxPrice,
      inStockOnly: inStockOnly,
      onSaleOnly: onSaleOnly,
    );
    notifyListeners();
  }

  /// Sort products
  void sortProducts(String sortBy) {
    _products = _filterService.sortProducts(_products, sortBy);
    notifyListeners();
  }

  /// Generate dynamic filters for current products
  Future<void> generateFilters() async {
    if (_products.isEmpty) return;

    try {
      _filterData = await _filterService.generateFiltersFromProducts(_products);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error generating filters: $e');
      }
    }
  }

  /// Reset pagination
  void resetPagination() {
    _currentOffset = 0;
    _hasMore = true;
    _products = [];
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear selected product
  void clearSelectedProduct() {
    _selectedProduct = null;
    _productCombinations = [];
    _productFeatures = [];
    _relatedProducts = [];
    notifyListeners();
  }

  /// Clear all products
  void clearProducts() {
    _products = [];
    _currentOffset = 0;
    _hasMore = true;
    notifyListeners();
  }

  /// Refresh products (pull to refresh)
  Future<void> refreshProducts({
    String? categoryId,
    String? searchQuery,
  }) async {
    return fetchProducts(
      categoryId: categoryId,
      searchQuery: searchQuery,
      reset: true,
    );
  }
}
