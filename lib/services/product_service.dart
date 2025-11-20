import '../models/product.dart';
import '../models/combination.dart';
import '../models/specific_price.dart';
import '../models/feature.dart';
import '../config/api_config.dart';
import 'api_service.dart';

/// Service for managing PrestaShop products with complete JSON API integration
/// Follows the specification for combining products, stock, combinations, categories, and specific prices
class ProductService {
  final ApiService _apiService;

  ProductService(this._apiService);

  // ============================================================================
  // 🔵 1. FETCH PRODUCT IDS (PAGINATED, JSON)
  // ============================================================================

  /// Fetch paginated product IDs using JSON format
  ///
  /// Endpoint: /products?output_format=JSON&display=[id,id_default_category]&limit=20&offset={page*20}
  ///
  /// Returns a list of product IDs only
  Future<List<String>> getProductIds({
    int page = 0,
    int limit = 20,
    String? categoryId,
  }) async {
    try {
      final offset = page * limit;
      final queryParams = <String, String>{
        'display': '[id,id_default_category]',
        'limit': '$offset,$limit',
        'filter[active]': '1',
        if (categoryId != null) 'filter[id_category_default]': categoryId,
      };

      final response = await _apiService.get(
        ApiConfig.productsEndpoint,
        queryParameters: queryParams,
      );

      final List<String> productIds = [];

      if (response is List) {
        for (var item in response) {
          final id = item['id']?.toString();
          if (id != null) productIds.add(id);
        }
      } else if (response is Map && response['products'] != null) {
        final productsData = response['products'];
        if (productsData is List) {
          for (var item in productsData) {
            final id = item['id']?.toString();
            if (id != null) productIds.add(id);
          }
        } else if (productsData is Map) {
          final id = productsData['id']?.toString();
          if (id != null) productIds.add(id);
        }
      }

      return productIds;
    } catch (e) {
      throw Exception('Failed to fetch product IDs: $e');
    }
  }

  // ============================================================================
  // 🔵 2. FETCH FULL PRODUCT DETAILS (JSON)
  // ============================================================================

