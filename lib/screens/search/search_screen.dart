import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/product_provider.dart';
import '../../widgets/custom_search_bar.dart';
import '../../widgets/product_card.dart';
import '../../widgets/filter_bottom_sheet.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../product/product_detail_screen.dart';

/// Modern Search Screen with auto-suggestions and filters
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _recentSearches = [
    'Running shoes',
    'Wireless headphones',
    'Summer dress',
    'Laptop bag',
  ];

  bool _isSearching = false;
  FilterOptions? _currentFilters;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isNotEmpty) {
      setState(() {
        _isSearching = true;
      });
      Provider.of<ProductProvider>(context, listen: false).searchProducts(query);
    }
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
        title: const Text(
          'Search',
          style: TextStyle(
            color: AppTheme.primaryBlack,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar Section
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing2),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomSearchBar(
                    controller: _searchController,
                    hintText: 'Search products...',
                    onChanged: (value) {
                      if (value.isEmpty) {
                        setState(() {
                          _isSearching = false;
                        });
                      }
                    },
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: AppTheme.spacing1),
                // Filter Button
                GestureDetector(
                  onTap: _showFilters,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlack,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: const Icon(
                      Icons.tune,
                      color: AppTheme.pureWhite,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Button
          if (_searchController.text.isNotEmpty && !_isSearching)
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing2),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _performSearch(_searchController.text),
                  child: const Text('Search'),
                ),
              ),
            ),

          // Content
          Expanded(
            child: _isSearching
                ? _buildSearchResults()
                : _buildRecentSearches(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlack,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Clear recent searches
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing1),
          Wrap(
            spacing: AppTheme.spacing1,
            runSpacing: AppTheme.spacing1,
            children: _recentSearches.map((search) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = search;
                  _performSearch(search);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing2,
                    vertical: AppTheme.spacing1,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.history,
                        size: 16,
                        color: AppTheme.secondaryGrey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        search,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppTheme.spacing3),
          const Text(
            'Popular Searches',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlack,
            ),
          ),
          const SizedBox(height: AppTheme.spacing1),
          ...['Sneakers', 'T-shirts', 'Watches', 'Backpacks', 'Sunglasses']
              .map((item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.trending_up,
                      color: AppTheme.secondaryGrey,
                    ),
                    title: Text(item),
                    onTap: () {
                      _searchController.text = item;
                      _performSearch(item);
                    },
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.isLoading) {
          return const LoadingWidget(message: 'Searching...');
        }

        if (productProvider.products.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.search_off,
            title: 'No Results Found',
            message: 'Try searching with different keywords',
            onAction: () {
              setState(() {
                _isSearching = false;
                _searchController.clear();
              });
            },
            actionLabel: 'Clear Search',
          );
        }

        return Column(
          children: [
            // Results Count
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing2,
                vertical: AppTheme.spacing1,
              ),
              child: Text(
                '${productProvider.products.length} items found',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.secondaryGrey,
                ),
              ),
            ),

            // Results Grid
            Expanded(
              child: GridView.builder(
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
              ),
            ),
          ],
        );
      },
    );
  }
}
