import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';

/// Filter bottom sheet for category and search pages
/// Includes: Price, Brand, Color, Size, Availability, Sort
class FilterBottomSheet extends StatefulWidget {
  final Function(FilterOptions) onApplyFilters;
  final FilterOptions? initialFilters;
  final List<String>? availableBrands;
  final List<String>? availableColors;
  final List<String>? availableSizes;

  const FilterBottomSheet({
    super.key,
    required this.onApplyFilters,
    this.initialFilters,
    this.availableBrands,
    this.availableColors,
    this.availableSizes,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late FilterOptions _filters;

  // Default filter options
  static const List<String> _defaultBrands = [
    'Nike', 'Adidas', 'Puma', 'Reebok', 'Under Armour',
    'New Balance', 'Converse', 'Vans'
  ];

  static const List<String> _defaultColors = [
    'Black', 'White', 'Red', 'Blue', 'Green',
    'Yellow', 'Orange', 'Purple', 'Pink', 'Grey'
  ];

  static const List<String> _defaultSizes = [
    'XS', 'S', 'M', 'L', 'XL', 'XXL',
    '36', '37', '38', '39', '40', '41', '42', '43', '44', '45'
  ];

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters ?? FilterOptions();
  }

  // Color map for visual display
  Color _getColorFromName(String colorName) {
    final colors = {
      'Black': Colors.black,
      'White': Colors.white,
      'Red': Colors.red,
      'Blue': Colors.blue,
      'Green': Colors.green,
      'Yellow': Colors.yellow,
      'Orange': Colors.orange,
      'Purple': Colors.purple,
      'Pink': Colors.pink,
      'Grey': Colors.grey,
    };
    return colors[colorName] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brands = widget.availableBrands ?? _defaultBrands;
    final colors = widget.availableColors ?? _defaultColors;
    final sizes = widget.availableSizes ?? _defaultSizes;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing1),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.lightGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing2,
              vertical: AppTheme.spacing1,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n?.filters ?? 'Filtres',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlack,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filters = FilterOptions();
                    });
                  },
                  child: Text(l10n?.reset ?? 'Réinitialiser'),
                ),
              ],
            ),
          ),

          const Divider(),

          // Filters Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacing2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price Range
                  _buildSectionTitle(l10n?.priceRange ?? 'Fourchette de prix'),
                  const SizedBox(height: AppTheme.spacing1),
                  RangeSlider(
                    values: RangeValues(
                      _filters.minPrice,
                      _filters.maxPrice,
                    ),
                    min: 0,
                    max: 1000,
                    divisions: 20,
                    activeColor: AppTheme.primaryBlack,
                    labels: RangeLabels(
                      '${_filters.minPrice.toStringAsFixed(0)} TND',
                      '${_filters.maxPrice.toStringAsFixed(0)} TND',
                    ),
                    onChanged: (values) {
                      setState(() {
                        _filters.minPrice = values.start;
                        _filters.maxPrice = values.end;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_filters.minPrice.toStringAsFixed(0)} TND',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.secondaryGrey,
                        ),
                      ),
                      Text(
                        '${_filters.maxPrice.toStringAsFixed(0)} TND',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.secondaryGrey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppTheme.spacing3),
                  const Divider(),
                  const SizedBox(height: AppTheme.spacing2),

                  // Brand Filter
                  _buildSectionTitle(l10n?.brand ?? 'Marque'),
                  const SizedBox(height: AppTheme.spacing1),
                  Wrap(
                    spacing: AppTheme.spacing1,
                    runSpacing: AppTheme.spacing1,
                    children: brands.map((brand) {
                      return _buildFilterChip(
                        brand,
                        _filters.selectedBrands.contains(brand),
                        () {
                          setState(() {
                            if (_filters.selectedBrands.contains(brand)) {
                              _filters.selectedBrands.remove(brand);
                            } else {
                              _filters.selectedBrands.add(brand);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppTheme.spacing3),
                  const Divider(),
                  const SizedBox(height: AppTheme.spacing2),

                  // Color Filter
                  _buildSectionTitle(l10n?.color ?? 'Couleur'),
                  const SizedBox(height: AppTheme.spacing1),
                  Wrap(
                    spacing: AppTheme.spacing1,
                    runSpacing: AppTheme.spacing1,
                    children: colors.map((color) {
                      return _buildColorChip(
                        color,
                        _filters.selectedColors.contains(color),
                        () {
                          setState(() {
                            if (_filters.selectedColors.contains(color)) {
                              _filters.selectedColors.remove(color);
                            } else {
                              _filters.selectedColors.add(color);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppTheme.spacing3),
                  const Divider(),
                  const SizedBox(height: AppTheme.spacing2),

                  // Size Filter
                  _buildSectionTitle(l10n?.size ?? 'Taille'),
                  const SizedBox(height: AppTheme.spacing1),
                  Wrap(
                    spacing: AppTheme.spacing1,
                    runSpacing: AppTheme.spacing1,
                    children: sizes.map((size) {
                      return _buildSizeChip(
                        size,
                        _filters.selectedSizes.contains(size),
                        () {
                          setState(() {
                            if (_filters.selectedSizes.contains(size)) {
                              _filters.selectedSizes.remove(size);
                            } else {
                              _filters.selectedSizes.add(size);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppTheme.spacing3),
                  const Divider(),
                  const SizedBox(height: AppTheme.spacing2),

                  // Availability
                  _buildSectionTitle(l10n?.availability ?? 'Disponibilité'),
                  const SizedBox(height: AppTheme.spacing1),
                  CheckboxListTile(
                    title: Text(l10n?.inStock ?? 'En stock'),
                    value: _filters.inStockOnly,
                    activeColor: AppTheme.primaryBlack,
                    onChanged: (value) {
                      setState(() {
                        _filters.inStockOnly = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: Text(l10n?.onSale ?? 'En promotion'),
                    value: _filters.onSaleOnly,
                    activeColor: AppTheme.primaryBlack,
                    onChanged: (value) {
                      setState(() {
                        _filters.onSaleOnly = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: AppTheme.spacing3),
                  const Divider(),
                  const SizedBox(height: AppTheme.spacing2),

                  // Sort By
                  _buildSectionTitle(l10n?.sortBy ?? 'Trier par'),
                  const SizedBox(height: AppTheme.spacing1),
                  Wrap(
                    spacing: AppTheme.spacing1,
                    runSpacing: AppTheme.spacing1,
                    children: [
                      _buildSortChip(l10n?.newest ?? 'Plus récent', SortOption.newest),
                      _buildSortChip(l10n?.priceLowToHigh ?? 'Prix croissant', SortOption.priceLowToHigh),
                      _buildSortChip(l10n?.priceHighToLow ?? 'Prix décroissant', SortOption.priceHighToLow),
                      _buildSortChip(l10n?.popular ?? 'Populaire', SortOption.popular),
                    ],
                  ),

                  const SizedBox(height: AppTheme.spacing2),
                ],
              ),
            ),
          ),

          // Apply Button
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing2),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApplyFilters(_filters);
                  Navigator.pop(context);
                },
                child: Text(l10n?.applyFilters ?? 'Appliquer les filtres'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Section Title
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.primaryBlack,
      ),
    );
  }

  // Helper: Filter Chip (for brands)
  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing2,
          vertical: AppTheme.spacing1,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlack : AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlack : AppTheme.lightGrey,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppTheme.pureWhite : AppTheme.primaryBlack,
          ),
        ),
      ),
    );
  }

  // Helper: Color Chip with color swatch
  Widget _buildColorChip(String colorName, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing1 + 4,
          vertical: AppTheme.spacing1,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlack : AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlack : AppTheme.lightGrey,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _getColorFromName(colorName),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorName == 'White' ? AppTheme.lightGrey : Colors.transparent,
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              colorName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppTheme.pureWhite : AppTheme.primaryBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Size Chip
  Widget _buildSizeChip(String size, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing2,
          vertical: AppTheme.spacing1,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlack : AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlack : AppTheme.lightGrey,
            width: 1.5,
          ),
        ),
        child: Text(
          size,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppTheme.pureWhite : AppTheme.primaryBlack,
          ),
        ),
      ),
    );
  }

  // Helper: Sort Chip
  Widget _buildSortChip(String label, SortOption option) {
    final isSelected = _filters.sortBy == option;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filters.sortBy = option;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing2,
          vertical: AppTheme.spacing1,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlack : AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlack : AppTheme.lightGrey,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppTheme.pureWhite : AppTheme.primaryBlack,
          ),
        ),
      ),
    );
  }
}

/// Filter options model
class FilterOptions {
  double minPrice;
  double maxPrice;
  bool inStockOnly;
  bool onSaleOnly;
  SortOption sortBy;
  List<String> selectedBrands;
  List<String> selectedColors;
  List<String> selectedSizes;

  FilterOptions({
    this.minPrice = 0,
    this.maxPrice = 1000,
    this.inStockOnly = false,
    this.onSaleOnly = false,
    this.sortBy = SortOption.newest,
    List<String>? selectedBrands,
    List<String>? selectedColors,
    List<String>? selectedSizes,
  })  : selectedBrands = selectedBrands ?? [],
        selectedColors = selectedColors ?? [],
        selectedSizes = selectedSizes ?? [];

  // Copy with method for easier filter management
  FilterOptions copyWith({
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    bool? onSaleOnly,
    SortOption? sortBy,
    List<String>? selectedBrands,
    List<String>? selectedColors,
    List<String>? selectedSizes,
  }) {
    return FilterOptions(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      inStockOnly: inStockOnly ?? this.inStockOnly,
      onSaleOnly: onSaleOnly ?? this.onSaleOnly,
      sortBy: sortBy ?? this.sortBy,
      selectedBrands: selectedBrands ?? List.from(this.selectedBrands),
      selectedColors: selectedColors ?? List.from(this.selectedColors),
      selectedSizes: selectedSizes ?? List.from(this.selectedSizes),
    );
  }

  // Check if any filters are active
  bool get hasActiveFilters {
    return minPrice > 0 ||
        maxPrice < 1000 ||
        inStockOnly ||
        onSaleOnly ||
        selectedBrands.isNotEmpty ||
        selectedColors.isNotEmpty ||
        selectedSizes.isNotEmpty ||
        sortBy != SortOption.newest;
  }

  // Reset all filters
  void reset() {
    minPrice = 0;
    maxPrice = 1000;
    inStockOnly = false;
    onSaleOnly = false;
    sortBy = SortOption.newest;
    selectedBrands.clear();
    selectedColors.clear();
    selectedSizes.clear();
  }
}

enum SortOption {
  newest,
  priceLowToHigh,
  priceHighToLow,
  popular,
}
