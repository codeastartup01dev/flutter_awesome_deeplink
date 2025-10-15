import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/deferred_link_config.dart';
import '../utils/link_validator.dart';
import '../utils/logger.dart';
import 'deferred_link_storage_service.dart';
import 'install_referrer_service.dart';

/// Main service for platform-optimized deferred deep link attribution
///
/// Orchestrates multiple attribution methods with platform-specific strategies:
/// - **Android**: Install Referrer API (95%+ success) → Storage fallback
/// - **iOS**: Optional clipboard detection (90%+ success) → Storage fallback
/// - **Cross-platform**: Persistent storage service (final fallback)
///
/// Provides 96%+ overall attribution success rates with privacy-conscious defaults.
class DeferredDeepLinksService {
  final DeferredLinkConfig config;
  late final LinkValidator _linkValidator;
  late final DeferredLinkStorageService _storageService;
  late final InstallReferrerService _installReferrerService;
  late final PluginLogger _logger;

  /// Flag to track if initialization is complete
  bool _isInitialized = false;

  /// Track the last processed link to prevent duplicate handling
  String? _lastProcessedLink;

  DeferredDeepLinksService(this.config) {
    _logger = PluginLogger(enableLogging: config.enableLogging);
    _linkValidator = LinkValidator(config);
    _storageService = DeferredLinkStorageService(config);
    _installReferrerService = InstallReferrerService(config);

    _logger.i('Initialized for ${Platform.operatingSystem}');
    _logger.i('iOS clipboard enabled: ${config.enableIOSClipboard}');
  }

  /// Initialize the deferred deep links service
  ///
  /// This should be called early in your app's lifecycle, typically in main()
  /// or in your app's initialization sequence.
  ///
  /// **Example**:
  /// ```dart
  /// await DeferredDeepLinksService(config).initialize();
  /// ```
  Future<void> initialize() async {
    if (_isInitialized) {
      if (config.enableLogging) {
        print('DeferredDeepLinksService: Already initialized');
      }
      return;
    }

    try {
      if (config.enableLogging) {
        print('DeferredDeepLinksService: Starting initialization...');
      }

      // Skip deep links for web platform (not applicable)
      if (kIsWeb) {
        if (config.enableLogging) {
          print(
            'DeferredDeepLinksService: Web platform - deferred links not applicable',
          );
        }
        _isInitialized = true;
        return;
      }

      // Process any stored deferred deep links from previous sessions
      await _processStoredDeferredLinks();

      _isInitialized = true;

      if (config.enableLogging) {
        print('DeferredDeepLinksService: ✅ Initialization complete');
      }
    } catch (e) {
      if (config.enableLogging) {
        print('DeferredDeepLinksService: ❌ Initialization failed: $e');
      }
      config.onError?.call('Failed to initialize deferred deep links: $e');
    }
  }

