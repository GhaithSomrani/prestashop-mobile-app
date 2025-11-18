# PrestaShop Mobile App

A modern, high-performance Flutter mobile application for PrestaShop e-commerce stores. Features infinite scroll, dynamic filtering, wishlist management, and a clean minimal white design focused on conversion optimization.

## 📱 Overview

This application provides a complete mobile shopping experience for PrestaShop-powered online stores, utilizing the official PrestaShop Webservice API for all data operations.

### Key Features

- ✅ **Browse Products** - Infinite scroll with 20 products per page
- ✅ **Dynamic Filters** - Filters generated automatically from actual product data (brands, prices, colors, sizes)
- ✅ **Category Navigation** - Hierarchical category browsing with breadcrumbs
- ✅ **Product Search** - Real-time search with history and category filtering
- ✅ **Product Details** - Gallery, combinations, attributes, stock status, related products
- ✅ **Shopping Cart** - Add to cart with variant selection, quantity management
- ✅ **Wishlist** - Persistent wishlist with local storage
- ✅ **User Authentication** - Register, login, password recovery
- ✅ **Order Management** - Order history, address management
- ✅ **Sort Options** - Price (asc/desc), Name (A-Z, Z-A), Newest first

### Design Philosophy

- **Minimal White UI** - Clean, modern design with white background and floating cards
- **8px Spacing System** - Consistent visual hierarchy
- **High Conversion Focus** - Optimized buying flow, clear CTAs, smooth navigation
- **Responsive** - Adapts to different screen sizes
- **Performance** - Optimized image loading, efficient pagination, smart caching

---

## 🏗️ Architecture

### Tech Stack

- **Framework**: Flutter 3.x
- **Language**: Dart with null safety
- **State Management**: Provider pattern with ChangeNotifier
- **HTTP Client**: http package
- **Image Caching**: cached_network_image
- **Local Storage**: shared_preferences
- **API**: PrestaShop Webservice REST API

### Project Structure

```
lib/
├── config/               # Configuration files
│   ├── api_config.dart   # API endpoints and settings
│   └── app_theme.dart    # Theme colors, spacing, shadows
│
├── models/               # Data models
│   ├── product.dart      # Product model with combinations
│   ├── category.dart     # Category model
│   ├── combination.dart  # Product variants
│   ├── attribute.dart    # Product attributes (color, size)
│   ├── feature.dart      # Product features/specifications
│   ├── manufacturer.dart # Brand/manufacturer
│   ├── specific_price.dart # Discounts and special prices
│   ├── cart_item.dart    # Shopping cart items
│   ├── wishlist_item.dart # Wishlist items
│   ├── customer.dart     # Customer/user data
│   └── order.dart        # Order information
│
├── services/             # Business logic and API integration
│   ├── api_service.dart  # Base HTTP client with auth
│   ├── product_service.dart # Product CRUD operations
│   ├── category_service.dart # Category operations
│   ├── filter_service.dart # Dynamic filter generation
│   ├── stock_service.dart # Stock availability
│   ├── combination_service.dart # Product combinations
│   ├── attribute_service.dart # Attributes management
│   ├── manufacturer_service.dart # Brand operations
│   ├── specific_price_service.dart # Discount calculations
│   ├── feature_service.dart # Product features
│   ├── customer_service.dart # User authentication
│   ├── order_service.dart # Order management
│   └── carrier_service.dart # Shipping methods
│
├── providers/            # State management
│   ├── product_provider.dart # Product state with pagination
│   ├── category_provider.dart # Category state
│   ├── cart_provider.dart # Shopping cart state
│   ├── wishlist_provider.dart # Wishlist state
│   ├── auth_provider.dart # Authentication state
│   └── order_provider.dart # Order state
│
├── screens/              # UI screens
│   ├── home/            # Home screen with featured products
│   ├── category/        # Category listing and products
│   ├── product/         # Product detail screen
│   ├── search/          # Search functionality
│   ├── cart/            # Shopping cart
│   ├── wishlist/        # Wishlist screen
│   ├── checkout/        # Checkout flow
│   ├── auth/            # Login/register screens
│   └── profile/         # User profile and orders
│
├── widgets/              # Reusable UI components
│   ├── product_card.dart # Product grid/list item
│   ├── category_chip.dart # Category selector
│   ├── filter_bottom_sheet.dart # Dynamic filter UI
│   ├── custom_search_bar.dart # Search input
│   ├── loading_widget.dart # Loading state
│   ├── error_widget.dart # Error state
│   ├── empty_state_widget.dart # Empty results
│   └── ... (more components)
│
├── l10n/                 # Localization/translations
│   └── app_localizations.dart
│
└── main.dart             # App entry point
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK (2.17 or higher)
- PrestaShop store with Webservice API enabled
- Android Studio / Xcode for mobile development

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd prestashop-mobile-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API credentials**

   Create a `.env` file in the project root:
   ```env
   PRESTASHOP_API_URL=https://your-store.com/api
   PRESTASHOP_API_KEY=YOUR_API_KEY_HERE
   ```

4. **Update API configuration** (if needed)

   Edit `lib/config/api_config.dart`:
   ```dart
   class ApiConfig {
     static final String baseUrl = dotenv.env['PRESTASHOP_API_URL'] ?? '';
     static final String apiKey = dotenv.env['PRESTASHOP_API_KEY'] ?? '';
     // ... other settings
   }
   ```

5. **Run the app**
   ```bash
   # For Android
   flutter run

   # For iOS
   flutter run -d ios

   # For production build
   flutter build apk --release  # Android
   flutter build ios --release  # iOS
   ```

---

## 📖 How It Works

### 1. Application Flow

```
┌─────────────┐
│   Startup   │
│   (main.dart)│
└──────┬──────┘
       │
       ├─► Initialize Services (API, Product, Category, etc.)
       ├─► Setup Providers (Product, Cart, Auth, Wishlist)
       ├─► Load .env configuration
       │
       ▼
