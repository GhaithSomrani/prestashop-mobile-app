# PrestaShop Mobile App - Implementation Examples

This document provides practical code examples for implementing all features of the PrestaShop mobile application.

## Table of Contents
- [PrestaShop Mobile App - Implementation Examples](#prestashop-mobile-app---implementation-examples)
  - [Table of Contents](#table-of-contents)
  - [1. Infinite Scroll Implementation](#1-infinite-scroll-implementation)
    - [Category Products Screen with Infinite Scroll](#category-products-screen-with-infinite-scroll)
  - [2. Dynamic Filter Implementation](#2-dynamic-filter-implementation)
    - [Using Dynamic Filters](#using-dynamic-filters)
  - [3. Product Detail Page with Combinations](#3-product-detail-page-with-combinations)
  - [4. Provider Setup in main.dart](#4-provider-setup-in-maindart)
  - [5. Key Implementation Points](#5-key-implementation-points)
    - [Infinite Scroll Pattern](#infinite-scroll-pattern)
    - [Dynamic Filter Pattern](#dynamic-filter-pattern)
    - [State Management Pattern](#state-management-pattern)
    - [Performance Optimization](#performance-optimization)

---

## 1. Infinite Scroll Implementation

### Category Products Screen with Infinite Scroll

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../widgets/product_card.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryProductsScreen({
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _currentSortBy;

  @override
  void initState() {
    super.initState();

    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProductsByCategory(
        widget.categoryId,
        reset: true,
      );
    });

    // Setup infinite scroll listener
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Trigger load more when 80% scrolled
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    final provider = context.read<ProductProvider>();
    if (!provider.isLoadingMore && provider.hasMore) {
      await provider.loadMoreCategoryProducts(
        widget.categoryId,
        sortBy: _currentSortBy,
      );
    }
  }

  Future<void> _refresh() async {
    await context.read<ProductProvider>().refreshProducts(
      categoryId: widget.categoryId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          // Sort button
          PopupMenuButton<String>(
            icon: Icon(Icons.sort),
            onSelected: (sortBy) {
              setState(() => _currentSortBy = sortBy);
              context.read<ProductProvider>().fetchProductsByCategory(
                widget.categoryId,
                sortBy: sortBy,
                reset: true,
              );
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'price_ASC', child: Text('Price: Low to High')),
              PopupMenuItem(value: 'price_DESC', child: Text('Price: High to Low')),
              PopupMenuItem(value: 'name_ASC', child: Text('Name: A-Z')),
              PopupMenuItem(value: 'name_DESC', child: Text('Name: Z-A')),
              PopupMenuItem(value: 'id_DESC', child: Text('Newest')),
            ],
          ),
          // Filter button
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => _showFilters(),
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (provider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.products.isEmpty) {
            return Center(child: Text('No products found'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: GridView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: provider.products.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.products.length) {
                  // Loading indicator at bottom
                  return Center(
                    child: provider.isLoadingMore
                        ? CircularProgressIndicator()
                        : SizedBox.shrink(),
                  );
                }

                final product = provider.products[index];
                return ProductCard(
                  product: product,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                          productId: product.id,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showFilters() {
    // Show filter bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FilterBottomSheet(
        categoryId: widget.categoryId,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
```

---

## 2. Dynamic Filter Implementation

### Using Dynamic Filters

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../services/filter_service.dart';

class DynamicFilterBottomSheet extends StatefulWidget {
  final String? categoryId;

  const DynamicFilterBottomSheet({this.categoryId});

  @override
  State<DynamicFilterBottomSheet> createState() => _DynamicFilterBottomSheetState();
}

class _DynamicFilterBottomSheetState extends State<DynamicFilterBottomSheet> {
  List<String> selectedBrands = [];
  List<String> selectedColors = [];
  List<String> selectedSizes = [];
  double minPrice = 0;
  double maxPrice = 1000;
  bool inStockOnly = false;
  bool onSaleOnly = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        final filterData = provider.filterData;

        if (filterData == null) {
          return Center(child: Text('Loading filters...'));
        }

        // Initialize price range from filter data
        if (minPrice == 0 && maxPrice == 1000) {
          minPrice = filterData.minPrice;
          maxPrice = filterData.maxPrice;
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedBrands.clear();
                        selectedColors.clear();
                        selectedSizes.clear();
                        minPrice = filterData.minPrice;
                        maxPrice = filterData.maxPrice;
                        inStockOnly = false;
                        onSaleOnly = false;
                      });
                    },
                    child: Text('Reset'),
                  ),
                ],
              ),

              Divider(),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price Range
                      _buildSectionTitle('Price Range'),
                      RangeSlider(
                        values: RangeValues(minPrice, maxPrice),
                        min: filterData.minPrice,
                        max: filterData.maxPrice,
                        divisions: 20,
                        labels: RangeLabels(
                          '${minPrice.toStringAsFixed(0)} TND',
                          '${maxPrice.toStringAsFixed(0)} TND',
                        ),
                        onChanged: (values) {
                          setState(() {
                            minPrice = values.start;
                            maxPrice = values.end;
                          });
                        },
                      ),

                      // Brands
                      if (filterData.brands.isNotEmpty) ...[
                        SizedBox(height: 16),
                        _buildSectionTitle('Brands'),
                        Wrap(
                          spacing: 8,
                          children: filterData.brands.map((brand) {
                            return FilterChip(
                              label: Text(brand),
                              selected: selectedBrands.contains(brand),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedBrands.add(brand);
                                  } else {
                                    selectedBrands.remove(brand);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],

                      // Colors
                      if (filterData.colors.isNotEmpty) ...[
                        SizedBox(height: 16),
                        _buildSectionTitle('Colors'),
                        Wrap(
                          spacing: 8,
                          children: filterData.colors.map((color) {
                            return FilterChip(
                              label: Text(color.name),
                              selected: selectedColors.contains(color.name),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedColors.add(color.name);
                                  } else {
                                    selectedColors.remove(color.name);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],

                      // Sizes
                      if (filterData.sizes.isNotEmpty) ...[
                        SizedBox(height: 16),
                        _buildSectionTitle('Sizes'),
                        Wrap(
                          spacing: 8,
                          children: filterData.sizes.map((size) {
                            return FilterChip(
                              label: Text(size),
                              selected: selectedSizes.contains(size),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedSizes.add(size);
                                  } else {
                                    selectedSizes.remove(size);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],

                      // Stock & Sale
                      SizedBox(height: 16),
                      CheckboxListTile(
                        title: Text('In Stock Only'),
                        value: inStockOnly,
                        onChanged: (value) => setState(() => inStockOnly = value ?? false),
                      ),
                      CheckboxListTile(
                        title: Text('On Sale'),
                        value: onSaleOnly,
                        onChanged: (value) => setState(() => onSaleOnly = value ?? false),
                      ),
                    ],
                  ),
                ),
              ),

              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Apply filters
                    provider.applyClientSideFilters(
                      selectedBrands: selectedBrands.isNotEmpty ? selectedBrands : null,
                      selectedColors: selectedColors.isNotEmpty ? selectedColors : null,
                      selectedSizes: selectedSizes.isNotEmpty ? selectedSizes : null,
                      minPrice: minPrice,
                      maxPrice: maxPrice,
                      inStockOnly: inStockOnly,
                      onSaleOnly: onSaleOnly,
                    );
                    Navigator.pop(context);
                  },
                  child: Text('Apply Filters'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}
```

---

## 3. Product Detail Page with Combinations

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/combination.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Combination? selectedCombination;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProductById(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          final product = provider.selectedProduct;
          if (product == null) {
            return Center(child: Text('Product not found'));
          }

          final combinations = provider.productCombinations;
          final features = provider.productFeatures;
          final relatedProducts = provider.relatedProducts;

          return CustomScrollView(
            slivers: [
              // Image Gallery
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: PageView.builder(
                    itemCount: product.images.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        product.images[index],
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        product.name,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),

                      SizedBox(height: 8),

                      // Brand
                      if (product.manufacturerName != null)
                        Text(
                          product.manufacturerName!,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),

                      SizedBox(height: 16),

                      // Price
                      Row(
                        children: [
                          if (product.isOnSale) ...[
                            Text(
                              '${product.price.toStringAsFixed(2)} TND',
                              style: TextStyle(
                                fontSize: 18,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '${product.finalPrice.toStringAsFixed(2)} TND',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-${product.calculatedDiscountPercentage.toStringAsFixed(0)}%',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ] else
                            Text(
                              '${product.finalPrice.toStringAsFixed(2)} TND',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Stock Status
                      Row(
                        children: [
                          Icon(
                            product.inStock ? Icons.check_circle : Icons.cancel,
                            color: product.inStock ? Colors.green : Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            product.inStock
                                ? 'In Stock (${product.quantity})'
                                : 'Out of Stock',
                            style: TextStyle(
                              color: product.inStock ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),

                      // Combinations (Variants)
                      if (combinations.isNotEmpty) ...[
                        SizedBox(height: 24),
                        Text(
                          'Options',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: combinations.map((combo) {
                            return ChoiceChip(
                              label: Text(combo.reference),
                              selected: selectedCombination?.id == combo.id,
                              onSelected: (selected) {
                                setState(() {
                                  selectedCombination = selected ? combo : null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],

                      // Quantity Selector
                      SizedBox(height: 24),
                      Row(
                        children: [
                          Text('Quantity:', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 16),
                          IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () {
                              if (quantity > 1) setState(() => quantity--);
                            },
                          ),
                          Text('$quantity', style: TextStyle(fontSize: 18)),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              setState(() => quantity++);
                            },
                          ),
                        ],
                      ),

                      // Add to Cart Button
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: product.inStock
                              ? () {
                                  // Add to cart logic
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Added to cart')),
                                  );
                                }
                              : null,
                          child: Text('Add to Cart'),
                        ),
                      ),

                      // Description
                      SizedBox(height: 24),
                      Text(
                        'Description',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(product.description),

                      // Features
                      if (features.isNotEmpty) ...[
                        SizedBox(height: 24),
                        Text(
                          'Specifications',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        ...features.map((feature) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(feature.featureName),
                                Text(feature.value, style: TextStyle(fontWeight: FontWeight.w500)),
                              ],
                            ),
                          );
                        }).toList(),
                      ],

                      // Related Products
                      if (relatedProducts.isNotEmpty) ...[
                        SizedBox(height: 32),
                        Text(
                          'Related Products',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          height: 250,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: relatedProducts.length,
                            itemBuilder: (context, index) {
                              final relatedProduct = relatedProducts[index];
                              return Container(
                                width: 150,
                                margin: EdgeInsets.only(right: 16),
                                child: ProductCard(product: relatedProduct),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

---

## 4. Provider Setup in main.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'services/product_service.dart';
import 'services/category_service.dart';
import 'services/customer_service.dart';
import 'services/filter_service.dart';
import 'providers/product_provider.dart';
import 'providers/category_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'config/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize API Service
  final apiService = ApiService(
    baseUrl: ApiConfig.baseUrl,
    apiKey: ApiConfig.apiKey,
  );

  // Initialize Services
  final productService = ProductService(apiService);
  final categoryService = CategoryService(apiService);
  final customerService = CustomerService(apiService);
  final filterService = FilterService(apiService);

  runApp(
    MultiProvider(
      providers: [
        // Services (if needed by multiple providers)
        Provider<ApiService>.value(value: apiService),

        // Providers
        ChangeNotifierProvider(
          create: (_) => ProductProvider(productService, filterService),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(categoryService),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(customerService),
        ),
        ChangeNotifierProvider(
          create: (_) => CartProvider(apiService),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PrestaShop Mobile App',
      theme: ThemeData(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: HomeScreen(),
    );
  }
}
```

---

## 5. Key Implementation Points

### Infinite Scroll Pattern
1. Use `ScrollController` to detect scroll position
2. Trigger load more at 80% scroll
3. Track `hasMore` flag to avoid unnecessary requests
4. Show loading indicator at bottom while loading
5. Handle errors gracefully

### Dynamic Filter Pattern
1. Fetch products first
2. Generate filters from fetched products
3. Display filters dynamically
4. Apply filters client-side or server-side
5. Reset pagination when filters change

### State Management Pattern
1. Use Provider for global state
2. Separate loading states (`isLoading` vs `isLoadingMore`)
3. Handle errors with retry mechanism
4. Implement pull-to-refresh
5. Clear state when navigating away

### Performance Optimization
1. Paginate with 20 items per load
2. Cache images with `cached_network_image`
3. Lazy load combinations and features
4. Debounce search input
5. Use const constructors where possible

---

This implementation provides a solid foundation for a production-ready PrestaShop mobile application with all the required features!
