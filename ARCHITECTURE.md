# PrestaShop Mobile App - Complete Architecture & API Integration Guide

## 📱 Application Overview

This is a complete Flutter-based mobile e-commerce application that integrates with PrestaShop Webservice API to provide a seamless shopping experience.

### Technology Stack
- **Framework**: Flutter 3.0+
- **State Management**: Provider
- **HTTP Client**: http package
- **Image Caching**: cached_network_image
- **Local Storage**: shared_preferences, flutter_secure_storage
- **API Format**: JSON (PrestaShop Webservice)

---

## 🏗️ Architecture

### Layer Structure

```
lib/
├── models/           # Data models (Product, Category, Customer, etc.)
├── services/         # API services (ProductService, CategoryService, etc.)
├── providers/        # State management (ProductProvider, CartProvider, etc.)
├── screens/          # UI screens (HomeScreen, ProductDetailScreen, etc.)
├── widgets/          # Reusable UI components
├── config/           # Configuration (API config, Theme)
├── utils/            # Utility functions
└── l10n/             # Localization
```

### Data Flow

```
UI (Screens/Widgets)
      ↓
   Providers (State Management)
      ↓
   Services (Business Logic)
      ↓
   API Service (HTTP Client)
      ↓
PrestaShop Webservice API
```

---

## 🔌 PrestaShop API Integration

### Base Configuration

```dart
// lib/config/api_config.dart
baseUrl: "https://your-prestashop-domain.com/"
apiKey: "YOUR_PRESTASHOP_WEBSERVICE_KEY"
outputFormat: "JSON"
```

### Authentication
PrestaShop Webservice uses **Basic Authentication**:
```
Authorization: Basic base64(apiKey:)
```

---

## 📊 PrestaShop Endpoints & Usage

### 1. **Products Endpoint** (`/api/products`)

#### Get All Products (Paginated)
```dart
GET /api/products?display=full&limit=0,20&filter[active]=1
```

**Response Structure:**
```json
{
  "products": [
    {
      "id": "1",
      "name": "Product Name",
      "description": "Full description",
      "description_short": "Short description",
      "price": "99.00",
      "id_category_default": "5",
      "id_default_image": "12",
      "quantity": 100,
      "reference": "SKU123",
      "active": "1",
      "id_manufacturer": "2"
    }
  ]
}
```

#### Get Products by Category
```dart
GET /api/products?display=full&filter[id_category_default]=5&limit=0,20
```

#### Get Single Product
```dart
GET /api/products/1?display=full
```

**Use Case:** Product detail page, product list, search

---

### 2. **Categories Endpoint** (`/api/categories`)

```dart
GET /api/categories?display=full&filter[active]=1
```

**Response:**
```json
{
  "categories": [
    {
      "id": "5",
      "name": "Clothing",
      "description": "All clothing items",
      "id_parent": "2",
      "active": "1"
    }
  ]
}
```

**Use Case:** Home page category listing, navigation

---

### 3. **Product Images** (`/api/images/products/{id}`)

```dart
GET /api/images/products/1
```

**Response:**
```json
{
  "image": {
    "id": "12",
    "id_product": "1",
    "position": "1",
    "cover": "1"
  }
}
```

**Image URL Format:**
```
https://your-domain.com/api/images/products/{product_id}/{image_id}
```

**Use Case:** Product cards, product detail gallery

---

### 4. **Combinations** (`/api/combinations`)

Combinations are product variants (size, color, etc.)

```dart
GET /api/combinations?filter[id_product]=1&display=full
```

**Response:**
```json
{
  "combinations": [
    {
      "id": "5",
      "id_product": "1",
      "reference": "SKU-RED-M",
      "price": "5.00",  // Price impact (+ or -)
      "quantity": 10,
      "default_on": "0"
    }
  ]
}
```

**Use Case:** Product variants (size/color selection)

---

### 5. **Product Options & Values** (`/api/product_options`, `/api/product_option_values`)

Product options define the attributes like "Size" or "Color"

```dart
GET /api/product_options?display=full
GET /api/product_option_values?filter[id_attribute_group]=1
```

**Response:**
```json
{
  "product_options": [
    {
      "id": "1",
      "name": "Size",
      "group_type": "select"
    }
  ],
  "product_option_values": [
    {
      "id": "1",
      "id_attribute_group": "1",
      "name": "Small",
      "color": ""
    }
  ]
}
```

