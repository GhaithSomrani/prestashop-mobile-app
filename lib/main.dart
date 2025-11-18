import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'config/api_config.dart';
import 'config/app_theme.dart';
import 'services/api_service.dart';
import 'services/product_service.dart';
import 'services/category_service.dart';
import 'services/order_service.dart';
import 'services/customer_service.dart';
import 'services/carrier_service.dart';
import 'providers/product_provider.dart';
import 'providers/category_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/category/category_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize services
    final apiService = ApiService(
      baseUrl: ApiConfig.baseUrl,
      apiKey: ApiConfig.apiKey,
    );

    final productService = ProductService(apiService);
    final categoryService = CategoryService(apiService);
    final orderService = OrderService(apiService);
    final customerService = CustomerService(apiService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProductProvider(productService),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(categoryService),
        ),
        ChangeNotifierProvider(
          create: (_) => CartProvider()..loadCart(),
        ),
        ChangeNotifierProvider(
          create: (_) => OrderProvider(orderService),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(customerService)..checkAuthentication(),
        ),
      ],
      child: MaterialApp(
        title: 'PrestaShop Mobile App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CategoryScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
