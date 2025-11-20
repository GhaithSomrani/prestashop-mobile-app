/// Simple in-memory cache manager for API optimization
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  final Map<String, _CacheEntry> _cache = {};

  // Default cache durations
  static const Duration shortDuration = Duration(minutes: 5);
  static const Duration mediumDuration = Duration(minutes: 30);
  static const Duration longDuration = Duration(hours: 24);

  /// Get cached value if valid
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.value as T?;
  }

  /// Set cache value with duration
  void set<T>(String key, T value, {Duration duration = const Duration(minutes: 30)}) {
    _cache[key] = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(duration),
    );
  }

  /// Check if key exists and is valid
  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    return true;
  }

  /// Remove specific key
  void remove(String key) {
    _cache.remove(key);
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
  }

  /// Clear expired entries
  void clearExpired() {
    _cache.removeWhere((key, entry) => entry.isExpired);
  }

  /// Get cache stats
  Map<String, dynamic> getStats() {
    clearExpired();
    return {
      'total_entries': _cache.length,
      'keys': _cache.keys.toList(),
    };
  }

  // Convenience methods for common cache keys

  /// Cache key for product options
  static String productOptionKey(String id) => 'product_option_$id';

  /// Cache key for product option values
  static String productOptionValueKey(String id) => 'product_option_value_$id';

  /// Cache key for stock availability
  static String stockKey(String productId, [String? attributeId]) =>
      'stock_${productId}_${attributeId ?? '0'}';

  /// Cache key for product details
  static String productDetailKey(String id) => 'product_detail_$id';

  /// Cache key for combinations
  static String combinationsKey(String productId) => 'combinations_$productId';
}

class _CacheEntry {
  final dynamic value;
  final DateTime expiresAt;

  _CacheEntry({required this.value, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
