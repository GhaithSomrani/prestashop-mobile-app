import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/product_detail.dart';
import '../../models/product_option.dart';
import '../../services/api_service.dart';
import '../../services/product_option_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _currentImageIndex = 0;
  int? _selectedCombinationIndex;
  bool _isDescriptionExpanded = false;
  final PageController _imagePageController = PageController();

  // Resolved attribute data
  Map<String, ProductOptionValue> _optionValues = {};
  Map<String, ProductOption> _attributeGroups = {};
  bool _attributesLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false)
          .fetchProductById(widget.productId);
    });
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  /// Fetch and resolve attribute names for combinations
  /// Follows: product_option_value -> product_option (attribute group)
  Future<void> _loadAttributeData(List<dynamic> combinations) async {
    if (_attributesLoaded || combinations.isEmpty) return;

    try {
      final apiService = ApiService(
        baseUrl: ApiConfig.baseUrl,
        apiKey: ApiConfig.apiKey,
      );
      final optionService = ProductOptionService(apiService);

      // Collect all product_option_value IDs from all combinations
      final allOptionValueIds = <String>{};
      for (final combo in combinations) {
        if (combo.productOptionValueIds != null) {
          allOptionValueIds.addAll(combo.productOptionValueIds);
        }
      }

      if (allOptionValueIds.isEmpty) {
        setState(() => _attributesLoaded = true);
        return;
      }

      // Batch fetch all product option values
      final optionValues = await optionService.getProductOptionValues(
        allOptionValueIds.toList(),
      );

      // Collect all attribute group IDs
      final attributeGroupIds =
          optionValues.values.map((v) => v.optionId).toSet().toList();

      // Batch fetch all attribute groups
      final attributeGroups = await optionService.getProductOptions(
        attributeGroupIds,
      );

      setState(() {
        _optionValues = optionValues;
        _attributeGroups = attributeGroups;
        _attributesLoaded = true;
      });
    } catch (e) {
      debugPrint('Error loading attribute data: $e');
      setState(() => _attributesLoaded = true);
    }
  }

  /// Get resolved attribute info for a combination
  List<ResolvedAttribute> _getResolvedAttributes(dynamic combination) {
    final result = <ResolvedAttribute>[];

    if (combination.productOptionValueIds == null) return result;

    for (final valueId in combination.productOptionValueIds) {
      final optionValue = _optionValues[valueId];
      if (optionValue != null) {
        final group = _attributeGroups[optionValue.optionId];
        result.add(ResolvedAttribute(
          groupId: optionValue.optionId,
          groupName: group?.publicName ?? group?.name ?? '',
          valueId: valueId,
          valueName: optionValue.name,
          color: optionValue.color,
        ));
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _buildCircleButton(
          icon: Icons.arrow_back,
          onTap: () => Navigator.pop(context),
        ),
        actions: [
          _buildCircleButton(
            icon: Icons.favorite_border,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _buildCircleButton(
            icon: Icons.share_outlined,
            onTap: () {},
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading) {
            return const LoadingWidget(message: 'Loading product...');
          }

          if (productProvider.hasError) {
            return ErrorDisplayWidget(
              message: productProvider.error ?? 'Unknown error',
              onRetry: () {
                productProvider.fetchProductById(widget.productId);
              },
            );
          }

          final product = productProvider.selectedProduct;
          if (product == null) {
            return const Center(child: Text('Product not found'));
          }

          final combinations = productProvider.productCombinations;

          // Load attribute data when combinations are available
          if (combinations.isNotEmpty && !_attributesLoaded) {
            _loadAttributeData(combinations);
          }

          // Set default combination index
          if (_selectedCombinationIndex == null && combinations.isNotEmpty) {
            _selectedCombinationIndex =
                combinations.indexWhere((c) => c.defaultOn);
            if (_selectedCombinationIndex == -1) _selectedCombinationIndex = 0;
          }

          final selectedCombination = _selectedCombinationIndex != null &&
                  _selectedCombinationIndex! < combinations.length
              ? combinations[_selectedCombinationIndex!]
              : null;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Image Carousel
                    _ProductImageCarousel(
                      imageUrl: product.imageUrl,
                      images: product.images,
                      productId: product.id,
                      currentIndex: _currentImageIndex,
                      pageController: _imagePageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                    ),

                    // Product Info Section
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title + Brand + Price
                          _PriceBlock(
                            name: product.name,
                            manufacturerName: product.manufacturerName,
                            price: product.price,
                            finalPrice: selectedCombination != null
                                ? product.price +
                                    selectedCombination.priceImpact
                                : product.finalPrice,
                            isOnSale: product.isOnSale,
                            discountPercentage:
                                product.calculatedDiscountPercentage,
                          ),

                          const SizedBox(height: 24),

                          // Variations (if available)
                          if (combinations.isNotEmpty && _attributesLoaded)
                            _VariationSelector(
                              combinations: combinations,
                              selectedIndex: _selectedCombinationIndex ?? 0,
                              optionValues: _optionValues,
                              attributeGroups: _attributeGroups,
                              onCombinationSelected: (index) {
                                setState(() {
                                  _selectedCombinationIndex = index;
                                });
                              },
                            ),

                          // Stock Status
                          _StockStatus(
                            inStock:
                                selectedCombination?.inStock ?? product.inStock,
                            quantity: selectedCombination?.quantity ??
                                product.quantity,
                          ),

                          const SizedBox(height: 24),

                          // Description Section
                          _DescriptionSection(
                            description: product.shortDescription,
                            isExpanded: _isDescriptionExpanded,
                            onToggle: () {
                              setState(() {
                                _isDescriptionExpanded =
                                    !_isDescriptionExpanded;
                              });
                            },
                          ),

                          const SizedBox(height: 24),

                          // Features (if available)
                          if (productProvider.productFeatures.isNotEmpty)
                            _FeaturesSection(
                              features: productProvider.productFeatures,
                            ),

                          // Related Products (optional)
                          if (productProvider.relatedProducts.isNotEmpty)
                            _RelatedProductsSection(
                              products: productProvider.relatedProducts,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Fixed Bottom Add to Cart Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _AddToCartBar(
                  quantity: _quantity,
                  maxQuantity:
                      selectedCombination?.quantity ?? product.quantity,
                  inStock: selectedCombination?.inStock ?? product.inStock,
                  onQuantityChanged: (newQuantity) {
                    setState(() {
                      _quantity = newQuantity;
                    });
                  },
                  onAddToCart: () {
                    final cartProvider = Provider.of<CartProvider>(
                      context,
                      listen: false,
                    );
                    cartProvider.addItem(
                      product,
                      quantity: _quantity,
                      variantId: selectedCombination?.id,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Added to cart'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          shape: BoxShape.circle,
          boxShadow: AppTheme.softShadow,
        ),
        child: Icon(
          icon,
          size: 20,
          color: AppTheme.primaryBlack,
        ),
      ),
    );
  }
}

// ============================================================================
// PRODUCT IMAGE CAROUSEL
// ============================================================================

class _ProductImageCarousel extends StatelessWidget {
  final String? imageUrl;
  final List<String> images;
  final String productId;
  final int currentIndex;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;

  const _ProductImageCarousel({
    this.imageUrl,
    required this.images,
    required this.productId,
    required this.currentIndex,
    required this.pageController,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Build image URLs list
    List<String> imageUrls = [];

    if (imageUrl != null) {
      imageUrls.add(imageUrl!);
    }

    // Add additional images from product
    for (var i = 0; i < images.length; i++) {
      final url =
          '${ApiConfig.baseUrl}api/images/products/$productId/${images[i]}';
      if (!imageUrls.contains(url)) {
        imageUrls.add(url);
      }
    }

    if (imageUrls.isEmpty) {
      imageUrls.add(''); // Placeholder
    }

    return Container(
      height: 420,
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          child: Stack(
            children: [
              PageView.builder(
                controller: pageController,
                onPageChanged: onPageChanged,
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  final url = imageUrls[index];
                  if (url.isEmpty) {
                    return Container(
                      color: Colors.grey[100],
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                    );
                  }
                  return CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[100],
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[100],
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
              // Page Indicators
              if (imageUrls.length > 1)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      imageUrls.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: currentIndex == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: currentIndex == index
                              ? AppTheme.primaryBlack
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PRICE BLOCK
// ============================================================================

class _PriceBlock extends StatelessWidget {
  final String name;
  final String? manufacturerName;
  final double price;
  final double finalPrice;
  final bool isOnSale;
  final double discountPercentage;

  const _PriceBlock({
    required this.name,
    this.manufacturerName,
    required this.price,
    required this.finalPrice,
    required this.isOnSale,
    required this.discountPercentage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand
        if (manufacturerName != null && manufacturerName!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              manufacturerName!.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondaryGrey,
                letterSpacing: 1.5,
              ),
            ),
          ),

        // Product Name & Price Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlack,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isOnSale) ...[
                  Text(
                    '${price.toStringAsFixed(2)} TND',
                    style: TextStyle(
                      fontSize: 14,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  '${finalPrice.toStringAsFixed(2)} TND',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isOnSale ? AppTheme.errorRed : AppTheme.primaryBlack,
                  ),
                ),
                if (isOnSale && discountPercentage > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '-${discountPercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// VARIATION SELECTOR (SIZE + COLOR)
// ============================================================================

class _VariationSelector extends StatelessWidget {
  final List<dynamic> combinations;
  final int selectedIndex;
  final Map<String, ProductOptionValue> optionValues;
  final Map<String, ProductOption> attributeGroups;
  final ValueChanged<int> onCombinationSelected;

  const _VariationSelector({
    required this.combinations,
    required this.selectedIndex,
    required this.optionValues,
    required this.attributeGroups,
    required this.onCombinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Group attributes by group name
    final Map<String, Set<String>> groupedAttributes = {};
    final Map<String, String> selectedValues = {};

    // Extract unique attributes from all combinations
    for (final combo in combinations) {
      for (final valueId in combo.productOptionValueIds) {
        final optionValue = optionValues[valueId];
        if (optionValue != null) {
          final group = attributeGroups[optionValue.optionId];
          final groupName = group?.publicName ?? group?.name ?? 'Option';
          groupedAttributes
              .putIfAbsent(groupName, () => {})
              .add(optionValue.name);
        }
      }
    }

    // Get selected attribute values
    if (selectedIndex < combinations.length) {
      final selectedCombo = combinations[selectedIndex];
      for (final valueId in selectedCombo.productOptionValueIds) {
        final optionValue = optionValues[valueId];
        if (optionValue != null) {
          final group = attributeGroups[optionValue.optionId];
          final groupName = group?.publicName ?? group?.name ?? 'Option';
          selectedValues[groupName] = optionValue.name;
        }
      }
    }

    if (groupedAttributes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedAttributes.entries.map((entry) {
        final groupName = entry.key;
        final values = entry.value.toList()..sort();
        final isColorGroup = _isColorAttribute(groupName);

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    groupName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlack,
                    ),
                  ),
                  if (selectedValues[groupName] != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      selectedValues[groupName]!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.secondaryGrey,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              if (isColorGroup)
                _buildColorSwatches(
                    values, selectedValues[groupName], groupName)
              else
                _buildSizePills(values, selectedValues[groupName], groupName),
            ],
          ),
        );
      }).toList(),
    );
  }

  bool _isColorAttribute(String groupName) {
    final lower = groupName.toLowerCase();
    return lower.contains('color') ||
        lower.contains('colour') ||
        lower.contains('couleur');
  }

  Widget _buildSizePills(
    List<String> values,
    String? selectedValue,
    String groupName,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: values.map((value) {
        final isSelected = value == selectedValue;
        final comboIndex = _findCombinationWithAttribute(groupName, value);
        final isAvailable =
            comboIndex != null && combinations[comboIndex].inStock;

        return GestureDetector(
          onTap: comboIndex != null
              ? () => onCombinationSelected(comboIndex)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryBlack : AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryBlack
                    : isAvailable
                        ? AppTheme.lightGrey
                        : AppTheme.lightGrey.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: isSelected ? AppTheme.softShadow : null,
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppTheme.pureWhite
                    : isAvailable
                        ? AppTheme.primaryBlack
                        : AppTheme.secondaryGrey.withOpacity(0.5),
                decoration: !isAvailable ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorSwatches(
    List<String> values,
    String? selectedValue,
    String groupName,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: values.map((value) {
        final isSelected = value == selectedValue;
        final comboIndex = _findCombinationWithAttribute(groupName, value);
        final isAvailable =
            comboIndex != null && combinations[comboIndex].inStock;
        final color = _getColorFromName(value);

        return GestureDetector(
          onTap: comboIndex != null
              ? () => onCombinationSelected(comboIndex)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppTheme.primaryBlack : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected ? AppTheme.softShadow : null,
            ),
            child: Stack(
              children: [
                if (isSelected)
                  Center(
                    child: Icon(
                      Icons.check,
                      size: 20,
                      color: _isLightColor(color) ? Colors.black : Colors.white,
                    ),
                  ),
                if (!isAvailable)
                  Center(
                    child: Container(
                      width: 2,
                      height: 40,
                      color: Colors.red,
                      transform: Matrix4.rotationZ(0.785398),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  int? _findCombinationWithAttribute(String groupName, String value) {
    for (int i = 0; i < combinations.length; i++) {
      final combo = combinations[i];
      for (final valueId in combo.productOptionValueIds) {
        final optionValue = optionValues[valueId];
        if (optionValue != null) {
          final group = attributeGroups[optionValue.optionId];
          final attrGroupName = group?.publicName ?? group?.name ?? 'Option';
          if (attrGroupName == groupName && optionValue.name == value) {
            return i;
          }
        }
      }
    }
    return null;
  }

  Color _getColorFromName(String colorName) {
    final Map<String, Color> colorMap = {
      'red': Colors.red,
      'blue': Colors.blue,
      'green': Colors.green,
      'yellow': Colors.yellow,
      'black': Colors.black,
      'white': Colors.white,
      'grey': Colors.grey,
      'gray': Colors.grey,
      'orange': Colors.orange,
      'purple': Colors.purple,
      'pink': Colors.pink,
      'brown': Colors.brown,
      'beige': const Color(0xFFF5F5DC),
      'navy': const Color(0xFF000080),
      'cyan': Colors.cyan,
      'teal': Colors.teal,
      'maroon': const Color(0xFF800000),
      'olive': const Color(0xFF808000),
      'coral': const Color(0xFFFF7F50),
      'salmon': const Color(0xFFFA8072),
      'khaki': const Color(0xFFF0E68C),
      'ivory': const Color(0xFFFFFFF0),
      'lavender': const Color(0xFFE6E6FA),
      'turquoise': const Color(0xFF40E0D0),
      'gold': const Color(0xFFFFD700),
      'silver': const Color(0xFFC0C0C0),
    };

    final lowerName = colorName.toLowerCase();
    for (final entry in colorMap.entries) {
      if (lowerName.contains(entry.key)) {
        return entry.value;
      }
    }
    return Colors.grey;
  }

  bool _isLightColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5;
  }
}

/// Helper class for resolved attribute data
class ResolvedAttribute {
  final String groupId;
  final String groupName;
  final String valueId;
  final String valueName;
  final String? color;

  ResolvedAttribute({
    required this.groupId,
    required this.groupName,
    required this.valueId,
    required this.valueName,
    this.color,
  });
}

// ============================================================================
// STOCK STATUS
// ============================================================================

class _StockStatus extends StatelessWidget {
  final bool inStock;
  final int quantity;

  const _StockStatus({
    required this.inStock,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: inStock
            ? AppTheme.successGreen.withOpacity(0.1)
            : AppTheme.errorRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            inStock ? Icons.check_circle : Icons.cancel,
            color: inStock ? AppTheme.successGreen : AppTheme.errorRed,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            inStock ? 'In Stock ($quantity available)' : 'Out of Stock',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: inStock ? AppTheme.successGreen : AppTheme.errorRed,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DESCRIPTION SECTION
// ============================================================================

class _DescriptionSection extends StatelessWidget {
  final String description;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _DescriptionSection({
    required this.description,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (description.isEmpty) {
      return const SizedBox.shrink();
    }

    // Strip HTML tags for display
    final cleanDescription = description
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Product Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlack,
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Row(
                  children: [
                    Text(
                      isExpanded ? 'Show less' : 'Read more',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentBlue,
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: AppTheme.accentBlue,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedCrossFade(
            firstChild: Text(
              cleanDescription.length > 150
                  ? '${cleanDescription.substring(0, 150)}...'
                  : cleanDescription,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.secondaryGrey,
                height: 1.6,
              ),
            ),
            secondChild: Text(
              cleanDescription,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.secondaryGrey,
                height: 1.6,
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FEATURES SECTION
// ============================================================================

class _FeaturesSection extends StatelessWidget {
  final List<dynamic> features;

  const _FeaturesSection({
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlack,
              ),
            ),
            const SizedBox(height: 16),
            ...features.map((feature) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        feature.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.secondaryGrey,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        feature.value,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlack,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// RELATED PRODUCTS SECTION
// ============================================================================

class _RelatedProductsSection extends StatelessWidget {
  final List<dynamic> products;

  const _RelatedProductsSection({
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You May Also Like',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlack,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppTheme.radiusMedium),
                          ),
                          child: product.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: product.imageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[100],
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: Colors.grey[100],
                                    child: const Icon(Icons.image),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[100],
                                  child: const Icon(Icons.shopping_bag),
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${product.finalPrice.toStringAsFixed(2)} TND',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlack,
                              ),
                            ),
                          ],
                        ),
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
}

// ============================================================================
// ADD TO CART BAR
// ============================================================================

class _AddToCartBar extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final bool inStock;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onAddToCart;

  const _AddToCartBar({
    required this.quantity,
    required this.maxQuantity,
    required this.inStock,
    required this.onQuantityChanged,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Quantity Selector
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.lightGrey),
            ),
            child: Row(
              children: [
                _QuantityButton(
                  icon: Icons.remove,
                  onTap: quantity > 1
                      ? () => onQuantityChanged(quantity - 1)
                      : null,
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlack,
                    ),
                  ),
                ),
                _QuantityButton(
                  icon: Icons.add,
                  onTap: quantity < maxQuantity && inStock
                      ? () => onQuantityChanged(quantity + 1)
                      : null,
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Add to Cart Button
          Expanded(
            child: ElevatedButton(
              onPressed: inStock ? onAddToCart : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlack,
                disabledBackgroundColor: AppTheme.lightGrey,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                inStock ? 'Add to Cart' : 'Out of Stock',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.pureWhite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuantityButton({
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: 20,
          color: onTap != null ? AppTheme.primaryBlack : AppTheme.lightGrey,
        ),
      ),
    );
  }
}
