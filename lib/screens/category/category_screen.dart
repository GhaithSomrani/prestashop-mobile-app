import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../services/category_service.dart';
import '../../models/category.dart';
import '../../widgets/category_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'category_products_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final Map<String, bool> _expandedCategories = {};
  final Map<String, List<Category>> _subcategoriesCache = {};
  final Map<String, bool> _loadingSubcategories = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
    });
  }

  Future<void> _loadSubcategories(String categoryId, CategoryService categoryService) async {
    if (_subcategoriesCache.containsKey(categoryId)) return;

    setState(() {
      _loadingSubcategories[categoryId] = true;
    });

    try {
      final subcategories = await categoryService.getSubcategories(categoryId);
      setState(() {
        _subcategoriesCache[categoryId] = subcategories;
        _loadingSubcategories[categoryId] = false;
      });
    } catch (e) {
      setState(() {
        _loadingSubcategories[categoryId] = false;
      });
      print('Error loading subcategories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.pureWhite,
        elevation: 0,
        title: Text(
          l10n?.categories ?? 'Catégories',
          style: const TextStyle(
            color: AppTheme.primaryBlack,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, child) {
          if (categoryProvider.isLoading) {
            return LoadingWidget(message: l10n?.loadingCategories ?? 'Chargement des catégories...');
          }

          if (categoryProvider.hasError) {
            return ErrorDisplayWidget(
              message: categoryProvider.error ?? (l10n?.errorOccurred ?? 'Une erreur s\'est produite'),
              onRetry: () {
                categoryProvider.fetchCategories();
              },
            );
          }

          if (categoryProvider.categories.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.category_outlined,
              title: 'Aucune catégorie trouvée',
              message: 'Aucune catégorie disponible pour le moment',
              onAction: () {
                categoryProvider.fetchCategories();
              },
              actionLabel: 'Actualiser',
            );
          }

          // Get CategoryService instance
          final categoryService = Provider.of<CategoryProvider>(context, listen: false).categoryService;

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacing2),
            itemCount: categoryProvider.categories.length,
            itemBuilder: (context, index) {
              final category = categoryProvider.categories[index];
              final isExpanded = _expandedCategories[category.id] ?? false;
              final subcategories = _subcategoriesCache[category.id] ?? [];
              final isLoadingSubcats = _loadingSubcategories[category.id] ?? false;

              return Card(
                margin: const EdgeInsets.only(bottom: AppTheme.spacing2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                elevation: 2,
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.all(AppTheme.spacing2),
                      leading: Container(
                        padding: const EdgeInsets.all(AppTheme.spacing1),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlack.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: const Icon(
                          Icons.category,
                          color: AppTheme.primaryBlack,
                        ),
                      ),
                      title: Text(
                        category.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // View Products Button
                          IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryProductsScreen(
                                    category: category,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Expand Subcategories Button
                          IconButton(
                            icon: Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                            ),
                            onPressed: () {
                              setState(() {
                                _expandedCategories[category.id] = !isExpanded;
                              });
                              if (!isExpanded && !_subcategoriesCache.containsKey(category.id)) {
                                _loadSubcategories(category.id, categoryService);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    // Subcategories Section
                    if (isExpanded)
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacing2),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundWhite,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(AppTheme.radiusMedium),
                            bottomRight: Radius.circular(AppTheme.radiusMedium),
                          ),
                        ),
                        child: isLoadingSubcats
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(AppTheme.spacing2),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : subcategories.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(AppTheme.spacing2),
                                    child: Text(
                                      l10n?.subcategories != null
                                          ? 'Aucune sous-catégorie'
                                          : 'Aucune sous-catégorie',
                                      style: const TextStyle(
                                        color: AppTheme.secondaryGrey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: AppTheme.spacing1,
                                        ),
                                        child: Text(
                                          l10n?.subcategories ?? 'Sous-catégories',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: AppTheme.secondaryGrey,
                                          ),
                                        ),
                                      ),
                                      ...subcategories.map((subcat) {
                                        return ListTile(
                                          contentPadding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                            horizontal: AppTheme.spacing1,
                                          ),
                                          leading: const Icon(
                                            Icons.subdirectory_arrow_right,
                                            size: 20,
                                            color: AppTheme.secondaryGrey,
                                          ),
                                          title: Text(
                                            subcat.name,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                          trailing: const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 14,
                                          ),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => CategoryProductsScreen(
                                                  category: subcat,
                                                ),
                                              ),
                                            );
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
          );
        },
      ),
    );
  }
}
