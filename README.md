# PrestaShop Mobile App

A complete Flutter mobile application for PrestaShop e-commerce stores. This app provides a native mobile shopping experience with full integration to PrestaShop's Web Service API.

## Features

### Core Features
- **Product Catalog**
  - Browse products with images, prices, and descriptions
  - Product search with real-time results
  - Category-based filtering
  - Product details with variants support
  - Pull-to-refresh functionality
  - Infinite scroll pagination

- **Shopping Cart**
  - Add/remove products
  - Update quantities
  - Cart persistence (local storage)
  - Real-time price calculations
  - Free shipping threshold indicator

- **Order Management**
  - Complete checkout flow
  - Customer information form
  - Shipping address management
  - Multiple shipping methods
  - Payment method selection
  - Order confirmation
  - Order history with details
  - Order status tracking

- **User Account**
  - Customer registration
  - Login/logout
  - Profile management
  - Address book
  - Order history
  - Favorites/Wishlist

- **Navigation**
  - Bottom navigation with 4 tabs (Home, Products, Cart, Profile)
  - Intuitive routing with go_router
  - Deep linking support

### Technical Features
- **State Management**: Provider/Riverpod architecture
- **API Integration**: Complete PrestaShop Web Service API integration
- **Secure Storage**: Flutter secure storage for sensitive data
- **Image Caching**: Cached network images for better performance
- **Error Handling**: Comprehensive error handling and user feedback
- **Form Validation**: Client-side validation for all forms
- **Responsive Design**: Adaptive UI for different screen sizes
- **Loading States**: Skeleton screens and loading indicators

## Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.10.0 or higher) - [Installation Guide](https://docs.flutter.dev/get-started/install)
- **Dart** (3.0.0 or higher)
- **Android Studio** or **Xcode** (for iOS development)
- **PrestaShop Store** with Web Service API enabled (PrestaShop 1.7+ recommended)

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/prestashop-mobile-app.git
cd prestashop-mobile-app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Generate JSON Serialization Code

This project uses `json_serializable` for model serialization. Generate the required `.g.dart` files:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

For development with auto-regeneration:

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 4. Configure API Settings

Edit `lib/config/app_config.dart`:

```dart
class AppConfig {
  static const String apiBaseUrl = 'https://yourstore.com/api';
  static const String apiKey = 'YOUR_API_KEY_HERE';
  static const String currencySymbol = '\$';
  static const String currencyCode = 'USD';
  // ... other settings
}
```

Or use the `.env.example` file (copy to `.env` and update values).

### 5. Run the App

```bash
flutter run
```

## PrestaShop Configuration

### Enable Web Service API

1. Log in to your PrestaShop admin panel
2. Navigate to **Advanced Parameters** > **Webservice**
3. Enable **Enable PrestaShop Webservice**
4. Click **Add new web service key**
5. Configure permissions for the key:
   - **customers**: GET, POST, PUT (for authentication and registration)
   - **products**: GET (for product catalog)
   - **categories**: GET (for category browsing)
   - **carts**: GET, POST, PUT (for cart management)
   - **orders**: GET, POST (for order placement and history)
   - **addresses**: GET, POST, PUT, DELETE (for address management)
   - **countries**: GET (for address forms)
   - **states**: GET (for address forms)
6. Copy the generated API key and update `app_config.dart`

## Project Structure

```
lib/
├── config/              # Configuration files
├── models/              # Data models
├── providers/           # State management (Provider)
├── screens/             # UI screens
├── services/            # API services
├── utils/               # Utility functions
├── widgets/             # Reusable widgets
└── main.dart            # App entry point
```

## API Endpoints Used

- `GET /products` - List products
- `GET /products/{id}` - Product details
- `GET /categories` - List categories
- `GET /carts/{id}` - Get cart
- `POST /orders` - Create order
- `GET /customers` - Find customer (login)
- `POST /customers` - Register customer

See full list in [README sections above](#api-endpoints-used).

## State Management

This app uses **Provider** for state management with the following key providers:

- **AuthProvider**: Authentication state
- **CartProvider**: Shopping cart state
- **ProductProvider**: Product catalog and filters
- **OrderProvider**: Order placement and history

## Troubleshooting

### Build runner fails
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### API connection fails
1. Verify `apiBaseUrl` in `app_config.dart`
2. Check API key permissions in PrestaShop
3. Ensure Web Service is enabled
4. Verify SSL certificate

### Images not loading
1. Check image URLs in API response
2. Verify network permissions in AndroidManifest.xml / Info.plist

## Building for Production

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Open an issue on GitHub
- Check [PrestaShop Web Service Documentation](https://devdocs.prestashop.com/1.7/webservice/)
- Flutter documentation: https://flutter.dev/docs

---

**Built with ❤️ using Flutter and PrestaShop**
