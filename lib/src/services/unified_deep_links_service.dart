import '../models/deferred_link_config.dart';
import '../utils/plugin_logger.dart';
import 'deferred_deep_links_service.dart';
import 'normal_deep_links_service.dart';

/// Unified service that handles both normal and deferred deep links
///
/// This service orchestrates:
/// - **Normal Deep Links**: Real-time deep links when app is running (via app_links)
/// - **Deferred Deep Links**: Post-install attribution (via Install Referrer/Clipboard)
///
/// Provides complete deep link coverage with a single initialization call.
class UnifiedDeepLinksService {
  final DeferredLinkConfig config;
  late final DeferredDeepLinksService _deferredService;
  late final NormalDeepLinksService _normalService;
  late final PluginLogger _logger;

  /// Flag to track if initialization is complete
  bool _isInitialized = false;

  UnifiedDeepLinksService(this.config) {
    _logger = PluginLogger(
      enableLogging: config.enableLogging,
      externalLogger: config.externalLogger,
    );
    _deferredService = DeferredDeepLinksService(config);
    _normalService = NormalDeepLinksService(config);

    _logger.i('UnifiedDeepLinksService: Initialized');
  }

  /// Initialize both normal and deferred deep link handling
  ///
  /// This should be called early in your app's lifecycle, typically in main()
  /// or after user authentication for best results.
  ///
  /// **Example**:
  /// ```dart
  /// await UnifiedDeepLinksService(config).initialize();
  /// ```
  Future<void> initialize() async {
    if (_isInitialized) {
      if (config.enableLogging) {
        print('UnifiedDeepLinksService: Already initialized');
      }
      return;
    }

    try {
      if (config.enableLogging) {
        print('UnifiedDeepLinksService: Starting unified initialization...');
      }

      // Initialize deferred deep links first (processes stored links)
      await _deferredService.initialize();

      // Initialize normal deep links (listens for real-time links)
      await _normalService.initialize();

      _isInitialized = true;

      if (config.enableLogging) {
        print('UnifiedDeepLinksService: ✅ Unified initialization complete');
      }
    } catch (e) {
      if (config.enableLogging) {
        print('UnifiedDeepLinksService: ❌ Initialization failed: $e');
      }
      config.onError?.call('Failed to initialize unified deep links: $e');
    }
  }

  /// Store a deferred deep link for later processing
  ///
  /// This is typically used by web fallback pages when the app is not installed.
  Future<void> storeDeferredDeepLink(String deepLinkUrl) async {
    await _deferredService.storeDeferredDeepLink(deepLinkUrl);
  }

  /// Get stored deferred deep link (for debugging)
  Future<String?> getStoredDeferredLink() async {
    return await _deferredService.getStoredDeferredLink();
  }

  /// Get stored deferred link metadata (for debugging)
  Future<Map<String, dynamic>?> getStoredDeferredLinkMetadata() async {
    return await _deferredService.getStoredDeferredLinkMetadata();
  }

  /// Clear stored deferred deep link
  Future<void> clearStoredDeferredLink() async {
    await _deferredService.clearStoredDeferredLink();
  }

  /// Get attribution metadata for debugging and analytics
  Future<Map<String, dynamic>> getAttributionMetadata() async {
    final deferredMetadata = await _deferredService.getAttributionMetadata();
    return {
      'isInitialized': _isInitialized,
      'deferred': deferredMetadata,
      'normal': {
        'isInitialized': _normalService.isInitialized,
        'lastProcessedLink': _normalService.lastProcessedLink,
      },
    };
  }

  /// Validate a deep link against the current configuration
  bool isValidDeepLink(String link) {
    return _deferredService.isValidDeepLink(link);
  }

  /// Extract ID parameter from a deep link
  String? extractLinkId(String link) {
    return _deferredService.extractLinkId(link);
  }

  /// Extract all parameters from a deep link
  Map<String, String> extractLinkParameters(String link) {
    return _deferredService.extractLinkParameters(link);
  }

  /// Reset first launch flag (useful for testing)
  Future<void> resetFirstLaunchFlag() async {
    await _deferredService.resetFirstLaunchFlag();
  }

  /// Cleanup expired links
  Future<bool> cleanupExpiredLinks() async {
    return await _deferredService.cleanupExpiredLinks();
  }

  /// Clear the last processed links (useful for testing)
  void clearLastProcessedLinks() {
    _deferredService.clearLastProcessedLink();
    _normalService.clearLastProcessedLink();
  }

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Get the deferred deep links service for advanced usage
  DeferredDeepLinksService get deferredService => _deferredService;

  /// Get the normal deep links service for advanced usage
  NormalDeepLinksService get normalService => _normalService;
}
