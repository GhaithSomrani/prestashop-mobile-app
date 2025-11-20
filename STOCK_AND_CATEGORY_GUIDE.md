# Stock, Combination & Category Optimization Guide

## Overview
This guide explains the optimized stock filtering, combination handling, and category search functionality.

## Key Features

### 1. Stock Filtering with `stock_availables` Endpoint

#### How It Works
```dart
// Automatically filters out-of-stock products
final products = await productService.getProducts(
  filterInStock: true, // Default is true
);
```

**Behind the scenes:**
1. Fetches all in-stock product IDs from `stock_availables` endpoint
2. Caches results for 5 minutes
3. Filters products to only show items with `quantity > 0`

#### Check Individual Product Stock
```dart
// Check if product is in stock
bool inStock = await productService.isProductInStock('10000');

// Check specific combination/variant
bool variantInStock = await productService.isProductInStock(
  '10000',
  combinationId: '123'
);

// Get exact quantity
int quantity = await productService.getProductQuantity('10000');
```

### 2. Combination (Variants) Stock Management

#### Get All Combinations with Stock Data
```dart
// Get combinations with accurate stock quantities
final combinations = await combinationService.getCombinationsWithStock('10000');

// Each combination will have updated quantity from stock_availables
for (var combo in combinations) {
  print('${combo.reference}: ${combo.quantity} in stock');
}
```

#### Get Only In-Stock Combinations
```dart
// Only returns combinations that have quantity > 0
final availableCombinations = await combinationService.getInStockCombinations('10000');
```

### 3. Category-Based Stock Filtering

#### Get In-Stock Products for a Category
```dart
// Option 1: Direct filtering (recommended)
final categoryProducts = await productService.getProductsByCategory(
  '200', // Category ID
  filterInStock: true,
);

// Option 2: Get in-stock product IDs for a category
final inStockIds = await productService.getInStockProductIdsForCategory('200');
```

### 4. Caching Strategy

#### Stock Cache (5 minutes)
- In-stock product IDs are cached for 5 minutes
- Refreshed automatically when cache expires
- Category-specific queries bypass cache for accuracy

#### Manufacturer Cache (30 minutes)
- Manufacturer names cached for 30 minutes
- Reduces API calls significantly
- Shared across all product fetches

### 5. API Query Optimization

#### Stock Availables Query
```
GET stock_availables?display=[id_product,id_product_attribute,quantity]&filter[quantity]=>[0]
```
- Returns only products/combinations with quantity > 0
- Minimal fields for faster response
- Works with both base products and variants

#### Product Query
```
GET products?display=full&filter[active]=1&filter[id_category_default]=200
```
- No quantity filter (not supported by products endpoint)
- Filtering happens via stock_availables cross-reference

## Performance Benefits

### Before Optimization
```
For 20 products:
- 1 products API call
- 20 specific_price calls (one per product)
- 20 stock calls (one per product)
= 41 API calls total
```

### After Optimization
```
For 20 products:
- 1 stock_availables call (cached for 5 min)
- 1 products API call
= 2 API calls total
```

**Result: 95% fewer API calls!** 🚀

## Example Usage in App

### Home Screen - Featured Products
```dart
// Automatically shows only in-stock products
await productProvider.fetchProducts(
  limit: 20,
  filterInStock: true, // Default
);
```

### Category Screen
```dart
// Shows only in-stock products in this category
await productProvider.fetchProductsByCategory(
  categoryId,
  filterInStock: true,
);
```

### Product Detail Screen with Variants
```dart
// Get product
final product = await productService.getProductById('10000');

// Get only available variants
final availableVariants = await combinationService.getInStockCombinations('10000');

// User can only select from in-stock variants
```

## Technical Details

### Stock Availables Data Structure
```json
{
  "stock_availables": [
    {
      "id_product": "10000",
      "id_product_attribute": "0",  // 0 = base product
      "quantity": "5"
    },
    {
      "id_product": "10000",
      "id_product_attribute": "123", // variant ID
      "quantity": "3"
    }
  ]
}
```

### Filtering Logic
```dart
// Step 1: Get in-stock IDs
Set<String> inStockIds = await _getInStockProductIds();
// Returns: {"10001", "10002", "10005", ...}

// Step 2: Fetch products
List<Product> products = await fetchFromAPI();

// Step 3: Filter
products = products.where((p) => inStockIds.contains(p.id)).toList();
```

## Best Practices

1. **Always use default filterInStock=true** unless you specifically need out-of-stock products

2. **Use combination service for variants** to get accurate stock per variant

3. **Trust the cache** - 5 minutes is optimal for stock data

4. **Category filtering** - Use `getProductsByCategory()` instead of manual filtering

5. **Check stock before adding to cart** - Although filtered, double-check on add:
   ```dart
   if (await productService.isProductInStock(productId)) {
     cart.addItem(product);
   }
   ```

## Troubleshooting

### Products not showing up?
- Check if they have quantity > 0 in PrestaShop admin
- Verify `stock_availables` endpoint returns the product ID
- Check cache - wait 5 minutes or clear app data

### Wrong quantities displayed?
- Stock data comes from `stock_availables`, not product.quantity
- Combinations override base product quantity
- Cache may be stale - wait 5 minutes

### Category filtering slow?
- First load fetches stock_availables (cached afterward)
- Subsequent loads use cache - much faster
- Consider pagination for large categories

## Summary

✅ **Out-of-stock products completely hidden**
✅ **Accurate stock from stock_availables endpoint**
✅ **Combination/variant stock properly handled**
✅ **5-minute caching for performance**
✅ **95% reduction in API calls**
✅ **Category-aware stock filtering**