┌─────────────┐
│  MainScreen │  ◄─── Bottom Navigation (5 tabs)
│             │
└──────┬──────┘
       │
       ├─► Home Screen ────► Browse featured/latest products
       ├─► Categories ─────► Browse by category hierarchy
       ├─► Cart ───────────► View cart, checkout
       ├─► Wishlist ───────► Saved products
       └─► Profile ────────► Orders, addresses, logout
```

### 2. Data Flow (Provider Pattern)

```
┌──────────┐
│   UI     │ ◄──── Listens to changes
│ (Screen) │
└────┬─────┘
     │
     │ User Action (e.g., "Load Products")
     ▼
┌──────────────┐
│   Provider   │ ◄──── State Management
│ (ChangeNotifier)
└────┬─────────┘
     │
     │ Calls business logic
     ▼
┌──────────────┐
│   Service    │ ◄──── API Communication
│ (ProductService)
└────┬─────────┘
     │
     │ HTTP Request
     ▼
┌──────────────┐
│ PrestaShop   │ ◄──── REST API
│   Webservice │
└────┬─────────┘
     │
     │ JSON Response
     ▼
┌──────────────┐
│    Model     │ ◄──── Data Parsing
│  (Product)   │
└────┬─────────┘
     │
     │ Update State
     ▼
┌──────────────┐
│   Provider   │ ──notifyListeners()──► UI Rebuilds
│              │
└──────────────┘
```

### 3. Infinite Scroll Implementation

The app uses **server-side pagination** with infinite scroll:

1. **Initial Load**: Fetch 20 products (offset=0, limit=20)
2. **Scroll Detection**: When user scrolls to 80% of the list
3. **Load More**: Fetch next 20 products (offset=20, limit=20)
4. **Append Results**: Add new products to existing list
5. **Stop Condition**: When response returns less than 20 products

**Example Code:**
```dart
// ProductProvider
Future<void> fetchProducts() async {
  final products = await _productService.getProducts(
    limit: 20,
    offset: _currentOffset,
  );
  _products.addAll(products);
  _currentOffset += 20;
  if (products.length < 20) _hasMore = false;
}