**Use Case:** Dynamic filter generation, product variant selection

---

### 6. **Stock Availables** (`/api/stock_availables`)

Real-time stock information

```dart
GET /api/stock_availables?filter[id_product]=1&filter[id_product_attribute]=5
```

**Response:**
```json
{
  "stock_available": {
    "id": "1",
    "id_product": "1",
    "id_product_attribute": "5",
    "quantity": "15",
    "depends_on_stock": "0",
    "out_of_stock": "2"
  }
}
```

**Use Case:** Show real-time stock, "Add to Cart" button state

---

### 7. **Manufacturers** (`/api/manufacturers`)

Brand information

```dart
GET /api/manufacturers?display=full
```

**Response:**
```json
{
  "manufacturers": [
    {
      "id": "1",
      "name": "Nike",
      "description": "Nike brand",
      "active": "1"
    }
  ]
}
```

**Use Case:** Brand filter, brand pages

---

### 8. **Specific Prices** (`/api/specific_prices`)

Discounts and special pricing

```dart
GET /api/specific_prices?filter[id_product]=1
```

**Response:**
```json
{
  "specific_price": {
    "id": "1",
    "id_product": "1",
    "reduction": "0.2",  // 20% discount
    "reduction_type": "percentage",
    "price": "-1",       // -1 = use base price
    "from": "2024-01-01",
    "to": "2024-12-31"
  }
}
```

**Use Case:** Show sale badge, calculate discounted price

---

### 9. **Features & Feature Values** (`/api/features`, `/api/feature_values`)

Product features (material, weight, etc.)

```dart
GET /api/features?display=full
GET /api/feature_values?filter[id_feature]=1
```

**Response:**
```json
{
  "features": [
    {
      "id": "1",
      "name": "Material"
    }
  ],
  "feature_values": [
    {
      "id": "1",
      "id_feature": "1",
      "value": "Cotton"
    }
  ]
}
```

**Use Case:** Product specifications, filter generation

---

### 10. **Customers** (`/api/customers`)

Customer account management

```dart
GET /api/customers/{id}
POST /api/customers  (Create account)
PUT /api/customers/{id}  (Update account)
```

**Use Case:** Authentication, profile management

---

### 11. **Addresses** (`/api/addresses`)

Shipping/billing addresses

```dart
GET /api/addresses?filter[id_customer]=1
POST /api/addresses
```

**Use Case:** Checkout address selection

---

### 12. **Carts** (`/api/carts`)

Shopping cart management

```dart
GET /api/carts/{id}
POST /api/carts
PUT /api/carts/{id}
```

**Cart Product Association:**
```dart
POST /api/carts/{id}/products
{
  "id_product": "1",
  "id_product_attribute": "5",
  "quantity": 2
}
```

**Use Case:** Add to cart, update quantities

---

### 13. **Orders** (`/api/orders`)

Order creation and history

```dart
POST /api/orders
{
  "id_customer": "1",
  "id_cart": "5",
  "id_carrier": "2",
  "id_address_delivery": "3",
  "id_address_invoice": "3",
  "payment": "Credit Card",
  "module": "stripe"
}
```

```dart
GET /api/orders?filter[id_customer]=1  // Order history
```

**Use Case:** Checkout, order history

---

### 14. **Carriers** (`/api/carriers`)

Shipping methods

```dart
GET /api/carriers?filter[active]=1
```

**Use Case:** Checkout shipping selection

---

### 15. **Search** (`/api/search`)

Product search (if available, depends on PrestaShop version)

```dart
GET /api/search?query=shirt&limit=0,20
```

**Alternative:** Use product filter:
```dart
GET /api/products?filter[name]=%shirt%&limit=0,20
```

---

## 🎯 Complete Feature Implementations

### **1. Home Page Flow**

```dart
// Fetch categories
GET /api/categories?filter[active]=1&filter[id_parent]=2

// Fetch featured products (using specific category or custom logic)
GET /api/products?display=full&limit=0,10&filter[active]=1

// Fetch latest products (sorted by date)
GET /api/products?display=full&limit=0,10&sort=[id_DESC]
```

---

### **2. Category Page with Infinite Scroll**

