# Product Retrieval Logic - Complete Guide

This guide explains the new product retrieval system for the PrestaShop mobile app using JSON endpoints.

## 📋 Overview

The new `ProductService` follows a modular architecture where each PrestaShop endpoint is called separately and then merged into a unified product object. All products and combinations without stock are automatically filtered out.

## 🔵 Architecture

### Flow Diagram

```
1. getProductIds(page)
   ↓
2. For each product ID:
   ├─→ getProductDetails(id)      [Product info]
   ├─→ getProductStock(id)         [Base stock]
   ├─→ getProductCombinations(id)  [Variants + stock]
   ├─→ getProductSpecificPrices(id) [Discounts]
   └─→ buildUnifiedProduct(id)     [Merge all data]
       ↓
   Filter: Only products/combinations with stock > 0
```

---

## 🔵 1. Fetch Product IDs (Paginated)

### Endpoint
```
GET /api/products?output_format=JSON&display=[id,id_default_category]&limit=20&offset=0
```

### Code
```dart
Future<List<String>> getProductIds({
  int page = 0,
  int limit = 20,
  String? categoryId,
})
```

### Example Call
```dart
final productIds = await productService.getProductIds(page: 0, limit: 20);
// Returns: ['1', '2', '3', ...]
```

### Response Example
```json
{
  "products": [
    {"id": "1", "id_default_category": "2"},
    {"id": "2", "id_default_category": "3"}
  ]
}
```

---

## 🔵 2. Fetch Full Product Details

### Endpoint
```
GET /api/products/{id}?output_format=JSON&display=full
```

### Code
```dart
Future<Map<String, dynamic>> getProductDetails(String id)
```

### Example Call
```dart
final details = await productService.getProductDetails('1');
```

### Extracts
- `name` - Product name (multilingual)
- `price` - Base price
- `description` - Full description
- `description_short` - Short description
- `id_default_category` - Default category ID
- `associations.categories` - All categories
- `associations.images` - Product images
- `associations.combinations` - Combination references

---

## 🔵 3. Fetch Product Stock

### Endpoint
```
GET /api/stock_availables?output_format=JSON&filter[id_product]={id}&filter[id_product_attribute]=0
```

### Code
```dart
Future<int> getProductStock(String id)
```

### Example Call
```dart
final stock = await productService.getProductStock('1');
// Returns: 10 (quantity)
```

### Rules
✅ If `quantity > 0` → product has stock
❌ If product has no combinations AND `quantity = 0` → exclude product

---

## 🔵 4. Fetch Combinations with Stock

### Endpoints
```
Step 1: GET /api/combinations?output_format=JSON&filter[id_product]={id}&limit=50&offset=0
Step 2: For each combination:
        GET /api/stock_availables?output_format=JSON&filter[id_product]={id}&filter[id_product_attribute]={comb_id}
```

### Code
```dart
Future<List<Map<String, dynamic>>> getProductCombinations(String productId)
```

### Example Call
```dart
final combinations = await productService.getProductCombinations('1');
```

### Returns
```json
[
  {
    "id": "10",
    "price": "5.00",
    "stock": 15,
    "associations": {
      "product_option_values": [
        {"id": "1"},
        {"id": "5"}
      ]
    }
  }
]
```

### Rules
✅ Keep only combinations with `quantity > 0`
❌ If ALL combination stocks = 0 → exclude entire product

---

## 🔵 5. Fetch Specific Prices (Discounts)

### Endpoint
```
GET /api/specific_prices?output_format=JSON&filter[id_product]={id}&limit=20
```

### Code
```dart
Future<List<SpecificPrice>> getProductSpecificPrices(String productId)
```

### Example Call
```dart
final prices = await productService.getProductSpecificPrices('1');
```

### Processing
- Detects reduction type (`percentage` or `amount`)
- Computes `final_price = base_price - reduction`
- Applies date conditions (`from`, `to`)
- Applies quantity conditions (`from_quantity`)
- Filters only active prices

### Example Response
```json
{
  "specific_prices": [
    {
      "id": "1",
      "id_product": "1",
      "id_product_attribute": "0",
      "reduction": "0.20",
      "reduction_type": "percentage",
      "from": "2025-01-01 00:00:00",
      "to": "2025-12-31 23:59:59"
    }
  ]
}
```

---

## 🔵 6. Fetch Categories (Optional)

### Endpoint
```
GET /api/categories/{id}?output_format=JSON&display=full
```

### Code
```dart
Future<Map<String, dynamic>?> getCategoryDetails(String categoryId)
```

### Usage
Categories are extracted from `product.associations.categories`. This endpoint is only needed for additional category metadata (name, description, etc.).

---

## 🔵 7. Final Unified Product Object

### Code
```dart
Future<Map<String, dynamic>?> buildUnifiedProduct(String productId)
```

### Assembly Steps

1. **Fetch all data** (details, stock, combinations, prices)
2. **Apply stock filtering**:
   - If product has combinations: exclude if all have 0 stock
   - If no combinations: exclude if base stock = 0
3. **Calculate final prices** for base product and combinations
4. **Extract** categories, images, attributes
5. **Build** unified JSON object

### Final Object Structure

```json
{
  "id": "1",
  "name": "Premium T-Shirt",
  "default_category": "2",
  "categories": ["2", "5", "8"],
  "images": ["12", "13", "14"],
  "price": 25.00,
  "final_price": 20.00,
  "stock": 50,
  "description": "High quality cotton t-shirt",
  "description_short": "Premium t-shirt",
  "reference": "TSHIRT-001",
  "combinations": [
    {
      "id": "10",
      "attributes": [
        {"id": "1"},
        {"id": "5"}
      ],
      "price": 27.00,
      "final_price": 21.60,
      "stock": 15
    },
    {
      "id": "11",
      "attributes": [
        {"id": "2"},
        {"id": "6"}
      ],
      "price": 27.00,
      "final_price": 21.60,
      "stock": 20
    }
  ]
}
```