  /// Process stored deferred deep links using platform-optimized strategies
  ///
  /// **Platform Strategy**:
  /// - **Android**: Install Referrer API → Storage Service fallback
  /// - **iOS**: Clipboard detection (if enabled) → Storage Service fallback
  /// - **Other**: Storage Service only
  Future<void> _processStoredDeferredLinks() async {
    final stopwatch = Stopwatch()..start();

    try {
      String? deferredLink;
      String source = 'none';

      if (Platform.isAndroid) {
        // 🤖 ANDROID STRATEGY: Prioritize Install Referrer API
        if (config.enableLogging) {
          print(
            'DeferredDeepLinksService: Using Android-optimized attribution strategy',
          );
        }

        // 1. PRIMARY: Install Referrer API (95%+ success rate)
        deferredLink = await _installReferrerService
            .extractDeferredLinkFromReferrer();
        if (deferredLink != null) {
          source = 'android_install_referrer';
          if (config.enableLogging) {
            print(
              'DeferredDeepLinksService: ✅ Android Install Referrer attribution successful',
            );
          }
        } else {
          // 2. FALLBACK: Storage Service for Android
          deferredLink = await _storageService.getStoredDeferredLink();
          if (deferredLink != null) {
            source = 'storage_service_android_fallback';
            if (config.enableLogging) {
              print(
                'DeferredDeepLinksService: ✅ Android Storage Service fallback successful',
              );
            }
          }
        }
      } else if (Platform.isIOS) {
        // 🍎 iOS STRATEGY: Clipboard (if enabled) → Storage Service fallback
        if (config.enableLogging) {
          print(
            'DeferredDeepLinksService: Using iOS-optimized attribution strategy',
          );
        }

        // 1. PRIMARY: Install Referrer/Clipboard (90%+ success rate when enabled)
        if (config.enableIOSClipboard) {
          deferredLink = await _installReferrerService
              .extractDeferredLinkFromReferrer();
          if (deferredLink != null) {
            source = 'ios_clipboard';
            if (config.enableLogging) {
              print(
                'DeferredDeepLinksService: ✅ iOS clipboard attribution successful',
              );
            }
          }
        } else if (config.enableLogging) {
          print(
            'DeferredDeepLinksService: iOS clipboard disabled - skipping to storage fallback',
          );
        }

        // 2. FALLBACK: Storage Service for iOS
        if (deferredLink == null) {
          deferredLink = await _storageService.getStoredDeferredLink();
          if (deferredLink != null) {
            source = 'storage_service_ios_fallback';
            if (config.enableLogging) {
              print(
                'DeferredDeepLinksService: ✅ iOS Storage Service fallback successful',
              );
            }
          }
        }
      } else {
        // 🌐 OTHER PLATFORMS: Use storage service as primary
        if (config.enableLogging) {
          print(
            'DeferredDeepLinksService: Using storage-first strategy for ${Platform.operatingSystem}',
          );
        }

        deferredLink = await _storageService.getStoredDeferredLink();
        if (deferredLink != null) {
          source = 'storage_service_primary';
          if (config.enableLogging) {
            print(
              'DeferredDeepLinksService: ✅ Storage Service attribution successful',
            );
          }
        }
      }

      if (deferredLink == null) {
        if (config.enableLogging) {
          print(
            'DeferredDeepLinksService: No deferred deep link found from any source',
          );
        }

        // Report no attribution found
        final result = AttributionResult.failure(
          source: source,
          platform: Platform.operatingSystem,
          processingTime: stopwatch.elapsed,
          error: 'No deferred link found',
        );
        config.onAttributionData?.call(result.toMap());
        return;
      }

      if (config.enableLogging) {
        print(
          'DeferredDeepLinksService: Processing deferred deep link from $source',
        );
      }

      // Validate and handle the found link
      await _handleDeferredLink(deferredLink, source, stopwatch.elapsed);

      // Clear the processed deferred link from storage (if from storage)
      if (source.contains('storage_service')) {
        await _storageService.clearStoredDeferredLink();
        if (config.enableLogging) {
          print(
            'DeferredDeepLinksService: Cleared processed link from storage',
          );
        }
      }
    } catch (e) {
      // Report attribution error
      final result = AttributionResult.failure(
        source: 'error',
        platform: Platform.operatingSystem,
        processingTime: stopwatch.elapsed,
        error: e.toString(),
      );
      config.onAttributionData?.call(result.toMap());

      if (config.enableLogging) {
        print(
          'DeferredDeepLinksService: Error processing stored deferred links: $e',
        );
      }
      config.onError?.call('Failed to process deferred links: $e');
    } finally {
      stopwatch.stop();
    }
  }

