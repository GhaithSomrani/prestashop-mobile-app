import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_theme.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/custom_search_bar.dart';
import '../../widgets/product_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../product/product_detail_screen.dart';
import '../../l10n/app_localizations.dart';

/// Modern Search Screen with auto-suggestions and filters
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _recentSearches = [];
  Timer? _debounce;
  static const String _searchHistoryKey = 'search_history';
  static const int _maxSearchHistory = 10;

  bool _isSearching = false;
  String? _selectedCategoryId;
  String? _selectedCategoryName;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _searchController.addListener(_onSearchChanged);

    // Load categories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList(_searchHistoryKey) ?? [];
    });
  }

  Future<void> _saveSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_searchHistoryKey, _recentSearches);
  }

  Future<void> _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchHistoryKey);
    setState(() {
      _recentSearches = [];
    });
  }

  void _addToSearchHistory(String query) {
    if (query.isEmpty) return;

    setState(() {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > _maxSearchHistory) {
        _recentSearches = _recentSearches.sublist(0, _maxSearchHistory);
      }
    });
    _saveSearchHistory();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final query = _searchController.text;

    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    if (query.isNotEmpty) {
      setState(() {
        _isSearching = true;
      });
      _addToSearchHistory(query);

      final productProvider = Provider.of<ProductProvider>(context, listen: false);

      if (_selectedCategoryId != null) {
        productProvider.fetchProductsByCategory(_selectedCategoryId!);
      } else {
        productProvider.searchProducts(query);
      }
    }
  }

  void _showCategoryFilter() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<CategoryProvider>(
        builder: (context, categoryProvider, child) {
          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLarge),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n?.categories ?? 'Catégories',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.category_outlined),
                        title: Text(l10n?.allCategories ?? 'Toutes les catégories'),
                        selected: _selectedCategoryId == null,
                        onTap: () {
                          setState(() {
                            _selectedCategoryId = null;
                            _selectedCategoryName = null;
                          });
                          Navigator.pop(context);
                          if (_searchController.text.isNotEmpty) {
                            _performSearch(_searchController.text);
                          }
                        },
                      ),
                      ...categoryProvider.categories.map((category) {
                        return ListTile(
                          leading: const Icon(Icons.label_outline),
                          title: Text(category.name),
                          selected: _selectedCategoryId == category.id,
                          onTap: () {
                            setState(() {
                              _selectedCategoryId = category.id;
                              _selectedCategoryName = category.name;
                            });
                            Navigator.pop(context);
                            if (_searchController.text.isNotEmpty) {
                              _performSearch(_searchController.text);
                            }
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
          l10n?.search ?? 'Rechercher',
          style: const TextStyle(
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
                    hintText: l10n?.searchProducts ?? 'Rechercher des produits...',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: AppTheme.spacing1),
                // Category Filter Button
                GestureDetector(
                  onTap: _showCategoryFilter,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _selectedCategoryId != null
                          ? AppTheme.successGreen
                          : AppTheme.primaryBlack,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: const Icon(
                      Icons.category_outlined,
                      color: AppTheme.pureWhite,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Selected Category Chip
          if (_selectedCategoryName != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing2,
                vertical: AppTheme.spacing1,
              ),
              child: Chip(
                label: Text(_selectedCategoryName!),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _selectedCategoryId = null;
                    _selectedCategoryName = null;
                  });
                  if (_searchController.text.isNotEmpty) {
                    _performSearch(_searchController.text);
                  }
                },
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
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n?.searchHistory ?? 'Historique de recherche',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlack,
                  ),
                ),
                TextButton(
                  onPressed: _clearSearchHistory,
                  child: Text(l10n?.clearHistory ?? 'Effacer l\'historique'),
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
          const SizedBox(height: AppTheme.spacing3),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final l10n = AppLocalizations.of(context);

    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.isLoading) {
          return LoadingWidget(message: l10n?.loading ?? 'Chargement...');
        }

        if (productProvider.products.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.search_off,
            title: l10n?.noResultsFound ?? 'Aucun résultat trouvé',
            message: 'Essayez avec des mots-clés différents',
            onAction: () {
              setState(() {
                _isSearching = false;
                _searchController.clear();
              });
            },
            actionLabel: l10n?.reset ?? 'Réinitialiser',
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
                '${productProvider.products.length} ${l10n?.items ?? 'articles'}',
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