  /// Fetch full product details for a specific product
  ///
  /// Endpoint: /products/{id}?output_format=JSON&display=full
  ///
  /// Extracts: name, base price, images, default category, associations.categories, associations.combinations
  Future<Map<String, dynamic>> getProductDetails(String id) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.productsEndpoint}/$id',
        queryParameters: {'display': 'full'},
      );

      if (response['product'] != null) {
        return response['product'] as Map<String, dynamic>;
      } else if (response is Map) {
        return response as Map<String, dynamic>;
      }

      throw Exception('Product not found');
    } catch (e) {
      throw Exception('Failed to fetch product details: $e');
    }
  }

  // ============================================================================
  // 🔵 3. FETCH PRODUCT STOCK (JSON)
  // ============================================================================

  /// Fetch stock for a product (base product without combinations)
  ///
  /// Endpoint: /stock_availables?output_format=JSON&filter[id_product]={id}&filter[id_product_attribute]=0
  ///
  /// Rules:
  /// - If quantity > 0 → product has stock
  /// - If product has no combinations and quantity = 0 → exclude product
  Future<int> getProductStock(String id) async {
    try {
      final response = await _apiService.get(
        ApiConfig.stockAvailablesEndpoint,
        queryParameters: {
          'display': '[quantity]',
          'filter[id_product]': id,
          'filter[id_product_attribute]': '0',
        },
      );

      if (response['stock_availables'] != null) {
        final stockData = response['stock_availables'];
        if (stockData is List && stockData.isNotEmpty) {
          return _parseQuantity(stockData[0]['quantity']);
        } else if (stockData is Map) {
          return _parseQuantity(stockData['quantity']);
        }
      }

      return 0;
    } catch (e) {
      print('Warning: Failed to fetch stock for product $id: $e');
      return 0;
    }
  }

  // ============================================================================
  // 🔵 4. FETCH COMBINATIONS USING JSON
  // ============================================================================

  /// Fetch product combinations with their stock levels
  ///
  /// Endpoint: /combinations?output_format=JSON&filter[id_product]={id}&limit=50&offset=0
  /// Then: /stock_availables?output_format=JSON&filter[id_product]={id}&filter[id_product_attribute]={comb_id}
  ///
  /// Rules:
  /// - Keep only combinations with quantity > 0
  /// - If all combination stocks = 0 → exclude entire product
  Future<List<Map<String, dynamic>>> getProductCombinations(String productId) async {
    try {
      // Step 1: Fetch combinations
      final combinationsResponse = await _apiService.get(
        ApiConfig.combinationsEndpoint,
        queryParameters: {
          'display': 'full',
          'filter[id_product]': productId,
          'limit': '0,50',
        },
      );

      List<Map<String, dynamic>> combinations = [];

      if (combinationsResponse['combinations'] != null) {
        final combData = combinationsResponse['combinations'];
        if (combData is List) {
          combinations = combData.map((c) => c as Map<String, dynamic>).toList();
        } else if (combData is Map) {
          combinations = [combData as Map<String, dynamic>];
        }
      }

      if (combinations.isEmpty) {
        return [];
      }

      // Step 2: Fetch stock for each combination
      final combinationsWithStock = <Map<String, dynamic>>[];

      for (var combination in combinations) {
        final combId = combination['id']?.toString();
        if (combId == null) continue;

        // Fetch stock for this combination
        final stockResponse = await _apiService.get(
          ApiConfig.stockAvailablesEndpoint,
          queryParameters: {
            'display': '[quantity]',
            'filter[id_product]': productId,
            'filter[id_product_attribute]': combId,
          },
        );

        int quantity = 0;
        if (stockResponse['stock_availables'] != null) {
          final stockData = stockResponse['stock_availables'];
          if (stockData is List && stockData.isNotEmpty) {
            quantity = _parseQuantity(stockData[0]['quantity']);
          } else if (stockData is Map) {
            quantity = _parseQuantity(stockData['quantity']);
          }
        }

        // Only include combinations with stock > 0
        if (quantity > 0) {
          combination['stock'] = quantity;
          combinationsWithStock.add(combination);
        }
      }

      return combinationsWithStock;
    } catch (e) {
      print('Warning: Failed to fetch combinations for product $productId: $e');
      return [];
    }
  }

  // ============================================================================
  // 🔵 5. FETCH SPECIFIC PRICES (JSON)
  // ============================================================================

  /// Fetch specific prices (discounts) for a product
  ///
  /// Endpoint: /specific_prices?output_format=JSON&filter[id_product]={id}&limit=20
  ///
  /// Computes:
  /// - Reduction type detection
  /// - final_price = base_price - reduction
  /// - Date conditions
  /// - Quantity conditions
  Future<List<SpecificPrice>> getProductSpecificPrices(String productId) async {
    try {
      final response = await _apiService.get(
        ApiConfig.specificPricesEndpoint,
        queryParameters: {
          'display': 'full',
          'filter[id_product]': productId,
          'limit': '0,20',
        },
      );

      List<SpecificPrice> prices = [];

      if (response['specific_prices'] != null) {
        final pricesData = response['specific_prices'];
        if (pricesData is List) {
          prices = pricesData
              .map((priceJson) => SpecificPrice.fromJson(priceJson as Map<String, dynamic>))
              .toList();
        } else if (pricesData is Map) {
          prices = [SpecificPrice.fromJson(pricesData as Map<String, dynamic>)];
        }
      }

      // Filter only active prices (based on date conditions)
      return prices.where((price) => price.isActive).toList();
    } catch (e) {
      print('Warning: Failed to fetch specific prices for product $productId: $e');
      return [];
    }
  }

  // ============================================================================
  // 🔵 6. FETCH CATEGORIES (JSON)
  // ============================================================================

  /// Fetch category details if needed
  ///
  /// Endpoint: /categories/{id}?output_format=JSON&display=full
  Future<Map<String, dynamic>?> getCategoryDetails(String categoryId) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.categoriesEndpoint}/$categoryId',
        queryParameters: {'display': 'full'},
      );

      if (response['category'] != null) {
        return response['category'] as Map<String, dynamic>;
      } else if (response is Map) {
        return response as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      print('Warning: Failed to fetch category $categoryId: $e');
      return null;
    }
  }

  // ============================================================================
  // 🔵 7. FINAL JSON OBJECT ASSEMBLY
  // ============================================================================

  /// Build a unified product object combining all data
  ///
  /// Final object structure:
  /// ```json
  /// {
  ///   "id": ID,
  ///   "name": "Product Name",
  ///   "default_category": CATEGORY_ID,
  ///   "categories": [...],
  ///   "price": PRICE,
  ///   "final_price": FINAL_PRICE,
  ///   "stock": STOCK_QTY,
  ///   "combinations": [
  ///     {
  ///       "id": COMB_ID,
  ///       "attributes": [...],
  ///       "price": PRICE,
  ///       "final_price": FINAL,
  ///       "stock": QTY
  ///     }
  ///   ]
  /// }
  /// ```
  Future<Map<String, dynamic>?> buildUnifiedProduct(String productId) async {
    try {
      // Step 1: Get product details
      final productDetails = await getProductDetails(productId);

      // Step 2: Get product stock (base product)
      final productStock = await getProductStock(productId);

      // Step 3: Get combinations with stock
      final combinations = await getProductCombinations(productId);

      // Step 4: Get specific prices
      final specificPrices = await getProductSpecificPrices(productId);

      // Step 5: Filter logic - exclude if no stock
      // If product has combinations, check if any combination has stock
      // If product has no combinations, check if base product has stock
      if (combinations.isNotEmpty) {
        // Product has combinations - exclude if all combinations have 0 stock
        if (combinations.isEmpty) {
          return null; // All combinations filtered out due to 0 stock
        }
      } else {
        // Product has no combinations - exclude if base stock is 0
        if (productStock <= 0) {
          return null; // No stock for base product
        }
      }

      // Step 6: Extract product information
      final productName = _extractName(productDetails['name']);
      final basePrice = _parsePrice(productDetails['price']);
      final defaultCategory = productDetails['id_default_category']?.toString() ?? '0';

      // Extract categories
      final categories = _extractCategories(productDetails);

      // Extract images
      final images = _extractImages(productDetails);

      // Step 7: Calculate final price for base product
      double finalPrice = basePrice;
      if (specificPrices.isNotEmpty) {
        // Find price applicable to base product (id_product_attribute = null or 0)
        final baseProductPrice = specificPrices.firstWhere(
          (sp) => sp.idProductAttribute == null || sp.idProductAttribute == '0',
          orElse: () => specificPrices.first,
        );
        finalPrice = baseProductPrice.calculateFinalPrice(basePrice);
      }

      // Step 8: Build combinations array with pricing
      final combinationsArray = combinations.map((comb) {
        final combId = comb['id']?.toString() ?? '';
        final priceImpact = _parsePrice(comb['price'] ?? 0);
        final combBasePrice = basePrice + priceImpact;
        final combStock = comb['stock'] as int? ?? 0;

        // Find specific price for this combination
        double combFinalPrice = combBasePrice;
        if (specificPrices.isNotEmpty) {
          final combSpecificPrice = specificPrices.firstWhere(
            (sp) => sp.idProductAttribute == combId,
            orElse: () => specificPrices.first,
          );
          combFinalPrice = combSpecificPrice.calculateFinalPrice(combBasePrice);
        }

        // Extract attributes
        final attributes = _extractCombinationAttributes(comb);

        return {
          'id': combId,
          'attributes': attributes,
          'price': combBasePrice,
          'final_price': combFinalPrice,
          'stock': combStock,
        };
      }).toList();

      // Step 9: Build final unified object
      return {
        'id': productId,
        'name': productName,
        'default_category': defaultCategory,
        'categories': categories,
        'images': images,
        'price': basePrice,
        'final_price': finalPrice,
        'stock': productStock,
        'combinations': combinationsArray,
        'description': productDetails['description']?.toString() ?? '',
        'description_short': productDetails['description_short']?.toString() ?? '',
        'reference': productDetails['reference']?.toString() ?? '',
      };
    } catch (e) {
      print('Warning: Failed to build unified product for $productId: $e');
      return null;
    }
  }

  // ============================================================================
  // 🔵 8. GET PRODUCTS WITH PAGINATION AND FILTERING
  // ============================================================================

  /// Get products with pagination, fully enriched with stock, combinations, and pricing
  ///
  /// This is the main entry point for fetching products (returns Product models)
  Future<List<Product>> getProducts({
    int? limit,
    int? offset,
    String? categoryId,
    String? searchQuery,
    String? manufacturerId,
    double? minPrice,
    double? maxPrice,
    bool filterInStock = true,
    String? sortBy,
  }) async {
    try {
      // Calculate page from offset
      final page = offset != null && limit != null ? offset ~/ limit : 0;
      final effectiveLimit = limit ?? 20;

      // Get raw product maps
      final productMaps = await getProductsRaw(
        page: page,
        limit: effectiveLimit,
        categoryId: categoryId,
        searchQuery: searchQuery,
        manufacturerId: manufacturerId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        sortBy: sortBy,
      );

      // Convert to Product models
      return productMaps.map((map) => _convertMapToProduct(map)).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  /// Get products as raw Map objects (internal method for advanced use)
  Future<List<Map<String, dynamic>>> getProductsRaw({
    int page = 0,
    int limit = 20,
    String? categoryId,
    String? searchQuery,
    String? manufacturerId,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
  }) async {
    try {
      // If search query is provided, use search endpoint
      if (searchQuery != null && searchQuery.isNotEmpty) {
        return await searchProductsRaw(searchQuery, page: page, limit: limit);
      }

      // Step 1: Get product IDs (paginated)
      final productIds = await getProductIds(
        page: page,
        limit: limit,
        categoryId: categoryId,
      );

      if (productIds.isEmpty) {
        return [];
      }

      // Step 2: Build unified product objects for each ID
      final products = <Map<String, dynamic>>[];

      for (var productId in productIds) {
        final unifiedProduct = await buildUnifiedProduct(productId);
        if (unifiedProduct != null) {
          products.add(unifiedProduct);
        }
      }

      // Apply additional filters (manufacturer, price range) since API doesn't support all filters
      var filteredProducts = products;

      if (manufacturerId != null) {
        filteredProducts = filteredProducts.where((p) {
          final prodDetails = p;
          return prodDetails['id_manufacturer']?.toString() == manufacturerId;
        }).toList();
      }

      if (minPrice != null || maxPrice != null) {
        filteredProducts = filteredProducts.where((p) {
          final price = p['final_price'] as double;
          if (minPrice != null && price < minPrice) return false;
          if (maxPrice != null && price > maxPrice) return false;
          return true;
        }).toList();
      }

      return filteredProducts;
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  /// Get single product by ID with full details (returns Product model)
  Future<Product?> getProductById(String id) async {
    final map = await buildUnifiedProduct(id);
    if (map == null) return null;
    return _convertMapToProduct(map);
  }

  /// Search products by name (returns Product models)
  Future<List<Product>> searchProducts(
    String query, {
    int page = 0,
    int limit = 20,
  }) async {
    final maps = await searchProductsRaw(query, page: page, limit: limit);
    return maps.map((map) => _convertMapToProduct(map)).toList();
  }

  /// Search products by name (returns raw maps)
  Future<List<Map<String, dynamic>>> searchProductsRaw(
    String query, {
    int page = 0,
    int limit = 20,
  }) async {
    try {
      final offset = page * limit;
      final queryParams = <String, String>{
        'display': '[id]',
        'limit': '$offset,$limit',
        'filter[active]': '1',
        'filter[name]': '%$query%',
      };

      final response = await _apiService.get(
        ApiConfig.productsEndpoint,
        queryParameters: queryParams,
      );

      final List<String> productIds = [];

      if (response is List) {
        for (var item in response) {
          final id = item['id']?.toString();
          if (id != null) productIds.add(id);
        }
      } else if (response is Map && response['products'] != null) {
        final productsData = response['products'];
        if (productsData is List) {
          for (var item in productsData) {
            final id = item['id']?.toString();
            if (id != null) productIds.add(id);
          }
        } else if (productsData is Map) {
          final id = productsData['id']?.toString();
          if (id != null) productIds.add(id);
        }
      }

      // Build unified products
      final products = <Map<String, dynamic>>[];
      for (var productId in productIds) {
        final unifiedProduct = await buildUnifiedProduct(productId);
        if (unifiedProduct != null) {
          products.add(unifiedProduct);
        }
      }

      return products;
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  /// Get featured products (first N products sorted by ID DESC)
  Future<List<Product>> getFeaturedProducts({int limit = 10}) async {
    final maps = await getProductsRaw(page: 0, limit: limit, sortBy: 'id_DESC');
    return maps.map((map) => _convertMapToProduct(map)).toList();
  }

  /// Get latest products (newest first)
  Future<List<Product>> getLatestProducts({int limit = 10}) async {
    final maps = await getProductsRaw(page: 0, limit: limit, sortBy: 'id_DESC');
    return maps.map((map) => _convertMapToProduct(map)).toList();
  }

  /// Get product combinations as Combination models
  Future<List<Combination>> getProductCombinationsAsCombinationModels(String productId) async {
    try {
      final combinationMaps = await getProductCombinations(productId);

      return combinationMaps.map((combMap) {
        return Combination(
          id: combMap['id']?.toString() ?? '',
          idProduct: productId,
          reference: combMap['reference']?.toString() ?? '',
          priceImpact: _parsePrice(combMap['price'] ?? 0),
          quantity: combMap['stock'] as int? ?? 0,
          defaultOn: combMap['default_on'] == '1' || combMap['default_on'] == true,
          attributes: [], // Attributes would need additional API calls to resolve names
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch combinations: $e');
    }
  }

  /// Get product features (stub - requires feature service integration)
  Future<List<ProductFeature>> getProductFeatures(String productId) async {
    // This would require additional API calls to features endpoint
    // For now, return empty list to prevent errors
    return [];
  }

  /// Get related products (same category, different product)
  Future<List<Product>> getRelatedProducts(
    String productId,
    String categoryId, {
    int limit = 10,
  }) async {
    try {
      final maps = await getProductsRaw(
        categoryId: categoryId,
        limit: limit + 5,
      );

      // Filter out current product
      final relatedMaps = maps.where((m) => m['id']?.toString() != productId).toList();

      // Return only requested limit
      final limitedMaps = relatedMaps.take(limit).toList();

      return limitedMaps.map((map) => _convertMapToProduct(map)).toList();
    } catch (e) {
      throw Exception('Failed to fetch related products: $e');
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Parse quantity from dynamic value
  int _parseQuantity(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  /// Parse price from dynamic value
  double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  /// Extract product name from multilingual field
  String _extractName(dynamic nameField) {
    if (nameField == null) return '';
    if (nameField is String) return nameField;
    if (nameField is Map) {
      // PrestaShop multilingual field
      if (nameField['language'] != null) {
        if (nameField['language'] is List) {
          final languages = nameField['language'] as List;
          if (languages.isNotEmpty) {
            return languages[0]['value']?.toString() ?? '';
          }
        } else if (nameField['language'] is Map) {
          return nameField['language']['value']?.toString() ?? '';
        }
      }
    }
    return nameField.toString();
  }

  /// Extract categories from product associations
  List<String> _extractCategories(Map<String, dynamic> productDetails) {
    final categories = <String>[];

    if (productDetails['associations'] != null &&
        productDetails['associations']['categories'] != null) {
      final categoriesData = productDetails['associations']['categories'];

      if (categoriesData is List) {
        for (var cat in categoriesData) {
          final catId = cat['id']?.toString();
          if (catId != null) categories.add(catId);
        }
      } else if (categoriesData is Map && categoriesData['category'] != null) {
        final catData = categoriesData['category'];
        if (catData is List) {
          for (var cat in catData) {
            final catId = cat['id']?.toString();
            if (catId != null) categories.add(catId);
          }
        } else if (catData is Map) {
          final catId = catData['id']?.toString();
          if (catId != null) categories.add(catId);
        }
      }
    }

    return categories;
  }

  /// Extract images from product
  List<String> _extractImages(Map<String, dynamic> productDetails) {
    final images = <String>[];

    if (productDetails['associations'] != null &&
        productDetails['associations']['images'] != null) {
      final imagesData = productDetails['associations']['images'];

      if (imagesData is List) {
        for (var img in imagesData) {
          final imgId = img['id']?.toString();
          if (imgId != null) {
            images.add(imgId);
          }
        }
      } else if (imagesData is Map && imagesData['image'] != null) {
        final imgData = imagesData['image'];
        if (imgData is List) {
          for (var img in imgData) {
            final imgId = img['id']?.toString();
            if (imgId != null) images.add(imgId);
          }
        } else if (imgData is Map) {
          final imgId = imgData['id']?.toString();
          if (imgId != null) images.add(imgId);
        }
      }
    }

    return images;
  }

  /// Extract combination attributes
  List<Map<String, dynamic>> _extractCombinationAttributes(Map<String, dynamic> combination) {
    final attributes = <Map<String, dynamic>>[];

    if (combination['associations'] != null &&
        combination['associations']['product_option_values'] != null) {
      final optionValues = combination['associations']['product_option_values'];

      if (optionValues is List) {
        for (var opt in optionValues) {
          attributes.add({
            'id': opt['id']?.toString() ?? '',
          });
        }
      } else if (optionValues is Map && optionValues['product_option_value'] != null) {
        final optData = optionValues['product_option_value'];
        if (optData is List) {
          for (var opt in optData) {
            attributes.add({
              'id': opt['id']?.toString() ?? '',
            });
          }
        } else if (optData is Map) {
          attributes.add({
            'id': optData['id']?.toString() ?? '',
          });
        }
      }
    }

    return attributes;
  }

  /// Convert unified product map to Product model
  Product _convertMapToProduct(Map<String, dynamic> map) {
    final basePrice = _parsePrice(map['price']);
    final finalPrice = _parsePrice(map['final_price']);
    final hasDiscount = finalPrice < basePrice;
    final discountPercentage = hasDiscount ? ((basePrice - finalPrice) / basePrice * 100) : 0.0;

    // Build image URLs from image IDs
    final imageIds = map['images'] as List? ?? [];
    final productId = map['id']?.toString() ?? '';
    final imageUrls = imageIds.map((imgId) => imgId.toString()).toList();

    return Product(
      id: productId,
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      shortDescription: map['description_short']?.toString() ?? '',
      price: basePrice,
      reducedPrice: hasDiscount ? finalPrice : null,
      imageUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
      images: imageUrls,
      quantity: map['stock'] as int? ?? 0,
      reference: map['reference']?.toString(),
      active: true,
      categoryId: map['default_category']?.toString() ?? '0',
      onSale: hasDiscount,
      discountPercentage: hasDiscount ? discountPercentage : null,
    );
  }
}
