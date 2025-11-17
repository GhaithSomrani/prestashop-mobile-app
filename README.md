# PrestaShop Mobile App

A comprehensive Flutter mobile application that integrates with PrestaShop API to provide a full-featured e-commerce experience.

## Features

### Core Features
- **Bottom Navigation** with 4 main tabs:
  - Home/Shop (Product Listing)
  - Categories
  - Shopping Cart
  - Profile/Account

### PrestaShop API Integration
- Full API client with base URL configuration
- Authentication using PrestaShop webservice key
- Comprehensive error handling and loading states
- Support for JSON responses
- Secure storage for API keys and user tokens

### Product Management
- Product listing with images, names, and prices
- Product detail page with descriptions and variants
- Category browsing and filtering
- Search functionality with real-time results
- Product sale badges and stock indicators

### Shopping Cart
- Add/Remove products from cart
- Update quantities
- Persistent cart storage (saved locally)
- Real-time cart total calculation
- Cart badge showing item count

### Checkout Flow
- Customer information form (name, email, phone, address)
- Shipping method selection with pricing
- Payment method selection
- Order summary and review
- Order confirmation screen
- Form validation throughout

### User Account
- User registration and login
- Profile management
- Order history with detailed views
- Secure authentication storage

## Architecture

The app follows **Clean Architecture** principles:

```
lib/
├── config/           # Configuration files (API, Theme)
├── models/           # Data models
├── services/         # API services
├── providers/        # State management (Provider)
├── screens/          # UI screens
│   ├── home/
│   ├── product/
│   ├── category/
│   ├── cart/
│   ├── checkout/
│   └── profile/
├── widgets/          # Reusable widgets
└── main.dart         # App entry point
```

## Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- PrestaShop store with webservice enabled
- PrestaShop API key

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd prestashop-mobile-app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Environment Variables

Create a `.env` file in the root directory:

```env
PRESTASHOP_BASE_URL=https://your-prestashop-store.com
PRESTASHOP_API_KEY=YOUR_WEBSERVICE_KEY_HERE
DEBUG_MODE=true
```

**Important:** Replace the values with your actual PrestaShop store details.

### 4. PrestaShop API Setup

#### Enable Webservice in PrestaShop:

1. Log in to your PrestaShop admin panel
2. Go to **Advanced Parameters** > **Webservice**
3. Enable the webservice option
4. Click **Add new webservice key**
5. Configure permissions for the key:
   - **Products**: GET
   - **Categories**: GET
   - **Orders**: GET, POST, PUT
   - **Customers**: GET, POST, PUT
   - **Addresses**: GET, POST, PUT
   - **Carriers**: GET
   - **Carts**: GET, POST, PUT
6. Copy the generated API key

#### Required PrestaShop API Endpoints:

The app uses the following PrestaShop API endpoints:

- `/api/products` - Product listing and details
- `/api/categories` - Category browsing
- `/api/orders` - Order creation and history
- `/api/customers` - Customer management
- `/api/addresses` - Shipping addresses
- `/api/carriers` - Shipping methods
- `/api/carts` - Shopping cart management

### 5. Run the App

```bash
flutter run
```

## Dependencies

### Core Dependencies
- **provider** (^6.1.1) - State management
- **http** (^1.1.0) - HTTP requests
- **flutter_dotenv** (^5.1.0) - Environment variables

### Storage
- **shared_preferences** (^2.2.2) - Local storage
- **flutter_secure_storage** (^9.0.0) - Secure token storage

### UI Components
- **cached_network_image** (^3.3.1) - Image caching
- **flutter_spinkit** (^5.2.0) - Loading indicators
- **shimmer** (^3.0.0) - Shimmer effects
- **pull_to_refresh** (^2.0.0) - Pull to refresh

### Utilities
- **xml** (^6.5.0) - XML parsing for PrestaShop
- **email_validator** (^2.1.17) - Email validation
- **intl** (^0.19.0) - Internationalization and formatting

## Project Structure Details

### Models (`lib/models/`)
- `product.dart` - Product and ProductVariant models
- `category.dart` - Category model
- `cart_item.dart` - Cart item model
- `customer.dart` - Customer model
- `address.dart` - Address model
- `carrier.dart` - Shipping carrier model
- `order.dart` - Order model

