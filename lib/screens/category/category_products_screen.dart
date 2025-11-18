import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/category.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/breadcrumb_bar.dart';
import '../../widgets/filter_bottom_sheet.dart';
import '../product/product_detail_screen.dart';

/// Category Products Screen with PrestaShop-style breadcrumbs
class CategoryProductsScreen extends StatefulWidget {
  final Category category;
  final List<Category>? parentCategories; // For breadcrumb hierarchy

  const CategoryProductsScreen({
    super.key,
    required this.category,
    this.parentCategories,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  bool _isGridView = true;
  FilterOptions? _currentFilters;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false)
          .fetchProducts(categoryId: widget.category.id);
    });
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: FilterBottomSheet(
          initialFilters: _currentFilters,
          onApplyFilters: (filters) {
            setState(() {
              _currentFilters = filters;
            });
            // Apply filters to product list
          },
        ),
      ),
    );
  }

  List<BreadcrumbItem> _buildBreadcrumbs() {
    final breadcrumbs = <BreadcrumbItem>[
      BreadcrumbItem(
        label: 'Home',
        onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
      ),
    ];

    // Add parent categories if available
    if (widget.parentCategories != null) {
      for (var parent in widget.parentCategories!) {
        breadcrumbs.add(
          BreadcrumbItem(
            label: parent.name,
            onTap: () {
              // Navigate to parent category
            },
          ),
        );
      }
    }

    // Add current category
    breadcrumbs.add(
      BreadcrumbItem(
        label: widget.category.name,
      ),
    );

    return breadcrumbs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.pureWhite,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category.name,
          style: const TextStyle(
            color: AppTheme.primaryBlack,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Grid/List Toggle
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list : Icons.grid_view,
              color: AppTheme.primaryBlack,
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          // Filter Button
          IconButton(
            icon: const Icon(Icons.tune, color: AppTheme.primaryBlack),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Breadcrumb Navigation
          BreadcrumbBar(items: _buildBreadcrumbs()),

          // Product List
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading) {
                  return const LoadingWidget(message: 'Loading products...');
                }

                if (productProvider.hasError) {
                  return ErrorDisplayWidget(
                    message: productProvider.error ?? 'Unknown error',
                    onRetry: () {
                      productProvider.fetchProducts(categoryId: widget.category.id);
                    },
                  );
                }

                if (productProvider.products.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.shopping_bag_outlined,
                    title: 'No Products Found',
                    message: 'This category has no products yet',
                    onAction: () {
                      Navigator.pop(context);
                    },
                    actionLabel: 'Go Back',
                  );
                }

                return Column(
                  children: [
                    // Product Count
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing2,
                        vertical: AppTheme.spacing1,
                      ),
                      child: Text(
                        '${productProvider.products.length} items',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.secondaryGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Products
                    Expanded(
                      child: _isGridView
                          ? _buildGridView(productProvider)
                          : _buildListView(productProvider),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(ProductProvider productProvider) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: AppTheme.spacing2,
        mainAxisSpacing: AppTheme.spacing2,
      ),
      itemCount: productProvider.products.length,
      itemBuilder: (context, index) {
        final product = productProvider.products[index];
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
    );
  }

  Widget _buildListView(ProductProvider productProvider) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing2),
      itemCount: productProvider.products.length,
      itemBuilder: (context, index) {
        final product = productProvider.products[index];
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacing2),
          height: 120,
          child: ProductCard(
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
          ),
        );
      },
    );
  }
}

