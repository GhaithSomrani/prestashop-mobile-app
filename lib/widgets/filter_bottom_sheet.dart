import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/product_provider.dart';

/// Dynamic Filter bottom sheet that uses actual product data
class FilterBottomSheet extends StatefulWidget {
  final String? categoryId;

  const FilterBottomSheet({
    super.key,
    this.categoryId,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  List<String> selectedBrands = [];
  List<String> selectedColors = [];
  List<String> selectedSizes = [];
  double minPrice = 0;
  double maxPrice = 1000;
  bool inStockOnly = false;
  bool onSaleOnly = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      child: Column(
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
                  l10n?.filters ?? 'Filters',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlack,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedBrands.clear();
                      selectedColors.clear();
                      selectedSizes.clear();
                      inStockOnly = false;
                      onSaleOnly = false;
                    });
                  },
                  child: Text(l10n?.reset ?? 'Reset'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Filters Content
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, child) {
                final filterData = provider.filterData;

                if (filterData == null) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppTheme.primaryBlack),
                        SizedBox(height: AppTheme.spacing2),
                        Text('Loading filters...'),
                      ],
                    ),
                  );
                }

                // Initialize price range from filter data
                if (minPrice == 0 && maxPrice == 1000) {
                  minPrice = filterData.minPrice;
                  maxPrice = filterData.maxPrice;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacing2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price Range
                      _buildSectionTitle(l10n?.priceRange ?? 'Price Range'),
                      const SizedBox(height: AppTheme.spacing1),
                      RangeSlider(
                        values: RangeValues(minPrice, maxPrice),
                        min: filterData.minPrice,
                        max: filterData.maxPrice,
                        divisions: 20,
                        activeColor: AppTheme.primaryBlack,
                        labels: RangeLabels(
                          '${minPrice.toStringAsFixed(0)} TND',
                          '${maxPrice.toStringAsFixed(0)} TND',
                        ),
                        onChanged: (values) {
                          setState(() {
                            minPrice = values.start;
                            maxPrice = values.end;
                          });
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${minPrice.toStringAsFixed(0)} TND',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.secondaryGrey,
                            ),
                          ),
                          Text(
                            '${maxPrice.toStringAsFixed(0)} TND',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.secondaryGrey,
                            ),
                          ),
                        ],
                      ),

                      // Brands (dynamic from API)
                      if (filterData.brands.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.spacing3),
                        const Divider(),
                        const SizedBox(height: AppTheme.spacing2),
                        _buildSectionTitle(l10n?.brand ?? 'Brand'),
                        const SizedBox(height: AppTheme.spacing1),
                        Wrap(
                          spacing: AppTheme.spacing1,
                          runSpacing: AppTheme.spacing1,
                          children: filterData.brands.map((brand) {
                            return _buildFilterChip(
                              brand,
                              selectedBrands.contains(brand),
                              () {
                                setState(() {
                                  if (selectedBrands.contains(brand)) {
                                    selectedBrands.remove(brand);
                                  } else {
                                    selectedBrands.add(brand);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],

                      // Colors (dynamic from API)
                      if (filterData.colors.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.spacing3),
                        const Divider(),
                        const SizedBox(height: AppTheme.spacing2),
                        _buildSectionTitle(l10n?.color ?? 'Color'),
                        const SizedBox(height: AppTheme.spacing1),
                        Wrap(
                          spacing: AppTheme.spacing1,
                          runSpacing: AppTheme.spacing1,
                          children: filterData.colors.map((colorOption) {
                            return _buildColorChip(
                              colorOption.name,
                              colorOption.hexColor,
                              selectedColors.contains(colorOption.name),
                              () {
                                setState(() {
                                  if (selectedColors.contains(colorOption.name)) {
                                    selectedColors.remove(colorOption.name);
                                  } else {
                                    selectedColors.add(colorOption.name);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],

                      // Sizes (dynamic from API)
                      if (filterData.sizes.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.spacing3),
                        const Divider(),
                        const SizedBox(height: AppTheme.spacing2),
                        _buildSectionTitle(l10n?.size ?? 'Size'),
                        const SizedBox(height: AppTheme.spacing1),
                        Wrap(
                          spacing: AppTheme.spacing1,
                          runSpacing: AppTheme.spacing1,
                          children: filterData.sizes.map((size) {
                            return _buildSizeChip(
                              size,
                              selectedSizes.contains(size),
                              () {
                                setState(() {
                                  if (selectedSizes.contains(size)) {
                                    selectedSizes.remove(size);
                                  } else {
                                    selectedSizes.add(size);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: AppTheme.spacing3),
                      const Divider(),
                      const SizedBox(height: AppTheme.spacing2),

                      // Availability
                      _buildSectionTitle(l10n?.availability ?? 'Availability'),
                      const SizedBox(height: AppTheme.spacing1),
                      CheckboxListTile(
                        title: Text(l10n?.inStock ?? 'In Stock'),
                        value: inStockOnly,
                        activeColor: AppTheme.primaryBlack,
                        onChanged: (value) {
                          setState(() {
                            inStockOnly = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        title: Text(l10n?.onSale ?? 'On Sale'),
                        value: onSaleOnly,
                        activeColor: AppTheme.primaryBlack,
                        onChanged: (value) {
                          setState(() {
                            onSaleOnly = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),

                      const SizedBox(height: AppTheme.spacing2),
                    ],
                  ),
                );
              },
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
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlack,
                  foregroundColor: AppTheme.pureWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                ),
                onPressed: () {
                  // Apply filters using provider
                  context.read<ProductProvider>().applyClientSideFilters(
                        selectedBrands: selectedBrands.isNotEmpty ? selectedBrands : null,
                        selectedColors: selectedColors.isNotEmpty ? selectedColors : null,
                        selectedSizes: selectedSizes.isNotEmpty ? selectedSizes : null,
                        minPrice: minPrice,
                        maxPrice: maxPrice,
                        inStockOnly: inStockOnly,
                        onSaleOnly: onSaleOnly,
                      );
                  Navigator.pop(context);
                },
                child: Text(l10n?.applyFilters ?? 'Apply Filters'),
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildColorChip(
    String colorName,
    String? hexColor,
    bool isSelected,
    VoidCallback onTap,
  ) {
    Color chipColor;
    try {
      if (hexColor != null && hexColor.isNotEmpty) {
        chipColor = Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
      } else {
        chipColor = _getColorFromName(colorName);
      }
    } catch (e) {
      chipColor = _getColorFromName(colorName);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
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
                color: chipColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: chipColor == Colors.white ? AppTheme.lightGrey : Colors.transparent,
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

  Color _getColorFromName(String colorName) {
    final colors = {
      'black': Colors.black,
      'white': Colors.white,
      'red': Colors.red,
      'blue': Colors.blue,
      'green': Colors.green,
      'yellow': Colors.yellow,
      'orange': Colors.orange,
      'purple': Colors.purple,
      'pink': Colors.pink,
      'grey': Colors.grey,
      'gray': Colors.grey,
      'brown': Colors.brown,
      'navy': Colors.indigo,
      'beige': const Color(0xFFF5F5DC),
    };
    return colors[colorName.toLowerCase()] ?? Colors.grey;
  }

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
}