#### Initial Load (20 products)
```dart
GET /api/products?filter[id_category_default]=5&limit=0,20&display=full
```

#### Load More (next 20)
```dart
GET /api/products?filter[id_category_default]=5&limit=20,20&display=full
```

#### With Filters Applied
```dart
GET /api/products?filter[id_category_default]=5
                  &filter[id_manufacturer]=2
                  &filter[price]=[50,100]
                  &limit=0,20
```

**Implementation Logic:**
1. Load first 20 products on page load
2. Detect scroll position reaching bottom (80% scrolled)
3. Fetch next 20 products with `offset = currentLength`
4. Append to existing product list
5. If filters change → reset offset to 0 and reload

---

### **3. Dynamic Filter Generation**

**Step 1: Fetch products in category**
```dart
GET /api/products?filter[id_category_default]=5&limit=0,100
```

**Step 2: Extract unique attributes from products**
- Get all `id_manufacturer` → fetch manufacturer names
- Get price range (min/max)
- Fetch combinations to get colors/sizes

**Step 3: Fetch product options and values**
```dart
GET /api/product_options?display=full
GET /api/product_option_values?display=full
```

**Step 4: Build filter groups dynamically**
```dart
Filters:
- Price Range: [min_price, max_price]
- Brands: [unique manufacturers]
- Colors: [from combinations/product_option_values where group=Color]
- Sizes: [from combinations/product_option_values where group=Size]
- Features: [from product features]
```

---

### **4. Product Detail Page Flow**

```dart
// 1. Fetch product details
GET /api/products/1?display=full

// 2. Fetch product images
GET /api/images/products/1

// 3. Fetch combinations (variants)
GET /api/combinations?filter[id_product]=1&display=full

// 4. Fetch stock for each combination
GET /api/stock_availables?filter[id_product]=1

// 5. Fetch specific prices (discounts)
GET /api/specific_prices?filter[id_product]=1

// 6. Fetch related products (products in same category)
GET /api/products?filter[id_category_default]={category_id}&limit=0,10
    &filter[id_product]=[!1]  // Exclude current product

// 7. Fetch manufacturer details
GET /api/manufacturers/{id_manufacturer}
```

---

### **5. Add to Cart Flow**

```dart
// 1. Check if customer has active cart
GET /api/carts?filter[id_customer]=1&filter[id_shop]=1
    &sort=[id_DESC]&limit=0,1

// 2. If no cart, create new cart
POST /api/carts
{
  "id_customer": "1",
  "id_currency": "1",
  "id_lang": "1"
}

// 3. Add product to cart
POST /api/cart_products
{
  "id_cart": "5",
  "id_product": "1",
  "id_product_attribute": "5",
  "quantity": 2
}

// 4. Fetch updated cart
GET /api/carts/5?display=full
```

---

### **6. Checkout Flow**

```dart
// 1. Get customer addresses
GET /api/addresses?filter[id_customer]=1

// 2. Get available carriers
GET /api/carriers?filter[active]=1

// 3. Calculate cart totals
GET /api/carts/5?display=full

// 4. Create order
POST /api/orders
{
  "id_customer": "1",
  "id_cart": "5",
  "id_carrier": "2",
  "id_address_delivery": "3",
  "id_address_invoice": "3",
  "payment": "Credit Card",
  "module": "stripe",
  "total_paid": "150.00",
  "total_products": "140.00",
  "total_shipping": "10.00"
}

// 5. Get order confirmation
GET /api/orders/{order_id}
```

---

### **7. Search with Filters**

```dart
// 1. Search products
GET /api/products?filter[name]=%shirt%&limit=0,20

// 2. Get unique attributes from results (for filters)
Extract: brands, colors, sizes, price range

// 3. Apply filters
GET /api/products?filter[name]=%shirt%
                  &filter[id_manufacturer]=2
                  &limit=20,20  // Pagination
```

---

## 🎨 UI Design System

### Minimal White Design Theme

```dart
Colors:
- Background: #FFFFFF (Pure White)
- Cards: #FFFFFF with shadow
- Primary Text: #000000 (Black)
- Secondary Text: #666666 (Grey)
- Buttons: #000000 (Black)
- Button Text: #FFFFFF (White)
- Borders: #E0E0E0 (Light Grey)

Spacing: 8px System
- spacing1: 8px
- spacing2: 16px
- spacing3: 24px
- spacing4: 32px

Border Radius:
- radiusSmall: 8px
- radiusMedium: 12px
- radiusLarge: 16px
- radiusXLarge: 24px

Shadows:
- Soft floating card shadow
- offset: (0, 2)
- blurRadius: 8
- color: rgba(0,0,0,0.08)
```

