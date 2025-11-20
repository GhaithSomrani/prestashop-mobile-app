# Developer Guide

Technical guide for developers working on the PrestaShop Mobile App.

---

## Table of Contents

1. [Development Setup](#development-setup)
2. [Project Architecture](#project-architecture)
3. [State Management](#state-management)
4. [Adding New Features](#adding-new-features)
5. [Code Style & Standards](#code-style--standards)
6. [Testing](#testing)
7. [Debugging](#debugging)
8. [Performance Optimization](#performance-optimization)
9. [Common Tasks](#common-tasks)

---

## Development Setup

### Initial Setup

1. **Install Flutter**
   ```bash
   # Verify installation
   flutter doctor
   ```

2. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd prestashop-mobile-app
   ```

3. **Install Dependencies**
   ```bash
   flutter pub get
   ```

4. **Configure Environment**

   Create `.env` file:
   ```env
   PRESTASHOP_API_URL=https://test.lamode.tn/api
   PRESTASHOP_API_KEY=YOUR_API_KEY_HERE
   ```

5. **Run the App**
   ```bash
   # Debug mode
   flutter run

   # With hot reload enabled
   flutter run --hot
   ```

### IDE Setup

**VS Code:**
- Install "Flutter" extension
- Install "Dart" extension
- Enable format on save in settings.json:
  ```json
  {
    "editor.formatOnSave": true,
    "[dart]": {
      "editor.formatOnSave": true,
      "editor.rulers": [80]
    }
  }
  ```

**Android Studio:**
- Install Flutter plugin
- Install Dart plugin
- Enable "Format code on save"

---

## Project Architecture

### Layer Structure

```
┌─────────────────────────────────────┐
│          Presentation Layer         │
│  (Screens, Widgets, UI Components)  │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│      State Management Layer         │
│    (Providers with ChangeNotifier)  │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│        Business Logic Layer         │
│    (Services, Data Processing)      │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│          Data Layer                 │
│   (Models, API Service, Storage)    │
└─────────────────────────────────────┘
```

### Folder Organization

**Models** (`lib/models/`)
- Data structures representing entities
- JSON serialization/deserialization
- Business logic helpers (e.g., calculated fields)

**Services** (`lib/services/`)
- API communication
- Data transformation
- External integrations

**Providers** (`lib/providers/`)
- State management
- Business logic orchestration
- UI state updates

**Screens** (`lib/screens/`)
- Full-page views
- Screen-level state
- Navigation logic

**Widgets** (`lib/widgets/`)
- Reusable UI components
- Stateless when possible
- Configurable via parameters

---

## State Management

### Provider Pattern

The app uses **Provider** for state management with the **ChangeNotifier** pattern.

### Creating a New Provider

1. **Create Provider Class**

```dart
// lib/providers/example_provider.dart
import 'package:flutter/foundation.dart';
import '../services/example_service.dart';
import '../models/example.dart';

class ExampleProvider with ChangeNotifier {
  final ExampleService _exampleService;

  ExampleProvider(this._exampleService);

  // State
  List<Example> _items = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Example> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  // Actions
  Future<void> fetchItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _exampleService.getItems();
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error fetching items: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(Example item) async {
    try {
      final newItem = await _exampleService.createItem(item);
      _items.add(newItem);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
```

2. **Register Provider in main.dart**

```dart
// lib/main.dart
MultiProvider(
  providers: [
    // ... existing providers
    ChangeNotifierProvider(
      create: (_) => ExampleProvider(exampleService),
    ),
  ],
  child: MaterialApp(/* ... */),
)
```

3. **Use Provider in UI**

```dart
// lib/screens/example_screen.dart
class ExampleScreen extends StatefulWidget {
  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  @override
  void initState() {
    super.initState();
    // Load data on screen init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExampleProvider>().fetchItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Example')),
      body: Consumer<ExampleProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return LoadingWidget();
          }

          if (provider.hasError) {
            return ErrorDisplayWidget(
              message: provider.error!,
              onRetry: () => provider.fetchItems(),
            );
          }

          if (provider.items.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.inbox,
              title: 'No Items',
              message: 'No items to display',
            );
          }

          return ListView.builder(
            itemCount: provider.items.length,
            itemBuilder: (context, index) {
              final item = provider.items[index];
              return ListTile(title: Text(item.name));
            },
          );
        },
      ),
    );
  }
}
```

### Best Practices

1. **Use `context.read()` for Actions (No Rebuild)**
   ```dart
   // For one-time actions (buttons, etc.)
   onPressed: () {
     context.read<ProductProvider>().addToCart(product);
   }
   ```

2. **Use `Consumer` for Reactive UI (Rebuilds)**
   ```dart
   // For widgets that need to rebuild when state changes
   Consumer<ProductProvider>(
     builder: (context, provider, child) {
       return Text('Items: ${provider.products.length}');
     },
   )
   ```

3. **Use `context.watch()` in Build Method**
   ```dart
   // For simple reactive widgets
   @override
   Widget build(BuildContext context) {
     final provider = context.watch<ProductProvider>();
     return Text('Count: ${provider.products.length}');
   }
   ```

4. **Avoid Notifying Listeners Too Frequently**
   ```dart
   // ❌ Bad: Notifies on every iteration
   for (var product in products) {
     _products.add(product);
     notifyListeners(); // Called multiple times!
   }

   // ✅ Good: Notify once after all changes
   for (var product in products) {
     _products.add(product);
   }
   notifyListeners(); // Called once
   ```

---

## Adding New Features

### Example: Adding Product Reviews

#### 1. Create Model

```dart
// lib/models/review.dart
class Review {
  final String id;
  final String productId;
  final String customerId;
  final String customerName;
  final int rating; // 1-5
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.productId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'].toString(),
      productId: json['id_product'].toString(),
      customerId: json['id_customer'].toString(),
      customerName: json['customer_name'] ?? 'Anonymous',
      rating: int.parse(json['grade'].toString()),
      comment: json['content'] ?? '',
      createdAt: DateTime.parse(json['date_add']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_product': productId,
      'id_customer': customerId,
      'customer_name': customerName,
      'grade': rating,
      'content': comment,
      'date_add': createdAt.toIso8601String(),
    };
  }
}
```

#### 2. Create Service

```dart
// lib/services/review_service.dart
class ReviewService {
  final ApiService _apiService;

  ReviewService(this._apiService);

  Future<List<Review>> getProductReviews(String productId) async {
    final queryParams = <String, String>{
      'display': 'full',
      'filter[id_product]': productId,
    };

    final response = await _apiService.get(
      '/product_comments', // PrestaShop reviews endpoint
      queryParameters: queryParams,
    );

    if (response is List && response.isEmpty) return [];

    if (response is Map && response['product_comments'] != null) {
      final reviewsData = response['product_comments'];
      if (reviewsData is List) {
        return reviewsData.map((json) => Review.fromJson(json)).toList();
      }
    }

    return [];
  }

  Future<Review> createReview({
    required String productId,
    required String customerId,
    required String customerName,
    required int rating,
    required String comment,
  }) async {
    final data = {
      'product_comment': {
        'id_product': productId,
        'id_customer': customerId,
        'customer_name': customerName,
        'grade': rating,
        'content': comment,
        'date_add': DateTime.now().toIso8601String(),
      },
    };

    final response = await _apiService.post('/product_comments', data);
    return Review.fromJson(response['product_comment']);
  }
}
```

#### 3. Create Provider

```dart
// lib/providers/review_provider.dart
class ReviewProvider with ChangeNotifier {
  final ReviewService _reviewService;

  ReviewProvider(this._reviewService);

  Map<String, List<Review>> _reviewsByProduct = {};
  bool _isLoading = false;
  String? _error;

  List<Review> getReviewsForProduct(String productId) {
    return _reviewsByProduct[productId] ?? [];
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProductReviews(String productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final reviews = await _reviewService.getProductReviews(productId);
      _reviewsByProduct[productId] = reviews;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addReview({
    required String productId,
    required String customerId,
    required String customerName,
    required int rating,
    required String comment,
  }) async {
    try {
      final review = await _reviewService.createReview(
        productId: productId,
        customerId: customerId,
        customerName: customerName,
        rating: rating,
        comment: comment,
      );

      if (_reviewsByProduct.containsKey(productId)) {
        _reviewsByProduct[productId]!.insert(0, review);
      } else {
        _reviewsByProduct[productId] = [review];
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
```

#### 4. Create UI Widget

```dart
// lib/widgets/product_reviews.dart
class ProductReviews extends StatelessWidget {
  final String productId;

  const ProductReviews({required this.productId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewProvider>(
      builder: (context, provider, child) {
        final reviews = provider.getReviewsForProduct(productId);

        if (reviews.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.rate_review,
            title: 'No Reviews Yet',
            message: 'Be the first to review this product',
          );
        }

        return Column(
          children: reviews.map((review) {
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(review.customerName[0].toUpperCase()),
                ),
                title: Row(
                  children: [
                    Text(review.customerName),
                    SizedBox(width: 8),
                    ...List.generate(5, (index) {
                      return Icon(
                        index < review.rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(review.comment),
                    SizedBox(height: 4),
                    Text(
                      _formatDate(review.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
```

#### 5. Integrate in Product Detail Screen

```dart
// lib/screens/product/product_detail_screen.dart
// Add to build method:

// After product description
SizedBox(height: 24),
Text(
  'Reviews',
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
SizedBox(height: 8),
ProductReviews(productId: product.id),
```

---

## Code Style & Standards

### File Naming

- **Screens**: `snake_case` (e.g., `product_detail_screen.dart`)
- **Widgets**: `snake_case` (e.g., `product_card.dart`)
- **Models**: `snake_case` (e.g., `cart_item.dart`)
- **Services**: `snake_case` (e.g., `product_service.dart`)
- **Providers**: `snake_case` (e.g., `product_provider.dart`)

### Class Naming

- **Classes**: `PascalCase` (e.g., `ProductDetailScreen`)
- **Widgets**: `PascalCase` (e.g., `ProductCard`)
- **Enums**: `PascalCase` (e.g., `OrderStatus`)

### Variable Naming

- **Public**: `camelCase` (e.g., `productName`)
- **Private**: `_camelCase` (e.g., `_isLoading`)
- **Constants**: `camelCase` (e.g., `defaultPageSize`)
- **Static Constants**: `camelCase` (e.g., `ApiConfig.baseUrl`)

### Import Organization

```dart
// 1. Dart imports
import 'dart:convert';
import 'dart:async';

// 2. Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// 3. Package imports (alphabetically)
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

// 4. Local imports (alphabetically)
import '../config/app_theme.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../widgets/product_card.dart';
```

### Code Formatting

Use `dart format`:
```bash
dart format lib/
```

### Documentation

Add documentation comments for public APIs:

```dart
/// Fetches products from the PrestaShop API with pagination support.
///
/// [limit] specifies the number of products to fetch per page (default: 20).
/// [offset] specifies the starting index for pagination (default: 0).
/// [categoryId] filters products by category if provided.
/// [sortBy] sorts products by field (e.g., 'price_ASC', 'name_DESC').
///
/// Returns a list of [Product] objects.
/// Throws [ApiException] if the request fails.
///
/// Example:
/// ```dart
/// final products = await productService.getProducts(
///   limit: 20,
///   offset: 0,
///   categoryId: '10',
///   sortBy: 'price_ASC',
/// );
/// ```
Future<List<Product>> getProducts({
  int? limit,
  int? offset,
  String? categoryId,
  String? sortBy,
}) async {
  // Implementation
}
```

---

## Testing

### Unit Testing

Create tests in `test/` directory:

```dart
// test/services/product_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:prestashop_mobile_app/services/product_service.dart';
import 'package:prestashop_mobile_app/services/api_service.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  group('ProductService', () {
    late MockApiService mockApiService;
    late ProductService productService;

    setUp(() {
      mockApiService = MockApiService();
      productService = ProductService(mockApiService);
    });

    test('getProducts returns empty list on empty API response', () async {
      when(mockApiService.get(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => []);

      final products = await productService.getProducts();

      expect(products, isEmpty);
    });

    test('getProducts parses product list correctly', () async {
      when(mockApiService.get(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => {
        'products': [
          {
            'id': '1',
            'name': 'Test Product',
            'price': '99.99',
            'active': '1',
          }
        ]
      });

      final products = await productService.getProducts();

      expect(products.length, equals(1));
      expect(products.first.id, equals('1'));
      expect(products.first.name, equals('Test Product'));
    });
  });
}
```

Run tests:
```bash
flutter test
```

### Widget Testing

```dart
// test/widgets/product_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prestashop_mobile_app/widgets/product_card.dart';
import 'package:prestashop_mobile_app/models/product.dart';

void main() {
  testWidgets('ProductCard displays product name', (WidgetTester tester) async {
    final product = Product(
      id: '1',
      name: 'Test Product',
      price: 99.99,
      inStock: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductCard(product: product),
        ),
      ),
    );

    expect(find.text('Test Product'), findsOneWidget);
    expect(find.text('TND99.99'), findsOneWidget);
  });
}
```

---

## Debugging

### Enable Debug Mode

```dart
// lib/config/api_config.dart
static const bool debugMode = true;
```

This logs all API requests and responses.

### Debug Tools

**Flutter DevTools:**
```bash
flutter run --observatory-port=8888
```

Then open: http://localhost:8888

**Print Debugging:**
```dart
if (kDebugMode) {
  print('Debug info: $variable');
}
```

**Breakpoints:**
- Set breakpoints in VS Code or Android Studio
- Run app in debug mode
- Inspect variables and call stack

### Common Issues

**Issue: Provider Not Found**
```
Error: Could not find the correct Provider<ProductProvider>
```

**Solution:** Ensure provider is registered in `main.dart` above the widget trying to access it.

**Issue: setState Called After Dispose**
```
Error: setState() called after dispose()
```

**Solution:** Check for pending async operations:
```dart
@override
void dispose() {
  _timer?.cancel(); // Cancel timers
  _subscription?.cancel(); // Cancel streams
  super.dispose();
}
```

---

## Performance Optimization

### Use const Constructors

```dart
// ✅ Good
const Text('Hello')

// ❌ Bad
Text('Hello')
```

### ListView.builder vs ListView

```dart
// ✅ Good: Only builds visible items
ListView.builder(
  itemCount: products.length,
  itemBuilder: (context, index) {
    return ProductCard(product: products[index]);
  },
)

// ❌ Bad: Builds all items upfront
ListView(
  children: products.map((p) => ProductCard(product: p)).toList(),
)
```

### Image Optimization

```dart
// Use cached_network_image
CachedNetworkImage(
  imageUrl: product.imageUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
  memCacheWidth: 300, // Limit cache size
  memCacheHeight: 300,
)
```

### Pagination

Always use pagination for lists:
```dart
// ✅ Load 20 at a time
fetchProducts(limit: 20, offset: 0)

// ❌ Load all products
fetchProducts()
```

---

## Common Tasks

### Add a New Screen

1. Create screen file: `lib/screens/example/example_screen.dart`
2. Define StatefulWidget or StatelessWidget
3. Add navigation route
4. Register in bottom navigation if needed

### Add a New Widget

1. Create widget file: `lib/widgets/example_widget.dart`
2. Make it configurable via constructor parameters
3. Prefer StatelessWidget when possible
4. Document usage with examples

### Add a New Model

1. Create model file: `lib/models/example.dart`
2. Add `fromJson` factory constructor
3. Add `toJson` method
4. Add `copyWith` for immutability (if needed)

### Update API Endpoint Permissions

1. Login to PrestaShop admin
2. Navigate to Webservice settings
3. Edit API key permissions
4. Enable GET/POST/PUT/DELETE as needed
5. Test endpoint with cURL or Postman

---

**Last Updated:** 2025-01-18
**Version:** 1.0.0
