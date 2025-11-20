import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../config/app_theme.dart';
import '../../widgets/product_card.dart';
import '../../widgets/loading_widget.dart';
import '../product/product_detail_screen.dart';

enum ProductListType {
  featured,
  newProducts,
  bestSales,
  pricesDrop,
}

class ProductListScreen extends StatefulWidget {
  final ProductListType listType;

  const ProductListScreen({
    super.key,
    required this.listType,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  void _loadProducts() {
    final productProvider = context.read<ProductProvider>();
    switch (widget.listType) {
      case ProductListType.featured:
        productProvider.fetchFeaturedProducts();
        break;
      case ProductListType.newProducts:
        productProvider.fetchLatestProducts();
        break;
      case ProductListType.bestSales:
        productProvider.fetchBestSalesProducts();
        break;
      case ProductListType.pricesDrop:
        productProvider.fetchPricesDropProducts();
        break;
    }
  }

  String get _title {
    switch (widget.listType) {
      case ProductListType.featured:
        return 'Featured Products';
      case ProductListType.newProducts:
        return 'New Products';
      case ProductListType.bestSales:
        return 'Best Sales';
      case ProductListType.pricesDrop:
        return 'Prices Drop';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          final products = _getProducts(productProvider);

          if (productProvider.isLoading && products.isEmpty) {
            return const LoadingWidget(message: 'Loading products...');
          }

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No products found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadProducts(),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                          productId: product.id,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  List _getProducts(ProductProvider provider) {
    switch (widget.listType) {
      case ProductListType.featured:
        return provider.featuredProducts;
      case ProductListType.newProducts:
        return provider.latestProducts;
      case ProductListType.bestSales:
        return provider.bestSalesProducts;
      case ProductListType.pricesDrop:
        return provider.pricesDropProducts;
    }
  }
}
