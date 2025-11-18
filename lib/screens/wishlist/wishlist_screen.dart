import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../widgets/empty_state_widget.dart';

/// Wishlist Screen - Simple implementation
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.pureWhite,
        title: const Text(
          'Wishlist',
          style: TextStyle(
            color: AppTheme.primaryBlack,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: EmptyStateWidget(
        icon: Icons.favorite_outline,
        title: 'Your Wishlist is Empty',
        message: 'Save your favorite items here',
        onAction: () {
          // Navigate to home - handled by bottom nav
        },
        actionLabel: 'Start Shopping',
      ),
    );
  }
}