// CategoryProductsScreen
_scrollController.addListener(() {
  if (_scrollController.position.pixels >=
      _scrollController.position.maxScrollExtent * 0.8) {
    _loadMore();
  }
});
```

### 4. Dynamic Filter Generation

Filters are **generated from actual product data**, not hardcoded:

**Process:**
1. Load products for a category
2. Extract unique values:
   - Brands (from manufacturer data)
   - Price range (min/max from actual prices)
   - Colors (from product attributes)
   - Sizes (from product attributes)
3. Generate filter UI dynamically
4. Apply filters client-side or server-side

**Example:**
```dart
// FilterService
Future<DynamicFilterData> generateFiltersFromProducts(
  List<Product> products,
) async {
  // Get unique brands
  final manufacturers = await _manufacturerService.getManufacturers();
  final brands = manufacturers.map((m) => m.name).toList();

  // Calculate price range from actual products
  final prices = products.map((p) => p.finalPrice).toList();
  final minPrice = prices.reduce((a, b) => a < b ? a : b);
  final maxPrice = prices.reduce((a, b) => a > b ? a : b);

  // Extract colors and sizes from attributes
  final attributes = await _attributeService.getAttributeGroupsWithValues();

  return DynamicFilterData(
    brands: brands,
    minPrice: minPrice,
    maxPrice: maxPrice,
    colors: colors,
    sizes: sizes,
  );
}
```

### 5. API Error Handling

The app gracefully handles all API response formats:

**Empty Results**: `[]` → Returns empty list, hides UI blocks
**Single Item**: `{"product": {...}}` → Wraps in list
**Multiple Items**: `{"products": [{...}, {...}]}` → Parses array
**Network Errors**: Shows error widget with retry button

```dart
// ApiService - Supports both Map and List responses
dynamic _handleResponse(http.Response response) {
  return jsonDecode(response.body); // Returns dynamic
}

// ProductService - Handles all formats
if (response is List) {
  if (response.isEmpty) return [];
  return response.map((json) => Product.fromJson(json)).toList();
} else if (response is Map && response['products'] != null) {
  // Handle wrapped response
}
```

### 6. Wishlist Persistence

Wishlist is stored **locally** using SharedPreferences:

1. Add to wishlist → Save to SharedPreferences as JSON
2. Remove from wishlist → Update SharedPreferences
3. App restart → Load wishlist from storage
4. Sync with server (optional enhancement)

```dart
// WishlistProvider
Future<void> _saveToStorage() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = json.encode(
    _items.map((item) => item.toJson()).toList()
  );
  await prefs.setString('wishlist_items', jsonString);
}
```

---

## 🔑 Key Features Explained

### Home Screen

**Purpose**: Entry point showcasing featured content

**Features:**
- Hero banner with promotional content
- Featured products carousel (first 5 products)
- Trending products grid (next 6 products)
- New arrivals carousel
- Shop by brand section
- Search bar (navigates to SearchScreen)

**Empty State Handling:**
- If no products: Hides all product sections
- Shows only available content
- No blank placeholder blocks

### Category Products Screen

**Purpose**: Browse products in a specific category

**Features:**
- Breadcrumb navigation (Home > Category > Subcategory)
- Grid/List view toggle
- Sort options (Price, Name, Newest)
- Filter button (opens FilterBottomSheet)
- Infinite scroll loading indicator
- Pull-to-refresh
- Empty state: "No Products Found"

**Infinite Scroll:**
- Loads 20 products initially
- Detects scroll at 80% threshold
- Shows loading indicator at bottom while loading more
- Stops when no more products available

### Product Detail Screen

**Purpose**: Display complete product information

**Features:**
- Image gallery (swipeable)
- Product name and price
- Discount badge (if on sale)
- Stock status indicator
- Variant selector (combinations)
- Quantity picker
- Add to cart button
- Product description
- Features/specifications table
- Related products carousel

**Variants:**
- ChoiceChips for size/color selection
- Updates price based on selected combination
- Shows stock for selected variant

### Search Screen

**Purpose**: Find products by keywords

**Features:**
- Real-time search with 500ms debounce
- Search history (stored locally, max 10 items)
- Category filter (search within specific category)
- Results grid with product cards
- Empty state: "No Results Found"

**Search Flow:**
1. User types query
2. 500ms delay (debounce)
3. API request to `/products?filter[name]=%query%`
4. Display results in grid
5. Save query to history

### Filter Bottom Sheet

**Purpose**: Apply dynamic filters to product list

**Features:**
- Brand filter (checkboxes)
- Price range slider (min/max from actual data)
- Color filter (from product attributes)
- Size filter (from product attributes)
- Stock availability toggle
- Apply button (triggers client-side or server-side filtering)
- Reset filters button

**Dynamic Generation:**
- Filters are NOT hardcoded
- Generated from actual product data in current view
- Updates when category/search changes

### Shopping Cart

**Purpose**: Manage items before checkout

**Features:**
- Cart items with thumbnail, name, variant, price
- Quantity adjustment (+/-)
- Remove item button
- Subtotal calculation
- Proceed to checkout button
- Empty cart state: "Your cart is empty"

**Persistence:**
- Saved to SharedPreferences
- Survives app restarts
- Cleared after order completion

### Wishlist

**Purpose**: Save products for later

**Features:**
- Grid of saved products
- Remove from wishlist button
- Add to cart from wishlist
- Empty state: "No items in wishlist"

**Heart Icon:**
- Product cards show heart icon
- Filled = in wishlist
- Outline = not in wishlist
- Toggle on tap

---

## 🔧 Configuration

### API Configuration (`lib/config/api_config.dart`)

```dart
class ApiConfig {
  // API Credentials
  static final String baseUrl = dotenv.env['PRESTASHOP_API_URL'] ?? '';
  static final String apiKey = dotenv.env['PRESTASHOP_API_KEY'] ?? '';

