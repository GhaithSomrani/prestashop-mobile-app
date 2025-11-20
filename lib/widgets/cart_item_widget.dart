import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../config/app_theme.dart';

/// Modern Cart Item Widget with quantity controls
class CartItemWidget extends StatelessWidget {
  final CartItem item;

  const CartItemWidget({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              child: item.product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.product.imageUrl!,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 90,
                        height: 90,
                        color: AppTheme.backgroundWhite,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 90,
                        height: 90,
                        color: AppTheme.backgroundWhite,
                        child: const Icon(
                          Icons.image_outlined,
                          color: AppTheme.lightGrey,
                        ),
                      ),
                    )
                  : Container(
                      width: 90,
                      height: 90,
                      color: AppTheme.backgroundWhite,
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: AppTheme.lightGrey,
                      ),
                    ),
            ),
            const SizedBox(width: AppTheme.spacing2),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.primaryBlack,
                          ),
                        ),
                      ),
                      // Remove Button
                      GestureDetector(
                        onTap: () {
                          cart.removeItem(item.product.id, variantId: item.variantId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Item removed from cart'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: AppTheme.secondaryGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.product.finalPrice.toStringAsFixed(2)} TND',
                    style: const TextStyle(
                      color: AppTheme.primaryBlack,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing1),

                  // Quantity Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundWhite,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                cart.decrementQuantity(
                                  item.product.id,
                                  variantId: item.variantId,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                child: const Icon(
                                  Icons.remove,
                                  size: 18,
                                  color: AppTheme.primaryBlack,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryBlack,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                cart.incrementQuantity(
                                  item.product.id,
                                  variantId: item.variantId,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                child: const Icon(
                                  Icons.add,
                                  size: 18,
                                  color: AppTheme.primaryBlack,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${item.totalPrice.toStringAsFixed(2)} TND',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.primaryBlack,
                        ),
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
}
