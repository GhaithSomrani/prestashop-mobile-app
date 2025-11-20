import '../models/product_detail.dart';
import '../models/combination.dart';

/// Utility for calculating product prices with combinations
class PriceCalculator {
  /// Calculate final price for a combination
  /// Formula: Base Product Price + Combination Price Impact
  static double calculateCombinationPrice(double basePrice, double priceImpact) {
    return basePrice + priceImpact;
  }

  /// Calculate final price for a combination with tax
  static double calculatePriceWithTax(double basePrice, double priceImpact, double taxRate) {
    final priceBeforeTax = basePrice + priceImpact;
    return priceBeforeTax * (1 + taxRate / 100);
  }

  /// Get the display price for a product
  static double getDisplayPrice(ProductDetail product) {
    if (product.isSimpleProduct) {
      return product.basePrice;
    }

    final defaultCombination = product.defaultCombination;
    if (defaultCombination != null) {
      return defaultCombination.finalPrice;
    }

    return product.basePrice;
  }

  /// Get price range for a product with combinations
  static PriceRange getPriceRange(ProductDetail product) {
    if (product.isSimpleProduct || product.combinations.isEmpty) {
      return PriceRange(min: product.basePrice, max: product.basePrice);
    }

    final prices = product.combinations.map((c) => c.finalPrice).toList();
    return PriceRange(
      min: prices.reduce((a, b) => a < b ? a : b),
      max: prices.reduce((a, b) => a > b ? a : b),
    );
  }

  /// Check if product is within a price range
  /// Returns true if any combination falls within the range
  static bool isInPriceRange(ProductDetail product, double minPrice, double maxPrice) {
    if (product.isSimpleProduct) {
      return product.basePrice >= minPrice && product.basePrice <= maxPrice;
    }

    if (product.combinations.isEmpty) {
      return product.basePrice >= minPrice && product.basePrice <= maxPrice;
    }

    // Check if any combination is in range
    return product.combinations.any(
      (c) => c.finalPrice >= minPrice && c.finalPrice <= maxPrice,
    );
  }

  /// Calculate discount percentage
  static double calculateDiscountPercentage(double originalPrice, double finalPrice) {
    if (originalPrice <= 0) return 0;
    return ((originalPrice - finalPrice) / originalPrice * 100).clamp(0, 100);
  }

  /// Format price for display
  static String formatPrice(double price, {String currency = 'TND', int decimals = 2}) {
    return '${price.toStringAsFixed(decimals)} $currency';
  }

  /// Format price range for display
  static String formatPriceRange(PriceRange range, {String currency = 'TND'}) {
    if (!range.hasRange) {
      return formatPrice(range.min, currency: currency);
    }
    return '${range.min.toStringAsFixed(2)} - ${range.max.toStringAsFixed(2)} $currency';
  }
}
