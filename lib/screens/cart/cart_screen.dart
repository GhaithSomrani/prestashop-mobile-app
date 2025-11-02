import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/cart.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../config/app_config.dart';
import '../../utils/helpers.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCart();
    });
  }

  Future<void> _loadCart() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    await cartProvider.init();
  }

  Future<void> _updateQuantity(String uniqueId, int quantity) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    await cartProvider.updateQuantity(uniqueId, quantity);
  }

  Future<void> _removeItem(String uniqueId) async {
    final confirmed = await _showConfirmDialog();
    if (confirmed) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await cartProvider.removeFromCart(uniqueId);
    }
  }

  Future<bool> _showConfirmDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove Item'),
            content: const Text('Are you sure you want to remove this item from your cart?'),
            actions: [
              TextButton(
                onPressed: () => context.pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => context.pop(true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _onCheckout() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      context.push('/login');
    } else {
      context.push('/checkout');
    }
  }

  void _onContinueShopping() {
    context.push('/products');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isLoading && cartProvider.items.isEmpty) {
            return const LoadingWidget(message: 'Loading cart...');
          }

          if (cartProvider.status == CartStatus.error) {
            return _buildErrorWidget(cartProvider.errorMessage);
          }

          if (cartProvider.isEmpty) {
            return _buildEmptyCart();
          }

          return Column(
            children: [
              Expanded(
                child: _buildCartItems(cartProvider),
              ),
              _buildOrderSummary(cartProvider),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Shopping Cart'),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 2,
      actions: [
        Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            if (cartProvider.isNotEmpty) {
              return TextButton(
                onPressed: () async {
                  final confirmed = await _showClearCartDialog();
                  if (confirmed) {
                    await cartProvider.clearCart();
                  }
                },
                child: const Text('Clear'),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildCartItems(CartProvider cartProvider) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      itemCount: cartProvider.items.length,
      itemBuilder: (context, index) {
        final item = cartProvider.items[index];
        return _buildCartItem(item, cartProvider);
      },
    );
  }

  Widget _buildCartItem(CartItem item, CartProvider cartProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConfig.defaultPadding),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.imageUrl?.isNotEmpty == true
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, error, stackTrace) {
                          return Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                          );
                        },
                      )
                    : Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                      ),
              ),
            ),
            const SizedBox(width: AppConfig.defaultPadding),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName ?? 'Product',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Helpers.formatPriceWithSymbol(item.unitPrice),
                    style: TextStyle(
                      fontSize: 16,
                      color: AppConfig.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Quantity controls
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: item.quantity > 1
                                  ? () => _updateQuantity(item.uniqueId, item.quantity - 1)
                                  : null,
                              icon: const Icon(Icons.remove),
                              iconSize: 16,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: item.quantity < 99
                                  ? () => _updateQuantity(item.uniqueId, item.quantity + 1)
                                  : null,
                              icon: const Icon(Icons.add),
                              iconSize: 16,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Remove button
                      IconButton(
                        onPressed: () => _removeItem(item.uniqueId),
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Price breakdown
          _buildPriceRow('Subtotal', cartProvider.formattedSubtotal),
          _buildPriceRow('Shipping', cartProvider.formattedShipping),
          _buildPriceRow('Tax', cartProvider.formattedTax),
          const Divider(height: 24),
          _buildPriceRow(
            'Total',
            cartProvider.formattedTotal,
            isBold: true,
            fontSize: 18,
          ),
          const SizedBox(height: AppConfig.defaultPadding),
          // Free shipping progress
          if (!cartProvider.qualifiesForFreeShipping) ...[
            _buildFreeShippingProgress(cartProvider),
            const SizedBox(height: AppConfig.defaultPadding),
          ],
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _onContinueShopping,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppConfig.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Continue Shopping',
                    style: TextStyle(
                      color: AppConfig.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppConfig.defaultPadding),
              Expanded(
                child: ElevatedButton(
                  onPressed: _onCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Checkout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false, double fontSize = 16}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeShippingProgress(CartProvider cartProvider) {
    final progress = cartProvider.freeShippingProgress;
    final amountNeeded = cartProvider.amountForFreeShipping;

    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 16,
              color: AppConfig.primaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                amountNeeded > 0
                    ? 'Add \$${amountNeeded.toStringAsFixed(2)} more for free shipping!'
                    : 'You qualify for free shipping!',
                style: TextStyle(
                  fontSize: 14,
                  color: AppConfig.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(AppConfig.primaryColor),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppConfig.defaultPadding),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some products to get started!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppConfig.largePadding),
          ElevatedButton(
            onPressed: _onContinueShopping,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Start Shopping',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String? errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: AppConfig.defaultPadding),
          Text(
            errorMessage ?? 'An error occurred',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConfig.defaultPadding),
          ElevatedButton(
            onPressed: _loadCart,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showClearCartDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Clear Cart'),
            content: const Text('Are you sure you want to clear your entire cart?'),
            actions: [
              TextButton(
                onPressed: () => context.pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => context.pop(true),
                child: const Text('Clear'),
              ),
            ],
          ),
        ) ??
        false;
  }
}