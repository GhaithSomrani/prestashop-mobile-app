import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/common/product_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../config/app_config.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  FocusNode _focusNode = FocusNode();
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(widget.initialQuery!);
      });
    }
    _loadSearchHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadSearchHistory() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    setState(() {
      _searchHistory = productProvider.getSearchHistory();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreResults();
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await productProvider.searchProducts(query, refresh: true);

    _focusNode.unfocus();
  }

  Future<void> _loadMoreResults() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final query = _searchController.text.trim();

    if (query.isNotEmpty && productProvider.hasMoreSearchResults) {
      await productProvider.loadMoreSearchResults(query);
    }
  }

  void _onProductTap(Product product) {
    context.push('/product/${product.id}');
  }

  Future<void> _onAddToCart(Product product) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    final success = await cartProvider.addToCart(product);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Added to cart' : 'Failed to add to cart'),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onHistoryTap(String query) {
    setState(() {
      _searchController.text = query;
    });
    _performSearch(query);
  }

  void _onClearHistory() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.clearSearchHistory();
    setState(() {
      _searchHistory.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Search'),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 2,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(AppConfig.defaultPadding),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConfig.cardBorderRadius),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConfig.defaultPadding,
            vertical: AppConfig.defaultPadding,
          ),
        ),
        onSubmitted: _performSearch,
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildContent() {
    final productProvider = Provider.of<ProductProvider>(context);
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      return _buildSearchHistory();
    }

    if (productProvider.isSearching) {
      return const LoadingProductGrid();
    }

    if (productProvider.searchStatus == SearchStatus.error) {
      return _buildErrorWidget(productProvider.searchErrorMessage);
    }

    if (productProvider.searchStatus == SearchStatus.noResults) {
      return _buildNoResults();
    }

    return _buildSearchResults(productProvider.searchResults);
  }

  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return _buildEmptyHistory();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConfig.defaultPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _onClearHistory,
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          itemCount: _searchHistory.length,
          itemBuilder: (context, index) {
            final query = _searchHistory[index];
            return ListTile(
              leading: const Icon(Icons.history),
              title: Text(query),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _onHistoryTap(query),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppConfig.defaultPadding),
          Text(
            'Search for products',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for items you\'re looking for',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<Product> results) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          _onScroll();
        }
        return false;
      },
      child: ProductGrid(
        products: results,
        onProductTap: _onProductTap,
        onAddToCart: _onAddToCart,
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppConfig.defaultPadding),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
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
            onPressed: () {
              final query = _searchController.text.trim();
              if (query.isNotEmpty) {
                _performSearch(query);
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}