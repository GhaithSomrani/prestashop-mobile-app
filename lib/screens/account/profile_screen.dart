import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../config/app_config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return _buildLoginPrompt();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Account'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 2,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConfig.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserHeader(authProvider),
                const SizedBox(height: 32),
                _buildMenuItems(authProvider),
                const SizedBox(height: 32),
                _buildLogoutButton(authProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginPrompt() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 2,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Please login to access your account',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Login',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(AuthProvider authProvider) {
    final user = authProvider.user!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConfig.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConfig.cardBorderRadius),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppConfig.primaryColor,
            child: Text(
              '${user.firstName[0]}${user.lastName[0]}'.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Edit profile
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(AuthProvider authProvider) {
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.shopping_bag_outlined,
          title: 'My Orders',
          subtitle: '${authProvider.orderCount} orders',
          onTap: () => context.push('/orders'),
        ),
        _buildMenuItem(
          icon: Icons.location_on_outlined,
          title: 'Shipping Addresses',
          subtitle: '${authProvider.addresses.length} addresses',
          onTap: () {
            // Navigate to addresses
          },
        ),
        _buildMenuItem(
          icon: Icons.favorite_outline,
          title: 'Favorites',
          subtitle: 'View favorite products',
          onTap: () {
            // Navigate to favorites
          },
        ),
        _buildMenuItem(
          icon: Icons.payment_outlined,
          title: 'Payment Methods',
          subtitle: 'Manage payment options',
          onTap: () {
            // Navigate to payment methods
          },
        ),
        _buildMenuItem(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Manage notifications',
          onTap: () {
            // Navigate to notifications
          },
        ),
        _buildMenuItem(
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: 'App settings and preferences',
          onTap: () {
            // Navigate to settings
          },
        ),
        _buildMenuItem(
          icon: Icons.help_outline,
          title: 'Help & Support',
          subtitle: 'Get help and support',
          onTap: () {
            // Navigate to help
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppConfig.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(AuthProvider authProvider) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: authProvider.isLoading ? null : () async {
              await authProvider.logout();
              if (mounted) {
                context.go('/');
              }
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.red[400]!),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: authProvider.isLoading
                ? const CircularProgressIndicator()
                : Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red[400],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        );
      },
    );
  }
}