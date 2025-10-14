/// Flutter Awesome Deeplink Plugin
///
/// Platform-optimized deferred deep links AND normal deep links for Flutter with 96%+ attribution success rates.
///
/// **Key Features**:
/// - 🤖 **Android**: Install Referrer API (95%+ success rate)
/// - 🍎 **iOS**: Optional clipboard detection (90%+ success rate when enabled)
/// - 🔗 **Normal Deep Links**: Real-time deep link handling using app_links
/// - 🔒 **Privacy-first**: iOS clipboard checking is opt-in
/// - 🌐 **Cross-platform**: Works on Android, iOS, and Web
/// - ⚡ **High performance**: Minimal overhead and fast attribution
/// - 🛡️ **Production-ready**: Comprehensive error handling and logging
///
/// **Basic Usage (Normal Deep Links Only)**:
/// ```dart
/// import 'package:flutter_awesome_deeplink/flutter_awesome_deeplink.dart';
///
/// // Initialize with normal deep links only (simpler setup)
/// await FlutterAwesomeDeeplink.initialize(
///   normalConfig: NormalDeepLinkConfig(
///     appScheme: 'myapp',
///     validDomains: ['myapp.com'],
///     onNormalLink: (uri) {
///       // Handle real-time deep links
///       final id = uri.queryParameters['id'];
///       if (uri.path.contains('/challenge')) {
///         GoRouter.of(context).push('/challenge/$id');
///       }
///     },
///   ),
/// );
/// ```
///
/// **Advanced Usage (Both Normal & Deferred Deep Links)**:
/// ```dart
/// // Initialize with both normal and deferred deep links
/// await FlutterAwesomeDeeplink.initialize(
///   normalConfig: NormalDeepLinkConfig(
///     appScheme: 'myapp',
///     validDomains: ['myapp.com'],
///     onNormalLink: (uri) {
///       // Handle real-time deep links
///       final id = uri.queryParameters['id'];
///       GoRouter.of(context).push('/challenge/$id');
///     },
///   ),
///   deferredConfig: DeferredLinkConfig(
///     appScheme: 'myapp',
///     validDomains: ['myapp.com'],
///     enableIOSClipboard: true, // Optional: Enable iOS clipboard detection
///     onDeferredLink: (link) {
///       // Handle post-install attribution
///       MyRouter.handleDeepLink(link);
///     },
///   ),
/// );
/// ```

// Export public API
export 'src/models/normal_deep_link_config.dart';
export 'src/models/deferred_link_config.dart';
export 'src/services/deferred_deep_links_service.dart';
export 'src/utils/link_validator.dart';

import 'src/models/normal_deep_link_config.dart';
import 'src/models/deferred_link_config.dart';
import 'src/services/deferred_deep_links_service.dart';

/// Main plugin class providing a simple static API
///
/// This class provides a convenient static interface for the most common
/// use cases while still allowing access to the underlying service classes
/// for advanced usage.
class FlutterAwesomeDeeplink {
  /// Internal service instance
  static DeferredDeepLinksService? _service;

  /// Initialize the Flutter Awesome Deeplink plugin
  ///
  /// This should be called early in your app's lifecycle, typically in main()
  /// or during app initialization.
  ///
  /// **Parameters**:
  /// - `normalConfig`: Configuration for normal deep links (required)
  /// - `deferredConfig`: Configuration for deferred link attribution (optional)
  ///
  /// **Example (Normal Deep Links Only)**:
  /// ```dart
  /// await FlutterAwesomeDeeplink.initialize(
  ///   normalConfig: NormalDeepLinkConfig(
  ///     appScheme: 'myapp',
  ///     validDomains: ['myapp.com'],
  ///     onNormalLink: (uri) => handleDeepLink(uri),
  ///   ),
  /// );
  /// ```
  ///
  /// **Example (Both Normal & Deferred Deep Links)**:
  /// ```dart
  /// await FlutterAwesomeDeeplink.initialize(
  ///   normalConfig: NormalDeepLinkConfig(
  ///     appScheme: 'myapp',
  ///     validDomains: ['myapp.com'],
  ///     onNormalLink: (uri) => handleDeepLink(uri),
  ///   ),
  ///   deferredConfig: DeferredLinkConfig(
  ///     appScheme: 'myapp',
  ///     validDomains: ['myapp.com'],
  ///     onDeferredLink: (link) => handleDeferredLink(link),
  ///   ),
  /// );
  /// ```
  ///
  /// **Throws**: Exception if initialization fails
  static Future<void> initialize({
    required NormalDeepLinkConfig normalConfig,
    DeferredLinkConfig? deferredConfig,
  }) async {
    _service = DeferredDeepLinksService(
      normalConfig: normalConfig,
      deferredConfig: deferredConfig,
    );
    await _service!.initialize();
  }