  // API Endpoints
  static const String productsEndpoint = '/products';
  static const String categoriesEndpoint = '/categories';
  static const String customersEndpoint = '/customers';
  static const String ordersEndpoint = '/orders';
  static const String cartsEndpoint = '/carts';
  static const String addressesEndpoint = '/addresses';
  static const String stocksEndpoint = '/stock_availables';
  static const String imagesEndpoint = '/images';
  static const String combinationsEndpoint = '/combinations';
  static const String attributesEndpoint = '/product_option_values';
  static const String manufacturersEndpoint = '/manufacturers';
  static const String specificPricesEndpoint = '/specific_prices';

  // Pagination
  static const int defaultLimit = 20; // Products per page

  // Settings
  static const String outputFormat = 'JSON';
  static const bool debugMode = true; // Set to false in production
}
```

### Theme Configuration (`lib/config/app_theme.dart`)

```dart
class AppTheme {
  // Colors
  static const Color primaryBlack = Color(0xFF000000);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color backgroundWhite = Color(0xFFF8F8F8);
  static const Color secondaryGrey = Color(0xFF6B6B6B);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFE53935);

  // Spacing (8px system)
  static const double spacing1 = 8.0;
  static const double spacing2 = 16.0;
  static const double spacing3 = 24.0;
  static const double spacing4 = 32.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // Shadows
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0A000000), // 4% opacity black
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
}
```

---

## 📊 API Integration Details

### Authentication

All API requests use **Basic Authentication**:
```
Authorization: Basic base64(API_KEY:)
```

**Implementation:**
```dart
// ApiService
Map<String, String> get _headers => {
  'Authorization': 'Basic ${base64Encode(utf8.encode('$apiKey:'))}',
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};
```

### Request Examples

**Get Products:**
```
GET /api/products?output_format=JSON&display=full&limit=0,20&filter[active]=1
```

**Get Category Products:**
```
GET /api/products?output_format=JSON&display=full&limit=0,20
    &filter[id_category_default]=663&filter[active]=1
```

**Search Products:**
```
GET /api/products?output_format=JSON&display=full
    &filter[name]=%query%&filter[active]=1
