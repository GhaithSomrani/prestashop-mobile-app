import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_config.dart';

class Helpers {
  // Price formatting
  static String formatPrice(double price, {String? currencyCode}) {
    final currency = currencyCode ?? AppConfig.currencyCode;
    final symbol = AppConfig.currencySymbol;

    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 2,
      name: currency,
    );

    return formatter.format(price);
  }

  // Format price with optional currency symbol
  static String formatPriceWithSymbol(double price) {
    return '${AppConfig.currencySymbol}${price.toStringAsFixed(2)}';
  }

  // Format discount percentage
  static String formatDiscountPercentage(double percentage) {
    return '${percentage.toStringAsFixed(0)}% OFF';
  }

  // Date formatting
  static String formatDate(DateTime date, {String pattern = 'MM/dd/yyyy'}) {
    return DateFormat(pattern).format(date);
  }

  static String formatDateWithTime(DateTime date) {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
  }

  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return formatDate(date);
    }
  }

  // Image URL helpers
  static String buildImageUrl(String baseUrl, String? imagePath, {String size = 'large'}) {
    if (imagePath == null || imagePath.isEmpty) {
      return AppConfig.defaultProductImage;
    }

    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    final cleanedBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanedImagePath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;

    return '$cleanedBaseUrl/$cleanedImagePath';
  }

  static String buildProductImageUrl(String baseUrl, int productId, String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return AppConfig.defaultProductImage;
    }

    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    return '$baseUrl/images/products/$productId/$imagePath';
  }

  // Text helpers
  static String truncateText(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) {
      return text;
    }
    return text.substring(0, maxLength).trim() + suffix;
  }

  static String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String capitalizeWords(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // Validation helpers
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    final digitsOnly = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    return digitsOnly.length >= 10 && RegExp(r'^[+]?[0-9]+$').hasMatch(digitsOnly);
  }

  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // Color helpers
  static Color hexToColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  // Size helpers
  static double getResponsiveWidth(BuildContext context, {double percentage = 0.9}) {
    return MediaQuery.of(context).size.width * percentage;
  }

  static double getResponsiveHeight(BuildContext context, {double percentage = 0.8}) {
    return MediaQuery.of(context).size.height * percentage;
  }

  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide > 600;
  }

  static bool isLargeTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide > 900;
  }

  // Animation helpers
  static Duration getAnimationDuration({int milliseconds = AppConfig.defaultAnimationDuration}) {
    return Duration(milliseconds: milliseconds);
  }

  // String formatting for SEO
  static String formatSeoTitle(String title) {
    return title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static String generateSlug(String text) {
    return formatSeoTitle(text);
  }

  // Quantity helpers
  static String formatQuantity(int quantity) {
    if (quantity == 1) return '1 item';
    return '$quantity items';
  }

  // Stock status helpers
  static String getStockStatus(int quantity, {bool outOfStock = false}) {
    if (outOfStock || quantity <= 0) {
      return 'Out of Stock';
    } else if (quantity <= 5) {
      return 'Only $quantity left';
    } else {
      return 'In Stock';
    }
  }

  static Color getStockStatusColor(int quantity, {bool outOfStock = false}) {
    if (outOfStock || quantity <= 0) {
      return Colors.red;
    } else if (quantity <= 5) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  // Rating helpers
  static List<IconData> getRatingStars(double rating, {int maxStars = 5}) {
    final stars = <IconData>[];
    final fullStars = rating.floor();
    final hasHalfStar = rating - fullStars >= 0.5;

    for (int i = 0; i < fullStars; i++) {
      stars.add(Icons.star);
    }

    if (hasHalfStar && fullStars < maxStars) {
      stars.add(Icons.star_half);
    }

    final emptyStars = maxStars - stars.length;
    for (int i = 0; i < emptyStars; i++) {
      stars.add(Icons.star_border);
    }

    return stars;
  }

  static String formatRating(double rating) {
    return rating.toStringAsFixed(1);
  }

  // Product helpers
  static String formatProductTitle(String title, {int maxLength = 50}) {
    return truncateText(title, maxLength);
  }

  static String formatProductDescription(String description, {int maxLength = 120}) {
    return truncateText(description, maxLength);
  }

  // Cart helpers
  static double calculateSubtotal(List<CartItem> items) {
    return items.fold(0.0, (total, item) => total + item.totalPrice);
  }

  static double calculateTax(List<CartItem> items, {double taxRate = 0.08}) {
    return calculateSubtotal(items) * taxRate;
  }

  static double calculateShipping(double subtotal, {double freeShippingThreshold = 100.0}) {
    return subtotal >= freeShippingThreshold ? 0.0 : 9.99;
  }

  static double calculateTotal(List<CartItem> items, {double taxRate = 0.08, double freeShippingThreshold = 100.0}) {
    final subtotal = calculateSubtotal(items);
    final tax = calculateTax(items, taxRate: taxRate);
    final shipping = calculateShipping(subtotal, freeShippingThreshold: freeShippingThreshold);
    return subtotal + tax + shipping;
  }

  // Order status helpers
  static String getOrderStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'refunded':
        return 'Refunded';
      default:
        return capitalizeFirstLetter(status);
    }
  }

  static Color getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'refunded':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Address helpers
  static String formatFullAddress({
    required String address1,
    String? address2,
    required String city,
    required String state,
    required String postcode,
    required String country,
  }) {
    final parts = <String>[];

    if (address1.isNotEmpty) parts.add(address1);
    if (address2?.isNotEmpty == true) parts.add(address2!);
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (postcode.isNotEmpty) parts.add(postcode);
    if (country.isNotEmpty) parts.add(country);

    return parts.join(', ');
  }

  // Error handling helpers
  static String getErrorMessage(dynamic error) {
    if (error is String) return error;
    if (error is Exception) return error.toString();
    return 'An unexpected error occurred';
  }

  // Debouncing helper
  static Function debounce(Function func, Duration delay) {
    Timer? timer;
    return () {
      if (timer != null) timer!.cancel();
      timer = Timer(delay, () {
        func();
      });
    };
  }
}