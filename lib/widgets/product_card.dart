import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../config/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../l10n/app_localizations.dart';

/// Modern Product Card with soft shadows and clean design
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final bool showAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.showAddToCart = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Section
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusMedium),
                    ),
                    child: product.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppTheme.backgroundWhite,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.secondaryGrey,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppTheme.backgroundWhite,
                              child: const Icon(
                                Icons.image_outlined,
                                size: 40,
                                color: AppTheme.lightGrey,
                              ),
                            ),
                          )
                        : Container(
                            color: AppTheme.backgroundWhite,
                            child: const Center(
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                size: 40,
                                color: AppTheme.lightGrey,
                              ),
                            ),
                          ),
                  ),

                  // Sale Badge
                  if (product.isOnSale)
                    Positioned(
                      top: AppTheme.spacing1,
                      left: AppTheme.spacing1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing1,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Text(
                          '-${product.calculatedDiscountPercentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: AppTheme.pureWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),

                  // Out of Stock Overlay
                  if (!product.inStock)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppTheme.radiusMedium),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            l10n?.outOfStock ?? 'Rupture de stock',
                            style: const TextStyle(
                              color: AppTheme.primaryBlack,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Product Info Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: AppTheme.primaryBlack,
                        height: 1.3,
                      ),
                    ),

                    // Price Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.isOnSale)
                          Text(
                            CurrencyFormatter.formatTND(product.price),
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: AppTheme.secondaryGrey,
                              fontSize: 11,
                            ),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                CurrencyFormatter.formatTND(product.finalPrice),
                                style: const TextStyle(
                                  color: AppTheme.primaryBlack,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Quick Add Button
                            if (showAddToCart)
                              Consumer<CartProvider>(
                                builder: (context, cart, child) {
                                  final isInCart = cart.isInCart(product.id);
                                  return GestureDetector(
                                    onTap: product.inStock
                                        ? () {
                                            if (!isInCart) {
                                              cart.addItem(product);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(l10n?.addedToCart ?? 'Ajouté au panier'),
                                                  duration: const Duration(seconds: 1),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
                                          }
                                        : null,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: isInCart
                                            ? AppTheme.successGreen
                                            : (product.inStock ? AppTheme.primaryBlack : AppTheme.lightGrey),
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusSmall,
                                        ),
                                      ),
                                      child: Icon(
                                        isInCart
                                            ? Icons.check
                                            : Icons.add_shopping_cart_outlined,
                                        size: 16,
                                        color: AppTheme.pureWhite,
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