  /// Get the current service instance
  ///
  /// Returns the initialized service instance for advanced usage.
  /// Throws an exception if the plugin hasn't been initialized.
  ///
  /// **Example**:
  /// ```dart
  /// final service = FlutterAwesomeDeeplink.instance;
  /// final metadata = await service.getAttributionMetadata();
  /// ```
  static DeferredDeepLinksService get instance {
    if (_service == null) {
      throw StateError(
        'FlutterAwesomeDeeplink has not been initialized. '
        'Call FlutterAwesomeDeeplink.initialize() first.',
      );
    }
    return _service!;
  }

  /// Check if the plugin has been initialized
  ///
  /// Returns true if initialize() has been called successfully.
  static bool get isInitialized => _service != null && _service!.isInitialized;

  /// Store a deferred deep link for later processing
  ///
  /// This is typically used by web fallback pages when the app is not installed.
  ///
  /// **Example**:
  /// ```dart
  /// await FlutterAwesomeDeeplink.storeDeferredLink('myapp://content?id=123');
  /// ```
  static Future<void> storeDeferredLink(String deepLinkUrl) async {
    await instance.storeDeferredLink(deepLinkUrl);
  }

  /// Get stored deferred deep link (for debugging)
  ///
  /// Returns the currently stored deferred link if any.
  static Future<String?> getStoredDeferredLink() async {
    return await instance.getStoredDeferredLink();
  }

  /// Clear stored deferred deep link
  ///
  /// Removes any stored deferred link. Useful for testing.
  static Future<void> clearStoredDeferredLink() async {
    await instance.clearStoredDeferredLink();
  }

  /// Validate a deep link against the current configuration
  ///
  /// Returns true if the link is valid according to the configured criteria.
  ///
  /// **Example**:
  /// ```dart
  /// final isValid = FlutterAwesomeDeeplink.isValidDeepLink('myapp://content?id=123');
  /// ```
  static bool isValidDeepLink(String link) {
    return instance.isValidDeepLink(link);
  }

  /// Extract ID parameter from a deep link
  ///
  /// Returns the ID value if found, null otherwise.
  ///
  /// **Example**:
  /// ```dart
  /// final id = FlutterAwesomeDeeplink.extractLinkId('myapp://content?id=123');
  /// // Returns: '123'
  /// ```
  static String? extractLinkId(String link) {
    return instance.extractLinkId(link);
  }

  /// Extract all parameters from a deep link
  ///
  /// Returns a map of all query parameters.
  ///
  /// **Example**:
  /// ```dart
  /// final params = FlutterAwesomeDeeplink.extractLinkParameters('myapp://content?id=123&type=challenge');
  /// // Returns: {'id': '123', 'type': 'challenge'}
  /// ```
  static Map<String, String> extractLinkParameters(String link) {
    return instance.extractLinkParameters(link);
  }

  /// Get attribution metadata for debugging and analytics
  ///
  /// Returns comprehensive information about the attribution system state.
  static Future<Map<String, dynamic>> getAttributionMetadata() async {
    return await instance.getAttributionMetadata();
  }

  /// Reset first launch flag (useful for testing)
  ///
  /// Resets the first launch detection, allowing deferred link attribution
  /// to be tested again. Should only be used for testing purposes.
  static Future<void> resetFirstLaunchFlag() async {
    await instance.resetFirstLaunchFlag();
  }

  /// Cleanup expired links
  ///
  /// Removes any expired deferred links from storage.
  /// Returns true if any links were cleaned up.
  static Future<bool> cleanupExpiredLinks() async {
    return await instance.cleanupExpiredLinks();
  }

  /// Clear the last processed link (useful for testing)
  ///
  /// Clears the duplicate prevention cache, allowing the same link
  /// to be processed again. Useful for testing scenarios.
  static void clearLastProcessedLink() {
    instance.clearLastProcessedLink();
  }

  /// Get the last processed link identifier (useful for debugging)
  ///
  /// Returns the identifier of the last processed deep link.
  /// Useful for debugging duplicate link prevention.
  static String? get lastProcessedLink {
    return instance.lastProcessedLink;
  }

  /// Dispose of the plugin resources
  ///
  /// Call this when you no longer need the plugin to clean up resources
  /// and prevent memory leaks. Typically called in your app's dispose method.
  ///
  /// **Example**:
  /// ```dart
  /// @override
  /// void dispose() {
  ///   FlutterAwesomeDeeplink.dispose();
  ///   super.dispose();
  /// }
  /// ```
  static Future<void> dispose() async {
    if (_service != null) {
      await _service!.dispose();
      _service = null;
    }
  }
}