---

## 📦 State Management with Provider

### Provider Structure

```dart
main.dart:
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => ProductProvider()),
    ChangeNotifierProvider(create: (_) => CartProvider()),
    ChangeNotifierProvider(create: (_) => CategoryProvider()),
    ChangeNotifierProvider(create: (_) => OrderProvider()),
    ChangeNotifierProvider(create: (_) => WishlistProvider()),
  ],
  child: MyApp(),
)
```

### ProductProvider Methods

```dart
- fetchProducts({limit, offset, categoryId, filters})
- loadMoreProducts()  // Infinite scroll
- applyFilters(FilterOptions)
- searchProducts(query)
- fetchProductById(id)
- fetchRelatedProducts(categoryId, excludeId)
```

---

## 🔄 Infinite Scroll Implementation

```dart
class CategoryProductsScreen extends StatefulWidget {
  // ...
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentOffset = 0;
  final int _limit = 20;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadInitialProducts();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadInitialProducts() async {
    await productProvider.fetchProducts(
      categoryId: widget.category.id,
      limit: _limit,
      offset: 0,
    );
    _currentOffset = _limit;
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    final newProducts = await productProvider.loadMoreProducts(
      categoryId: widget.category.id,
      limit: _limit,
      offset: _currentOffset,
    );

    if (newProducts.length < _limit) {
      _hasMore = false;
    }

    _currentOffset += _limit;
    setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: products.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == products.length) {
          return LoadingIndicator();  // Loading more indicator
        }
        return ProductCard(product: products[index]);
      },
    );
  }
}
```

---

## 🎯 Best Practices

### 1. Error Handling
```dart
try {
  final products = await productService.getProducts();
} catch (e) {
  if (e is ApiException) {
    showError(e.message);
  } else {
    showError('Network error');
  }
}
```

### 2. Caching
- Use `cached_network_image` for product images
- Cache category list in SharedPreferences
- Cache user session in secure storage

### 3. Performance
- Implement pagination (limit 20-50 items per request)
- Lazy load images
- Debounce search input (300ms)

### 4. User Experience
- Show loading shimmer while fetching
- Pull-to-refresh on lists
- Smooth animations (fade, slide, scale)
- Error states with retry button
- Empty states with helpful messages

---

## 📱 Complete Screen Breakdown

### Home Screen
- Hero banner/carousel
- Category horizontal scroll
- Featured products grid
- Latest products list
- Search bar

### Category Screen
- Breadcrumb navigation
- Filter button (dynamic filters)
- Sort options
- Product grid/list toggle
- Infinite scroll (20 products per load)

### Product Detail Screen
- Image gallery with zoom
- Product name, price, discount badge
- Variant selector (color, size)
- Stock availability
- Add to cart button
- Add to wishlist button
- Product description tabs
- Related products carousel

### Cart Screen
- Cart items with quantity controls
- Remove item
- Cart summary (subtotal, shipping, total)
- Proceed to checkout button

### Checkout Screen
- Step 1: Select/add address
- Step 2: Select carrier
- Step 3: Payment method
- Step 4: Order confirmation

### Profile Screen
- User info
- Order history
- Addresses management
- Wishlist
- Settings
- Logout

---

## 🚀 Deployment Checklist

- [ ] Configure .env file with API credentials
- [ ] Test all API endpoints
- [ ] Implement error handling
- [ ] Add loading states
- [ ] Test pagination
- [ ] Test filters
- [ ] Test checkout flow
- [ ] Verify image loading
- [ ] Test on different screen sizes
- [ ] Performance optimization
- [ ] Security audit (no exposed keys)

---

## 📞 Support & Resources

- **PrestaShop Webservice Documentation**: https://devdocs.prestashop.com/1.7/webservice/
- **Flutter Documentation**: https://flutter.dev/docs
- **Provider Package**: https://pub.dev/packages/provider

---

**Built with ❤️ using Flutter & PrestaShop Webservice**
