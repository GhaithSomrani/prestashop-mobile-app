import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/product_provider.dart';
import '../../widgets/custom_search_bar.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/hero_banner.dart';
import '../../widgets/section_header.dart';
import '../../widgets/product_card.dart';
import '../../widgets/brand_card.dart';
import '../../widgets/cart_badge.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../product/product_detail_screen.dart';
import '../search/search_screen.dart';
import '../../l10n/app_localizations.dart';

/// Modern Home Screen with clean white minimal UI
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Men',
    'Women',
    'Kids',
    'Shoes',
    'Electronics',
  ];

  final List<String> _brands = [
    'Nike',
    'Adidas',
    'Puma',
    'Apple',
    'Samsung',
    'Sony',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  Future<void> _loadProducts() async {
    await Provider.of<ProductProvider>(context, listen: false).fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            if (productProvider.isLoading && productProvider.products.isEmpty) {
              return LoadingWidget(message: l10n?.loadingProducts ?? 'Chargement des produits...');
            }

            if (productProvider.hasError) {
              return ErrorDisplayWidget(
                message: productProvider.error ?? (l10n?.errorOccurred ?? 'Une erreur s\'est produite'),
                onRetry: _loadProducts,
              );
            }

            return CustomScrollView(
              slivers: [
                // App Bar
                _buildAppBar(),

                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacing2),
                    child: CustomSearchBar(
                      readOnly: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Category Slider
                SliverToBoxAdapter(
                  child: _buildCategorySlider(),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppTheme.spacing2),
                ),

                // Hero Banner
                SliverToBoxAdapter(
                  child: HeroBanner(
                    title: l10n?.summerSale ?? 'Soldes d\'été',
                    subtitle: l10n?.upToOff ?? 'Jusqu\'à 50% de réduction sur une sélection d\'articles',
                    onButtonPressed: () {
                      // Navigate to sale page
                    },
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppTheme.spacing3),
                ),

                // Featured Products
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: l10n?.featuredProducts ?? 'Produits en vedette',
                    subtitle: l10n?.handPickedJustForYou ?? 'Sélectionnés rien que pour vous',
                    onSeeAllPressed: () {
                      // Navigate to all products
                    },
                  ),
                ),

                SliverToBoxAdapter(
                  child: _buildFeaturedProducts(productProvider),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppTheme.spacing3),
                ),

                // Trending Today Header
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: l10n?.trendingToday ?? 'Tendances du jour',
                    subtitle: '${productProvider.products.length} ${l10n?.items ?? 'articles'}',
                    onSeeAllPressed: () {
                      // Navigate to trending
                    },
                  ),
                ),

                // Trending Products Grid
                _buildTrendingGrid(productProvider),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppTheme.spacing3),
                ),

                // New Arrivals
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: l10n?.newArrivals ?? 'Nouveautés',
                    subtitle: l10n?.freshFromWarehouse ?? 'Fraîchement arrivé',
                    onSeeAllPressed: () {
                      // Navigate to new arrivals
                    },
                  ),
                ),

                SliverToBoxAdapter(
                  child: _buildNewArrivals(productProvider),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppTheme.spacing3),
                ),

                // Shop by Brand
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: l10n?.shopByBrand ?? 'Acheter par marque',
                    onSeeAllPressed: () {
                      // Navigate to brands
                    },
                  ),
                ),

                SliverToBoxAdapter(
                  child: _buildBrandSlider(),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppTheme.spacing4),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppTheme.pureWhite,
      elevation: 0,
      pinned: true,
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppTheme.primaryBlack),
            onPressed: () {
              // Open drawer
            },
          ),
          const Expanded(
            child: Center(
              child: Text(
                'BOUTIQUE',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: AppTheme.primaryBlack,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CartBadge(
              onTap: () {
                // Bottom nav will handle cart navigation
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySlider() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing2),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return CategoryChip(
            label: category,
            isSelected: _selectedCategory == category,
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildFeaturedProducts(ProductProvider provider) {
    final featured = provider.products.take(5).toList();

    if (featured.isEmpty) {
      return const SizedBox(height: 200);
    }

    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing2),
        itemCount: featured.length,
        itemBuilder: (context, index) {
          return SizedBox(
            width: 160,
            child: Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacing2),
              child: ProductCard(
                product: featured[index],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        productId: featured[index].id,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingGrid(ProductProvider provider) {
    final trending = provider.products.skip(5).take(6).toList();

    if (trending.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox(height: 200));
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing2),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: AppTheme.spacing2,
          mainAxisSpacing: AppTheme.spacing2,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return ProductCard(
              product: trending[index],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(
                      productId: trending[index].id,
                    ),
                  ),
                );
              },
            );
          },
          childCount: trending.length,
        ),
      ),
    );
  }

  Widget _buildNewArrivals(ProductProvider provider) {
    final newArrivals = provider.products.take(5).toList();

    if (newArrivals.isEmpty) {
      return const SizedBox(height: 200);
    }

    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing2),
        itemCount: newArrivals.length,
        itemBuilder: (context, index) {
          return SizedBox(
            width: 160,
            child: Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacing2),
              child: ProductCard(
                product: newArrivals[index],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        productId: newArrivals[index].id,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBrandSlider() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing2),
        itemCount: _brands.length,
        itemBuilder: (context, index) {
          return BrandCard(
            brandName: _brands[index],
            onTap: () {
              // Navigate to brand page
            },
          );
        },
      ),
    );
  }
}