### Services (`lib/services/`)
- `api_service.dart` - Base API service with authentication
- `product_service.dart` - Product-related API calls
- `category_service.dart` - Category-related API calls
- `order_service.dart` - Order management
- `customer_service.dart` - Customer management
- `carrier_service.dart` - Shipping methods

### Providers (`lib/providers/`)
- `product_provider.dart` - Product state management
- `category_provider.dart` - Category state management
- `cart_provider.dart` - Shopping cart state
- `order_provider.dart` - Order state management
- `auth_provider.dart` - Authentication state

### Screens

#### Home (`lib/screens/home/`)
- Product listing with grid view
- Search functionality
- Pull to refresh
- Cart badge

#### Product (`lib/screens/product/`)
- Product detail view
- Image display
- Variant selection
- Add to cart

#### Category (`lib/screens/category/`)
- Category grid view
- Category products listing

#### Cart (`lib/screens/cart/`)
- Cart items list
- Quantity management
- Total calculation
- Checkout navigation

#### Checkout (`lib/screens/checkout/`)
- Multi-step checkout form
- Customer information
- Shipping address
- Payment and shipping selection
- Order confirmation

#### Profile (`lib/screens/profile/`)
- User profile display
- Login/Register
- Order history
- Account settings

### Reusable Widgets (`lib/widgets/`)
- `product_card.dart` - Product grid item
- `category_card.dart` - Category grid item
- `cart_item_widget.dart` - Cart item display
- `loading_widget.dart` - Loading indicators
- `error_widget.dart` - Error display
- `empty_state_widget.dart` - Empty state display

## Configuration

### API Configuration (`lib/config/api_config.dart`)

Update API endpoints and parameters as needed:

```dart
class ApiConfig {
  static String get baseUrl => dotenv.env['PRESTASHOP_BASE_URL'] ?? '';
  static String get apiKey => dotenv.env['PRESTASHOP_API_KEY'] ?? '';
  static const String outputFormat = 'JSON';
  // ... other configurations
}
```

### Theme Configuration (`lib/config/app_theme.dart`)

Customize the app theme:

```dart
class AppTheme {
  static const Color primaryColor = Color(0xFF2C3E50);
  static const Color accentColor = Color(0xFF3498DB);
  // ... other colors
}
```

## Features Implementation Status

- ✅ Bottom Navigation with 4 tabs
- ✅ Product listing and search
- ✅ Category browsing
- ✅ Product detail view
- ✅ Shopping cart management
- ✅ Multi-step checkout flow
- ✅ Customer information form with validation
- ✅ Shipping method selection
- ✅ Payment method selection
- ✅ Order placement
- ✅ Order history
- ✅ User authentication
- ✅ Pull to refresh
- ✅ Image caching
- ✅ Error handling
- ✅ Loading states
- ✅ Secure storage

## Security Considerations

1. **API Key Storage**: API keys are stored in `.env` file (not committed to version control)
2. **Secure Storage**: User tokens stored using `flutter_secure_storage`
3. **HTTPS**: Ensure PrestaShop API is accessed via HTTPS
4. **Input Validation**: All forms include validation
5. **Error Handling**: Comprehensive error handling throughout the app

## Troubleshooting

### Common Issues

#### API Connection Failed
- Verify `.env` file exists and contains correct credentials
- Check PrestaShop webservice is enabled
- Ensure API key has proper permissions
- Verify base URL includes protocol (https://)

#### Empty Product List
- Check API key permissions for products endpoint
- Verify products exist in PrestaShop admin
- Check debug mode logs for API response

#### Cart Not Persisting
- Ensure `shared_preferences` is properly initialized
- Check app permissions for local storage

#### Build Errors
```bash
flutter clean
flutter pub get
flutter run
```

## Testing

To test the app without a real PrestaShop backend:

1. Update API service to return mock data
2. Use the included sample responses
3. Test UI components independently

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is open-source and available under the MIT License.

## Support

For issues and questions:
- Check the troubleshooting section
- Review PrestaShop API documentation
- Open an issue in the repository

## Future Enhancements

Potential features for future releases:
- Product reviews and ratings
- Wishlist functionality
- Multiple language support
- Dark mode theme
- Push notifications
- Social login
- Product filters and sorting
- Advanced search
- Payment gateway integration
- Offline mode

## Credits

Built with Flutter and PrestaShop API integration.

---

**Note:** This is a complete e-commerce application template. Customize it according to your specific PrestaShop store requirements and branding.