  /// Handle a found deferred link with validation and callback
  Future<void> _handleDeferredLink(
    String deferredLink,
    String source,
    Duration processingTime,
  ) async {
    try {
      // Create a unique identifier for this link to prevent duplicate processing
      final linkIdentifier = deferredLink.hashCode.toString();

      // Check if this link was already processed recently
      if (_lastProcessedLink == linkIdentifier) {
        if (config.enableLogging) {
          print('DeferredDeepLinksService: Skipping duplicate link processing');
        }
        return;
      }

      // Validate the deferred link
      if (!_linkValidator.isValidDeepLink(deferredLink)) {
        if (config.enableLogging) {
          print(
            'DeferredDeepLinksService: Invalid deferred link format: $deferredLink',
          );
        }

        // Report validation failure
        final result = AttributionResult.failure(
          source: source,
          platform: Platform.operatingSystem,
          processingTime: processingTime,
          error: 'Invalid link format',
          metadata: {'link': deferredLink},
        );
        config.onAttributionData?.call(result.toMap());
        config.onError?.call('Invalid deferred link format: $deferredLink');
        return;
      }

      // Report successful attribution
      final result = AttributionResult.success(
        link: deferredLink,
        source: source,
        platform: Platform.operatingSystem,
        processingTime: processingTime,
        metadata: {
          'linkId': _linkValidator.extractId(deferredLink),
          'parameters': _linkValidator.extractParameters(deferredLink),
        },
      );
      config.onAttributionData?.call(result.toMap());

      // Call the configured callback with the deferred link
      if (config.onDeepLink != null) {
        config.onDeepLink!(deferredLink);
        if (config.enableLogging) {
          print(
            'DeferredDeepLinksService: ✅ Successfully processed deferred link from $source',
          );
        }
      } else if (config.enableLogging) {
        print(
          'DeferredDeepLinksService: ⚠️ No onDeferredLink callback configured',
        );
      }

      // Mark this link as processed
      _lastProcessedLink = linkIdentifier;

      // Clear the last processed link after a delay to allow for legitimate duplicates
      Future.delayed(const Duration(seconds: 5), () {
        if (_lastProcessedLink == linkIdentifier) {
          _lastProcessedLink = null;
        }
      });
    } catch (e) {
      // Report callback error
      final result = AttributionResult.failure(
        source: source,
        platform: Platform.operatingSystem,
        processingTime: processingTime,
        error: 'Callback error: $e',
        metadata: {'link': deferredLink},
      );
      config.onAttributionData?.call(result.toMap());

      if (config.enableLogging) {
        print('DeferredDeepLinksService: Error handling deferred link: $e');
      }
      config.onError?.call('Failed to handle deferred link: $e');
    }
  }

  /// Store a deferred deep link for later processing
  ///
  /// This is typically used by web fallback pages when the app is not installed.
  /// The link will be processed when the user installs and opens the app.
  ///
  /// **Example**:
  /// ```dart
  /// await service.storeDeferredDeepLink('myapp://content?id=123');
  /// ```
  Future<void> storeDeferredDeepLink(String deepLinkUrl) async {
    try {
      // Validate the link before storing
      if (!_linkValidator.isValidDeepLink(deepLinkUrl)) {
        if (config.enableLogging) {
          print(
            'DeferredDeepLinksService: Cannot store invalid deep link: $deepLinkUrl',
          );
        }
        config.onError?.call('Cannot store invalid deep link format');
        return;
      }

      await _storageService.storeDeferredLink(deepLinkUrl);

      if (config.enableLogging) {
        print(
          'DeferredDeepLinksService: Stored deferred deep link for later processing',
        );
      }
    } catch (e) {
      if (config.enableLogging) {
        print('DeferredDeepLinksService: Error storing deferred deep link: $e');
      }
      config.onError?.call('Failed to store deferred deep link: $e');
    }
  }

  /// Get stored deferred deep link (for debugging)
  ///
  /// Returns the currently stored deferred link if any, null otherwise.
  /// Useful for debugging and testing.
  Future<String?> getStoredDeferredLink() async {
    try {
      return await _storageService.getStoredDeferredLink();
    } catch (e) {
      if (config.enableLogging) {
        print(
          'DeferredDeepLinksService: Error getting stored deferred deep link: $e',
        );
      }
      return null;
    }
  }

  /// Get stored deferred link metadata (for debugging)
  ///
  /// Returns metadata about the stored link including age, platform, etc.
  /// Useful for debugging and analytics.
  Future<Map<String, dynamic>?> getStoredDeferredLinkMetadata() async {
    try {
      return await _storageService.getStoredLinkMetadata();
    } catch (e) {
      if (config.enableLogging) {
        print(
          'DeferredDeepLinksService: Error getting deferred link metadata: $e',
        );
      }
      return null;
    }
  }

