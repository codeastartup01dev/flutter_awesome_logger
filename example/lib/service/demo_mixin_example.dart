import 'package:flutter_awesome_logger/flutter_awesome_logger.dart';

/// Example 1: Simple service class with AwesomeLoggerMixin
class UserService with AwesomeLoggerMixin {
  void fetchUser(String userId) {
    // logger.source now works because global logger is not exported!
    print('Logger source: ${logger.source}');
    logger.d('Fetching user with ID: $userId');

    // Simulate some work
    logger.i('User data retrieved successfully');

    // All logs automatically have source: 'UserService'
  }

  void deleteUser(String userId) {
    logger.w('Attempting to delete user: $userId');
    logger.i('User deleted successfully');
  }
}

/// Example 2: Repository class with error handling
class ProductRepository with AwesomeLoggerMixin {
  Future<void> loadProducts() async {
    logger.d('Starting product load...');

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 100));
      logger.i('Products loaded successfully');
    } catch (e, stack) {
      logger.e('Failed to load products', error: e, stackTrace: stack);
    }
  }
}

/// Example 3: Cache manager with detailed logging
class CacheManager with AwesomeLoggerMixin {
  final Map<String, dynamic> _cache = {};

  void set(String key, dynamic value) {
    logger.d('Setting cache key: $key');
    _cache[key] = value;
    logger.i('Cache updated. Total entries: ${_cache.length}');
  }

  dynamic get(String key) {
    if (_cache.containsKey(key)) {
      logger.d('Cache hit for key: $key');
      return _cache[key];
    } else {
      logger.w('Cache miss for key: $key');
      return null;
    }
  }

  void clear() {
    final count = _cache.length;
    _cache.clear();
    logger.i('Cache cleared. Removed $count entries');
  }
}

/// Test function to demonstrate all examples
void runMixinExamples() {
  print('\n=== AwesomeLoggerMixin Examples ===\n');

  // Example 1: UserService
  print('--- UserService Example ---');
  final userService = UserService();
  userService.fetchUser('user123');
  userService.deleteUser('user456');

  // Example 2: ProductRepository
  print('\n--- ProductRepository Example ---');
  final productRepo = ProductRepository();
  productRepo.loadProducts();

  // Example 3: CacheManager
  print('\n--- CacheManager Example ---');
  final cacheManager = CacheManager();
  cacheManager.set('user_token', 'abc123');
  cacheManager.get('user_token');
  cacheManager.get('non_existent_key');
  cacheManager.clear();

  print('\n=== Check the logger UI to see all logs with source names! ===\n');
}
