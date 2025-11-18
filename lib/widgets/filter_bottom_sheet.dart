import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Filter bottom sheet for category and search pages
class FilterBottomSheet extends StatefulWidget {
  final Function(FilterOptions) onApplyFilters;
  final FilterOptions? initialFilters;

  const FilterBottomSheet({
    super.key,
    required this.onApplyFilters,
    this.initialFilters,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late FilterOptions _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters ?? FilterOptions();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundWhite,
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
                const Text(
                  'Filters',
                  style: TextStyle(
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
                  child: const Text('Reset'),
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
                  const Text(
                    'Price Range',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlack,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing1),
                  RangeSlider(
                    values: RangeValues(
                      _filters.minPrice,
                      _filters.maxPrice,
                    ),
                    min: 0,
                    max: 1000,
                    divisions: 20,
                    labels: RangeLabels(
                      '\$${_filters.minPrice.toStringAsFixed(0)}',
                      '\$${_filters.maxPrice.toStringAsFixed(0)}',
                    ),
                    onChanged: (values) {
                      setState(() {
                        _filters.minPrice = values.start;
                        _filters.maxPrice = values.end;
                      });
                    },
                  ),

                  const SizedBox(height: AppTheme.spacing2),

                  // Availability
                  const Text(
                    'Availability',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlack,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing1),
                  CheckboxListTile(
                    title: const Text('In Stock'),
                    value: _filters.inStockOnly,
                    onChanged: (value) {
                      setState(() {
                        _filters.inStockOnly = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('On Sale'),
                    value: _filters.onSaleOnly,
                    onChanged: (value) {
                      setState(() {
                        _filters.onSaleOnly = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: AppTheme.spacing2),

                  // Sort By
                  const Text(
                    'Sort By',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlack,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing1),
                  Wrap(
                    spacing: AppTheme.spacing1,
                    runSpacing: AppTheme.spacing1,
                    children: [
                      _buildSortChip('Newest', SortOption.newest),
                      _buildSortChip('Price: Low to High', SortOption.priceLowToHigh),
                      _buildSortChip('Price: High to Low', SortOption.priceHighToLow),
                      _buildSortChip('Popular', SortOption.popular),
                    ],
                  ),
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
                child: const Text('Apply Filters'),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
    this.selectedBrands = const [],
    this.selectedColors = const [],
    this.selectedSizes = const [],
  });
}

enum SortOption {
  newest,
  priceLowToHigh,
  priceHighToLow,
  popular,
}