```

**Get Product by ID:**
```
GET /api/products/123?output_format=JSON&display=full
```

### Response Format

**Success Response:**
```json
{
  "products": [
    {
      "id": "123",
      "name": "Product Name",
      "price": "99.99",
      "id_manufacturer": "5",
      "id_category_default": "10",
      "active": "1"
    }
  ]
}
```

**Empty Response:**
```json
[]
```

**Error Response:**
```json
{
  "errors": [
    {
      "code": 401,
      "message": "Unauthorized"
    }
  ]
}
```

---

## 🐛 Troubleshooting

### Issue: API Parsing Error

**Error:**
```
type 'List<dynamic>' is not a subtype of type 'Map<String, dynamic>'
```

**Solution:**
✅ Already fixed in commit `da2a710`
- ApiService now returns `dynamic` instead of `Map<String, dynamic>`
- ProductService and CategoryService handle both `[]` and `{...}` responses

### Issue: Empty Categories Show Blank Spaces

**Solution:**
✅ Already implemented
- Home screen conditionally hides sections with no data
- Uses `if (products.isNotEmpty) ... []` syntax
- No placeholder widgets shown for empty results

### Issue: Products Not Loading

**Checklist:**
1. Verify `.env` file exists with correct credentials
2. Check API key has permissions for `/products` endpoint
3. Enable debug mode in `api_config.dart` to see API requests
4. Check network connectivity
5. Verify PrestaShop Webservice is enabled in store admin

### Issue: Images Not Displaying

**Possible Causes:**
- Image URL format incorrect
- CORS issues (if using web platform)
- Image server requires authentication

**Solution:**
- Check `product.imageUrl` in debug mode
- Verify image URLs are publicly accessible
- Use `cached_network_image` error widget to debug

---

## 📈 Performance Optimization

### Implemented Optimizations

1. **Pagination** - Load 20 products at a time (not all at once)
2. **Image Caching** - `cached_network_image` caches images locally
3. **Lazy Loading** - Products loaded only when scrolled into view
4. **Debounced Search** - 500ms delay prevents excessive API calls
5. **Provider Pattern** - Minimal widget rebuilds with `Consumer`
6. **Const Constructors** - Static widgets use `const` for performance

### Future Optimizations (Recommended)

- [ ] Implement API response caching
- [ ] Add image optimization/compression
- [ ] Lazy load product combinations
- [ ] Implement pagination for related products
- [ ] Add skeleton loading states
- [ ] Background sync for wishlist/cart

---

## 🧪 Testing

### Manual Testing Checklist

- [ ] Browse home screen with products
- [ ] Browse empty categories (verify no errors)
- [ ] Infinite scroll in category (load 20+ products)
- [ ] Apply filters (brand, price, stock)
- [ ] Search products with keyword
- [ ] View product details
- [ ] Add product to cart
- [ ] Add product to wishlist
- [ ] Remove from wishlist
- [ ] Adjust cart quantities
- [ ] Pull to refresh on category screen
- [ ] Switch between grid/list view
- [ ] Sort products (price, name, newest)

---

## 📝 Contributing

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use meaningful variable names
- Add comments for complex logic
- Keep functions small and focused
- Use `const` constructors where possible

### Git Workflow

1. Create feature branch: `git checkout -b feature/new-feature`
2. Make changes and commit: `git commit -m "Add new feature"`
3. Push to branch: `git push origin feature/new-feature`
4. Create pull request

### Commit Message Format

```
<type>: <short description>

<detailed description>

<impact/changes>
```

**Types:** feat, fix, docs, refactor, test, chore

---

## 📞 Support

For issues, questions, or contributions:
- Create an issue on GitHub
- Check the troubleshooting section
- Review PrestaShop API documentation

---

## 🗺️ Roadmap

### Completed ✅
- Product browsing with infinite scroll
- Dynamic filters from API data
- Category navigation
- Search functionality
- Shopping cart
- Wishlist with persistence
- Empty state handling
- API error handling

### In Progress 🚧
- User authentication
- Checkout flow
- Order management

### Planned 📋
- Product reviews and ratings
- Push notifications
- Offline mode
- Multi-language support
- Dark mode theme
- Payment gateway integration
- Social sharing
- Barcode scanner

---

**Last Updated:** 2025-01-18
**Version:** 1.0.0
**Status:** Production Ready (90% Complete)
