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

/// Category Products Screen with infinite scroll and dynamic filtering
class CategoryProductsScreen extends StatefulWidget {
  final Category category;
  final List<Category>? parentCategories;

  const CategoryProductsScreen({
    super.key,
    required this.category,
    this.parentCategories,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isGridView = true;
  String? _currentSortBy;

  @override
  void initState() {
    super.initState();

    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProductsByCategory(
            widget.category.id,
            reset: true,
          );
    });

    // Setup infinite scroll listener
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Trigger load more when 80% scrolled
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    final provider = context.read<ProductProvider>();
    if (!provider.isLoadingMore && provider.hasMore) {
      await provider.loadMoreCategoryProducts(
        widget.category.id,
        sortBy: _currentSortBy,
      );
    }
  }

  Future<void> _refresh() async {
    await context.read<ProductProvider>().refreshProducts(
          categoryId: widget.category.id,
        );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXLarge)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacing2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort By',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlack,
              ),
            ),
            const SizedBox(height: AppTheme.spacing2),
            _buildSortOption('Newest', 'id_DESC'),
            _buildSortOption('Price: Low to High', 'price_ASC'),
            _buildSortOption('Price: High to Low', 'price_DESC'),
            _buildSortOption('Name: A-Z', 'name_ASC'),
            _buildSortOption('Name: Z-A', 'name_DESC'),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String sortBy) {
    final isSelected = _currentSortBy == sortBy;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryBlack : AppTheme.secondaryGrey,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppTheme.primaryBlack)
          : null,
      onTap: () {
        setState(() => _currentSortBy = sortBy);
        Navigator.pop(context);
        context.read<ProductProvider>().fetchProductsByCategory(
              widget.category.id,
              sortBy: sortBy,
              reset: true,
            );
      },
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        categoryId: widget.category.id,
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

    if (widget.parentCategories != null) {
      for (var parent in widget.parentCategories!) {
        breadcrumbs.add(
          BreadcrumbItem(
            label: parent.name,
            onTap: () {
              Navigator.pop(context);
            },
          ),
        );
      }
    }

    breadcrumbs.add(
      BreadcrumbItem(label: widget.category.name),
    );

    return breadcrumbs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.pureWhite,
        elevation: 0,
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
          // Sort Button
          IconButton(
            icon: const Icon(Icons.sort, color: AppTheme.primaryBlack),
            onPressed: _showSortOptions,
            tooltip: 'Sort',
          ),
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
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
          // Filter Button
          IconButton(
            icon: const Icon(Icons.tune, color: AppTheme.primaryBlack),
            onPressed: _showFilters,
            tooltip: 'Filters',
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
              builder: (context, provider, child) {
                if (provider.isLoading && provider.products.isEmpty) {
                  return const LoadingWidget(message: 'Loading products...');
                }

                if (provider.hasError && provider.products.isEmpty) {
                  return ErrorDisplayWidget(
                    message: provider.error ?? 'Unknown error',
                    onRetry: () {
                      provider.fetchProductsByCategory(
                        widget.category.id,
                        reset: true,
                      );
                    },
                  );
                }

                if (provider.products.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.shopping_bag_outlined,
                    title: 'No Products Found',
                    message: 'This category has no products yet',
                    onAction: () => Navigator.pop(context),
                    actionLabel: 'Go Back',
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  color: AppTheme.primaryBlack,
                  child: Column(
                    children: [
                      // Product Count & Sort Info
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing2,
                          vertical: AppTheme.spacing1,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${provider.products.length} item${provider.products.length != 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.secondaryGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_currentSortBy != null)
                              Text(
                                'Sorted',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.secondaryGrey,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Products Grid/List
                      Expanded(
                        child: _isGridView
                            ? _buildGridView(provider)
                            : _buildListView(provider),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(ProductProvider provider) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppTheme.spacing2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: AppTheme.spacing2,
        mainAxisSpacing: AppTheme.spacing2,
      ),
      itemCount: provider.products.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator at bottom
        if (index == provider.products.length) {
          return Center(
            child: provider.isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.all(AppTheme.spacing2),
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryBlack,
                      strokeWidth: 2,
                    ),
                  )
                : const SizedBox.shrink(),
          );
        }

        final product = provider.products[index];
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

  Widget _buildListView(ProductProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppTheme.spacing2),
      itemCount: provider.products.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator at bottom
        if (index == provider.products.length) {
          return Center(
            child: provider.isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.all(AppTheme.spacing2),
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryBlack,
                      strokeWidth: 2,
                    ),
                  )
                : const SizedBox.shrink(),
          );
        }

        final product = provider.products[index];
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacing2),
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
