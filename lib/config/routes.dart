import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/catalog/products_screen.dart';
import '../screens/catalog/product_details_screen.dart';
import '../screens/catalog/search_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/cart/checkout_screen.dart';
import '../screens/account/profile_screen.dart';
import '../screens/account/orders_screen.dart';
import '../screens/account/order_details_screen.dart';
import '../widgets/main_navigation.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.location}',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainNavigation(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainNavigation(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) {
          final categoryId = state.queryParameters['category_id'];
          return ProductsScreen(categoryId: categoryId);
        },
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final productId = state.pathParameters['id']!;
          return ProductDetailsScreen(productId: int.parse(productId));
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) {
          final query = state.queryParameters['q'];
          return SearchScreen(initialQuery: query);
        },
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/order/:id',
        builder: (context, state) {
          final orderId = state.pathParameters['id']!;
          return OrderDetailsScreen(orderId: int.parse(orderId));
        },
      ),
    ],
  );
}