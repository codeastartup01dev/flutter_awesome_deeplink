import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../models/deferred_link_config.dart';
import '../utils/link_validator.dart';
import '../utils/plugin_logger.dart';

/// Service for handling normal (real-time) deep links using app_links
///
/// This service listens for deep links when the app is already running
/// and processes them immediately. Works alongside DeferredDeepLinksService
/// for complete deep link coverage.
class NormalDeepLinksService {
  final DeferredLinkConfig config;
  late final AppLinks _appLinks;
  late final LinkValidator _linkValidator;
  late final PluginLogger _logger;

  /// Track the last processed link to prevent duplicate handling
  String? _lastProcessedLink;

  /// Flag to track if initialization is complete
  bool _isInitialized = false;

  NormalDeepLinksService(this.config) {
    _logger = PluginLogger(
      enableLogging: config.enableLogging,
      externalLogger: config.externalLogger,
    );
    _linkValidator = LinkValidator(config);
    _appLinks = AppLinks();

    _logger.i('NormalDeepLinksService: Initialized');
  }

  /// Initialize and handle normal deep links using app_links package
  ///
  /// This method handles both:
  /// - Initial link (app opened from deep link when not running)
  /// - Subsequent link events (app already running)
  Future<void> initialize() async {
    if (_isInitialized) {
      if (config.enableLogging) {
        print('NormalDeepLinksService: Already initialized');
      }
      return;
    }

    try {
      // Skip deep links for web platform
      if (kIsWeb) {
        if (config.enableLogging) {
          print(
            'NormalDeepLinksService: Web platform - normal deep links not applicable',
          );
        }
        _isInitialized = true;
        return;
      }

      if (config.enableLogging) {
        print('NormalDeepLinksService: Starting initialization...');
      }

      // Handle initial link (app opened from deep link)
      final Uri? initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        if (config.enableLogging) {
          print(
            'NormalDeepLinksService: Initial link detected: $initialLink',
          );
        }
        await _handleDeepLink(initialLink);
      }

      // Listen for subsequent deep link events
      _appLinks.uriLinkStream.listen(
        (Uri deepLink) async {
          if (config.enableLogging) {
            print('NormalDeepLinksService: Received deep link: $deepLink');
          }
          await _handleDeepLink(deepLink);
        },
        onError: (error) {
          if (config.enableLogging) {
            print('NormalDeepLinksService: Error handling deep link: $error');
          }
          config.onError?.call('Failed to handle normal deep link: $error');
        },
      );

      _isInitialized = true;

      if (config.enableLogging) {
        print('NormalDeepLinksService: ✅ Initialization complete');
      }
    } catch (e) {
      if (config.enableLogging) {
        print('NormalDeepLinksService: ❌ Initialization failed: $e');
      }
      config.onError?.call('Failed to initialize normal deep links: $e');
    }
  }

  /// Handle incoming deep links
  Future<void> _handleDeepLink(Uri deepLink) async {
    try {
      // Create a unique identifier for this link to prevent duplicate processing
      final linkIdentifier = '${deepLink.path}?${deepLink.query}';

      // Check if this link was already processed recently
      if (_lastProcessedLink == linkIdentifier) {
        if (config.enableLogging) {
          print(
            'NormalDeepLinksService: Skipping duplicate link: $linkIdentifier',
          );
        }
        return;
      }

      final linkString = deepLink.toString();

      // Validate the deep link
      if (!_linkValidator.isValidDeepLink(linkString)) {
        if (config.enableLogging) {
          print(
            'NormalDeepLinksService: Invalid deep link format: $linkString',
          );
        }
        config.onError?.call('Invalid normal deep link format: $linkString');
        return;
      }

      if (config.enableLogging) {
        print(
            'NormalDeepLinksService: Processing valid deep link: $linkString');
      }

      // Call the configured callback with the deep link
      if (config.onDeepLink != null) {
        config.onDeepLink!(linkString);
        if (config.enableLogging) {
          print(
            'NormalDeepLinksService: ✅ Successfully processed normal deep link',
          );
        }
      } else if (config.enableLogging) {
        print('NormalDeepLinksService: ⚠️ No onDeepLink callback configured');
      }

      // Mark this link as processed
      _lastProcessedLink = linkIdentifier;

      // Clear the last processed link after a delay to allow for legitimate duplicates
      Future.delayed(const Duration(seconds: 2), () {
        if (_lastProcessedLink == linkIdentifier) {
          _lastProcessedLink = null;
        }
      });
    } catch (e) {
      if (config.enableLogging) {
        print('NormalDeepLinksService: Error handling deep link: $e');
      }
      config.onError?.call('Failed to handle normal deep link: $e');
    }
  }

  /// Clear the last processed link (useful for testing)
  void clearLastProcessedLink() {
    _lastProcessedLink = null;
    if (config.enableLogging) {
      print('NormalDeepLinksService: Cleared last processed link');
    }
  }

  /// Get the last processed link identifier (useful for debugging)
  String? get lastProcessedLink => _lastProcessedLink;

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Get the current app links instance for advanced usage
  AppLinks get appLinks => _appLinks;
}