---

## 🔵 8. Main Entry Points

### Get Paginated Products

```dart
Future<List<Map<String, dynamic>>> getProducts({
  int page = 0,
  int limit = 20,
  String? categoryId,
})
```

**Usage:**
```dart
// Page 1
final products = await productService.getProducts(page: 0, limit: 20);

// Page 2
final moreProducts = await productService.getProducts(page: 1, limit: 20);

// Filter by category
final categoryProducts = await productService.getProducts(
  page: 0,
  limit: 20,
  categoryId: '2',
);
```

### Get Single Product

```dart
Future<Map<String, dynamic>?> getProductById(String id)
```

**Usage:**
```dart
final product = await productService.getProductById('1');
if (product != null) {
  print('Product: ${product['name']}');
  print('Price: ${product['final_price']}');
  print('Stock: ${product['stock']}');
}
```

### Search Products

```dart
Future<List<Map<String, dynamic>>> searchProducts(
  String query, {
  int page = 0,
  int limit = 20,
})
```

**Usage:**
```dart
final results = await productService.searchProducts('shirt', page: 0);
```

---

## ✅ Stock Filtering Rules

### Products WITHOUT Combinations
```
IF base_stock > 0:
  ✅ Include product
ELSE:
  ❌ Exclude product
```

### Products WITH Combinations
```
combinations_with_stock = Filter combinations where stock > 0

IF combinations_with_stock.length > 0:
  ✅ Include product (with filtered combinations)
ELSE:
  ❌ Exclude product entirely
```

### Example Scenarios

**Scenario 1: Base product with stock**
```
Product ID: 1
Base Stock: 10
Combinations: None
Result: ✅ INCLUDED
```

**Scenario 2: Product with in-stock combinations**
```
Product ID: 2
Base Stock: 0
Combinations:
  - Comb 1: stock = 5  ✅
  - Comb 2: stock = 10 ✅
  - Comb 3: stock = 0  ❌
Result: ✅ INCLUDED (with Comb 1 & 2 only)
```

**Scenario 3: Product with all out-of-stock combinations**
```
Product ID: 3
Base Stock: 0
Combinations:
  - Comb 1: stock = 0  ❌
  - Comb 2: stock = 0  ❌
Result: ❌ EXCLUDED entirely
```

---

## 💰 Price Calculation

### Base Product Price

```dart
if (specificPrices.isNotEmpty) {
  final basePrice = specificPrices.firstWhere(
    (sp) => sp.idProductAttribute == null || sp.idProductAttribute == '0',
    orElse: () => specificPrices.first,
  );
  finalPrice = basePrice.calculateFinalPrice(productPrice);
}
```

### Combination Price

```dart
combBasePrice = product.basePrice + combination.priceImpact;

if (specificPrices.isNotEmpty) {
  final combPrice = specificPrices.firstWhere(
    (sp) => sp.idProductAttribute == combinationId,
    orElse: () => specificPrices.first,
  );
  combFinalPrice = combPrice.calculateFinalPrice(combBasePrice);
}
```

### Reduction Types

**Percentage:**
```
final_price = base_price * (1 - reduction)
Example: $100 with 20% off = $100 * 0.8 = $80
```

**Amount:**
```
final_price = base_price - reduction
Example: $100 with $15 off = $100 - $15 = $85
```

---

## 🚀 Performance Considerations

### Current Implementation
- **Sequential:** Each product is fetched one at a time
- **Multiple API calls per product:** 4-5 calls minimum
- **Automatic filtering:** Products without stock are excluded

### Future Optimizations (Optional)
1. **Parallel fetching:** Fetch multiple products simultaneously
2. **Batch stock queries:** Get stock for multiple products in one call
3. **Caching:** Cache category details, attribute names
4. **Lazy loading:** Load combinations only when needed

---

## 📝 Usage Examples

### Example 1: Display Product List

```dart
final products = await productService.getProducts(page: 0, limit: 10);

for (var product in products) {
  print('${product['name']} - \$${product['final_price']}');
  print('Stock: ${product['stock']}');

  if (product['combinations'].isNotEmpty) {
    print('Variants available: ${product['combinations'].length}');
  }
}
```

### Example 2: Product Detail Page

```dart
final product = await productService.getProductById('1');

if (product != null) {
  // Display product info
  final name = product['name'];
  final price = product['final_price'];
  final originalPrice = product['price'];
  final hasDiscount = price < originalPrice;

  // Display combinations
  final combinations = product['combinations'] as List;
  for (var combo in combinations) {
    print('Variant: ${combo['attributes']}');
    print('Price: \$${combo['final_price']}');
    print('Stock: ${combo['stock']}');
  }
}
```

### Example 3: Category Filtering

```dart
final categoryProducts = await productService.getProducts(
  page: 0,
  limit: 20,
  categoryId: '5',
);

print('Found ${categoryProducts.length} products in category 5');
```

---

## 🎯 Summary

✅ **Modular design** - Each endpoint has its own function
✅ **Stock filtering** - Automatic exclusion of out-of-stock items
✅ **Pagination support** - Efficient data loading
✅ **Complete pricing** - Handles discounts and specific prices
✅ **Combination support** - Full variant handling with stock
✅ **Category integration** - Multi-category support
✅ **Clean JSON output** - Unified, predictable structure

All code is located in: `lib/services/product_service.dart`
