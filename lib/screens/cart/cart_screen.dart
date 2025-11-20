import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/cart_item_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../config/app_theme.dart';
import '../checkout/enhanced_checkout_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/currency_formatter.dart';

/// Modern Cart Screen with clean white minimal UI
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.pureWhite,
        title: Text(
          l10n?.cart ?? 'Panier',
          style: const TextStyle(
            color: AppTheme.primaryBlack,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              if (cart.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      title: Text(l10n?.clearCart ?? 'Vider le panier'),
                      content: Text('Êtes-vous sûr de vouloir vider le panier?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n?.cancel ?? 'Annuler'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            cart.clearCart();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.errorRed,
                          ),
                          child: Text(l10n?.delete ?? 'Supprimer'),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(l10n?.clearCart ?? 'Vider'),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.shopping_cart_outlined,
              title: l10n?.cartEmpty ?? 'Votre panier est vide',
              message: 'Ajoutez des produits pour commencer',
              onAction: () {
                // Navigate to home - handled by bottom nav
              },
              actionLabel: l10n?.startShopping ?? 'Commencer vos achats',
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacing2),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spacing2),
                      child: CartItemWidget(item: cart.items[index]),
                    );
                  },
                ),
              ),

              // Cart Summary Card
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing2),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  boxShadow: AppTheme.mediumShadow,
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Subtotal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${l10n?.subtotal ?? 'Sous-total'}:',
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppTheme.secondaryGrey,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatTND(cart.totalAmount),
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppTheme.secondaryGrey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing1),

                      // Shipping
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Livraison:',
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppTheme.secondaryGrey,
                            ),
                          ),
                          Text(
                            l10n?.free ?? 'Gratuit',
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppTheme.successGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: AppTheme.spacing3),

                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${l10n?.total ?? 'Total'} (${cart.itemCount} ${l10n?.items ?? 'articles'}):',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlack,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatTND(cart.totalAmount),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlack,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppTheme.spacing2),

                      // Checkout Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EnhancedCheckoutScreen(),
                              ),
                            );
                          },
                          child: Text(
                            l10n?.proceedToCheckout ?? 'Passer à la caisse',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