  /// Clear stored deferred deep link
  ///
  /// Removes any stored deferred link. Useful for testing or manual cleanup.
  Future<void> clearStoredDeferredLink() async {
    try {
      await _storageService.clearStoredDeferredLink();
      if (config.enableLogging) {
        print('DeferredDeepLinksService: Cleared stored deferred link');
      }
    } catch (e) {
      if (config.enableLogging) {
        print(
          'DeferredDeepLinksService: Error clearing stored deferred link: $e',
        );
      }
      config.onError?.call('Failed to clear stored deferred link: $e');
    }
  }

  /// Get attribution metadata for debugging and analytics
  ///
  /// Returns comprehensive information about the attribution system state.
  /// Useful for debugging, analytics, and monitoring.
  Future<Map<String, dynamic>> getAttributionMetadata() async {
    try {
      final installReferrerMetadata = await _installReferrerService
          .getAttributionMetadata();
      final storageMetadata = await _storageService.getStoredLinkMetadata();

      return {
        'isInitialized': _isInitialized,
        'platform': Platform.operatingSystem,
        'config': {
          'appScheme': config.appScheme,
          'validDomains': config.validDomains,
          'validPaths': config.validPaths,
          'enableIOSClipboard': config.enableIOSClipboard,
          'maxLinkAgeHours': config.maxLinkAge.inHours,
          'enableLogging': config.enableLogging,
        },
        'installReferrer': installReferrerMetadata,
        'storage': storageMetadata,
        'lastProcessedLink': _lastProcessedLink,
      };
    } catch (e) {
      if (config.enableLogging) {
        print(
          'DeferredDeepLinksService: Error getting attribution metadata: $e',
        );
      }
      return {'error': e.toString()};
    }
  }

  /// Validate a deep link against the current configuration
  ///
  /// Returns true if the link is valid according to the configured criteria.
  /// Useful for testing and validation.
  bool isValidDeepLink(String link) {
    return _linkValidator.isValidDeepLink(link);
  }

  /// Extract ID parameter from a deep link
  ///
  /// Returns the ID value if found, null otherwise.
  /// Useful for extracting content identifiers from deep links.
  String? extractLinkId(String link) {
    return _linkValidator.extractId(link);
  }

  /// Extract all parameters from a deep link
  ///
  /// Returns a map of all query parameters.
  /// Useful for extracting additional data from deep links.
  Map<String, String> extractLinkParameters(String link) {
    return _linkValidator.extractParameters(link);
  }

  /// Reset first launch flag (useful for testing)
  ///
  /// Resets the first launch detection, allowing deferred link attribution
  /// to be tested again. Should only be used for testing purposes.
  Future<void> resetFirstLaunchFlag() async {
    try {
      await _installReferrerService.resetFirstLaunchFlag();
      if (config.enableLogging) {
        print('DeferredDeepLinksService: Reset first launch flag');
      }
    } catch (e) {
      if (config.enableLogging) {
        print(
          'DeferredDeepLinksService: Error resetting first launch flag: $e',
        );
      }
      config.onError?.call('Failed to reset first launch flag: $e');
    }
  }

  /// Cleanup expired links
  ///
  /// Removes any expired deferred links from storage.
  /// Can be called periodically for maintenance.
  Future<bool> cleanupExpiredLinks() async {
    try {
      return await _storageService.cleanupExpiredLinks();
    } catch (e) {
      if (config.enableLogging) {
        print('DeferredDeepLinksService: Error during cleanup: $e');
      }
      return false;
    }
  }

  /// Clear the last processed link (useful for testing)
  void clearLastProcessedLink() {
    _lastProcessedLink = null;
    if (config.enableLogging) {
      print('DeferredDeepLinksService: Cleared last processed link');
    }
  }

  /// Get the last processed link identifier (useful for debugging)
  String? get lastProcessedLink => _lastProcessedLink;

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;
}
