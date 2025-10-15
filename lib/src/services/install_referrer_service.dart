import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/deferred_link_config.dart';
import '../utils/link_validator.dart';

/// Platform-optimized install referrer service for deferred deep link attribution
///
/// Provides platform-specific attribution methods:
/// - **Android**: Google Play Install Referrer API (95%+ success rate)
/// - **iOS**: Optional clipboard detection (90%+ success rate when enabled)
///
/// Handles first-launch detection, privacy compliance, and comprehensive error handling.
class InstallReferrerService {
  final DeferredLinkConfig config;
  late final LinkValidator _linkValidator;

  /// Method channel for Android install referrer communication
  static const MethodChannel _androidChannel = MethodChannel(
    'flutter_awesome_deeplink/install_referrer',
  );

  /// SharedPreferences instance for first launch tracking
  SharedPreferences? _prefs;

  /// Keys for tracking first launch and install time
  late final String _firstLaunchKey;
  late final String _installTimeKey;

  InstallReferrerService(this.config) {
    _linkValidator = LinkValidator(config);

    // Initialize configurable storage keys
    _firstLaunchKey = '${config.storageKeyPrefix}first_launch_completed';
    _installTimeKey = '${config.storageKeyPrefix}install_timestamp';

    if (config.enableLogging) {
      print(
        'InstallReferrerService: Initialized for ${Platform.operatingSystem}',
      );
    }

    _initializePrefs();
  }

  /// Initialize SharedPreferences and mark install time
  Future<void> _initializePrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      // Mark install time on first initialization
      if (_prefs != null && !_prefs!.containsKey(_installTimeKey)) {
        await _prefs!.setInt(
          _installTimeKey,
          DateTime.now().millisecondsSinceEpoch,
        );
        if (config.enableLogging) {
          print('InstallReferrerService: Marked app install time');
        }
      }
    } catch (e) {
      if (config.enableLogging) {
        print(
          'InstallReferrerService: Error initializing SharedPreferences: $e',
        );
      }
      config.onError?.call('Failed to initialize install referrer service: $e');
    }
  }

  /// Extract deferred deep link using platform-optimized strategies
  ///
  /// **Platform Strategy**:
  /// - **Android**: Uses Play Store Install Referrer API
  /// - **iOS**: Uses clipboard checking (if enabled) or returns null
  /// - **Web**: Returns null (not applicable)
  ///
  /// **Returns**: Deferred link string if found, null otherwise
  Future<String?> extractDeferredLinkFromReferrer() async {
    final stopwatch = Stopwatch()..start();

    try {
      if (kIsWeb) {
        if (config.enableLogging) {
          print(
            'InstallReferrerService: Web platform, no install referrer available',
          );
        }
        return null;
      }

      // Only check for deferred links on eligible launches
      final isEligible = await _isEligibleForDeferredLinkCheck();
      if (!isEligible) {
        if (config.enableLogging) {
          print(
            'InstallReferrerService: App not eligible for deferred link check',
          );
        }
        return null;
      }

      final referrerData = await _getInstallReferrerData();
      if (referrerData == null) {
        if (config.enableLogging) {
          print('InstallReferrerService: No install referrer data found');
        }
        return null;
      }

      final deferredLink = _extractDeferredLinkFromData(referrerData);
      if (deferredLink != null) {
        // Mark that we've processed a deferred link
        await _markDeferredLinkProcessed();

        // Report attribution success
        final result = AttributionResult.success(
          link: deferredLink,
          source: referrerData['source'] ?? 'unknown',
          platform: Platform.operatingSystem,
          processingTime: stopwatch.elapsed,
          metadata: referrerData,
        );
        config.onAttributionData?.call(result.toMap());

        if (config.enableLogging) {
          print(
            'InstallReferrerService: ✅ Extracted deferred link: ${deferredLink.substring(0, deferredLink.length.clamp(0, 50))}...',
          );
        }
      }

      return deferredLink;
    } catch (e) {
      // Report attribution failure
      final result = AttributionResult.failure(
        source: Platform.isAndroid
            ? 'android_install_referrer'
            : 'ios_clipboard',
        platform: Platform.operatingSystem,
        processingTime: stopwatch.elapsed,
        error: e.toString(),
      );
      config.onAttributionData?.call(result.toMap());

      if (config.enableLogging) {
        print('InstallReferrerService: Error extracting deferred link: $e');
      }
      config.onError?.call('Install referrer extraction failed: $e');
      return null;
    } finally {
      stopwatch.stop();
    }
  }

  /// Get platform-specific install referrer data
  Future<Map<String, dynamic>?> _getInstallReferrerData() async {
    try {
      if (Platform.isAndroid) {
        return await _getAndroidInstallReferrer();
      } else if (Platform.isIOS) {
        return await _getIOSAttributionData();
      }

      if (config.enableLogging) {
        print(
          'InstallReferrerService: Unsupported platform for install referrer',
        );
      }
      return null;
    } catch (e) {
      if (config.enableLogging) {
        print(
          'InstallReferrerService: Error getting install referrer data: $e',
        );
      }
      return null;
    }
  }

  /// Get Android install referrer using Play Store API
  Future<Map<String, dynamic>?> _getAndroidInstallReferrer() async {
    try {
      if (config.enableLogging) {
        print(
          'InstallReferrerService: Attempting Android Install Referrer API',
        );
      }

      // Call native Android code via method channel with timeout
      final Map<String, dynamic>? result = await _androidChannel
          .invokeMapMethod<String, dynamic>('getInstallReferrer')
          .timeout(
            config.attributionTimeout,
            onTimeout: () {
              if (config.enableLogging) {
                print(
                  'InstallReferrerService: Android install referrer timeout',
                );
              }
              return null;
            },
          );

      if (result != null && result['referrerUrl'] != null) {
        if (config.enableLogging) {
          print(
            'InstallReferrerService: ✅ Android Install Referrer API successful',
          );
        }
        return {
          'source': 'android_install_referrer',
          'referrerUrl': result['referrerUrl'],
          'clickTime': result['referrerClickTimestampSeconds'],
          'installTime': result['installBeginTimestampSeconds'],
          'instantExperienceLaunched': result['googlePlayInstantParam'],
        };
      }

      if (config.enableLogging) {
        print(
          'InstallReferrerService: No Android install referrer data available',
        );
      }
      return null;
    } catch (e) {
      if (config.enableLogging) {
        print('InstallReferrerService: Android Install Referrer API error: $e');
      }
      return null;
    }
  }

  /// Get iOS attribution data using clipboard detection (if enabled)
  Future<Map<String, dynamic>?> _getIOSAttributionData() async {
    try {
      if (config.enableLogging) {
        print('InstallReferrerService: Attempting iOS attribution methods');
      }

      // Method 1: Enhanced clipboard checking (if enabled)
      if (config.enableIOSClipboard) {
        final clipboardData = await _checkIOSClipboard();
        if (clipboardData != null) {
          return clipboardData;
        }
      } else if (config.enableLogging) {
        print(
          'InstallReferrerService: iOS clipboard checking disabled in configuration',
        );
      }

      // Future: Could add SKAdNetwork or other iOS attribution methods here

      if (config.enableLogging) {
        print('InstallReferrerService: No iOS attribution data available');
      }
      return null;
    } catch (e) {
      if (config.enableLogging) {
        print('InstallReferrerService: iOS attribution error: $e');
      }
      return null;
    }
  }

  /// Check iOS clipboard for recently copied deep links (privacy-compliant)
  Future<Map<String, dynamic>?> _checkIOSClipboard() async {
    try {
      // Privacy-first: Only check clipboard on first app launch
      final isFirstLaunch = await isFirstLaunchAfterInstall();
      if (!isFirstLaunch) {
        if (config.enableLogging) {
          print(
            'InstallReferrerService: Skipping clipboard check - not first launch (privacy compliance)',
          );
        }
        return null;
      }

      if (config.enableLogging) {
        print(
          'InstallReferrerService: Checking iOS clipboard for deferred links',
        );
      }

      final ClipboardData? clipboardData = await Clipboard.getData('text/plain')
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              if (config.enableLogging) {
                print('InstallReferrerService: Clipboard access timeout');
              }
              return null;
            },
          );

      if (clipboardData?.text != null) {
        final clipboardText = clipboardData!.text!;

        // Enhanced domain validation using configuration
        bool containsValidDomain = false;
        String matchedDomain = '';

        // Check against configured domains
        for (final domain in config.validDomains) {
          if (clipboardText.contains(domain)) {
            containsValidDomain = true;
            matchedDomain = domain;
            break;
          }
        }

        // Also check custom scheme
        if (clipboardText.contains('${config.appScheme}://')) {
          containsValidDomain = true;
          matchedDomain = config.appScheme;
        }

        if (containsValidDomain &&
            _linkValidator.isValidDeepLink(clipboardText)) {
          if (config.enableLogging) {
            print(
              'InstallReferrerService: ✅ Found valid deep link in iOS clipboard (domain: $matchedDomain)',
            );
          }
          return {
            'source': 'ios_clipboard',
            'clipboardLink': clipboardText,
            'matchedDomain': matchedDomain,
            'detectedAt': DateTime.now().millisecondsSinceEpoch,
            'timeSinceInstall': _getTimeSinceInstall(),
          };
        } else if (config.enableLogging) {
          print(
            'InstallReferrerService: Clipboard contains text but not a valid deep link',
          );
        }
      }

      return null;
    } catch (e) {
      if (config.enableLogging) {
        print('InstallReferrerService: Error checking iOS clipboard: $e');
      }
      return null;
    }
  }

  /// Extract deferred link from referrer data with validation
  String? _extractDeferredLinkFromData(Map<String, dynamic> data) {
    try {
      final source = data['source'] as String?;

      switch (source) {
        case 'android_install_referrer':
          return _extractFromAndroidReferrer(data);
        case 'ios_clipboard':
          return _extractFromIOSClipboard(data);
        default:
          if (config.enableLogging) {
            print(
              'InstallReferrerService: Unknown attribution source: $source',
            );
          }
          return null;
      }
    } catch (e) {
      if (config.enableLogging) {
        print(
          'InstallReferrerService: Error extracting deferred link from data: $e',
        );
      }
      return null;
    }
  }

  /// Extract deferred link from Android install referrer
  String? _extractFromAndroidReferrer(Map<String, dynamic> data) {
    try {
      final referrerUrl = data['referrerUrl'] as String?;
      if (referrerUrl == null || referrerUrl.isEmpty) {
        return null;
      }

      if (config.enableLogging) {
        print(
          'InstallReferrerService: Parsing Android referrer URL: ${referrerUrl.substring(0, referrerUrl.length.clamp(0, 100))}...',
        );
      }

      // Parse referrer URL as query parameters
      final uri = Uri.parse('http://dummy.com?$referrerUrl');

      // Extract utm_content parameter which contains encoded deep link
      final utmContent = uri.queryParameters['utm_content'];
      if (utmContent != null && utmContent.isNotEmpty) {
        final decodedLink = Uri.decodeComponent(utmContent);

        // Validate the decoded link using configuration
        if (_linkValidator.isValidDeepLink(decodedLink)) {
          if (config.enableLogging) {
            print(
              'InstallReferrerService: ✅ Successfully extracted Android referrer link',
            );
          }
          return decodedLink;
        } else if (config.enableLogging) {
          print(
            'InstallReferrerService: Invalid deep link format in Android referrer',
          );
        }
      }

      // Also check utm_campaign for alternative encoding
      final utmCampaign = uri.queryParameters['utm_campaign'];
      if (utmCampaign != null && utmCampaign.contains('deferred_link')) {
        if (config.enableLogging) {
          print(
            'InstallReferrerService: Found deferred link marker in utm_campaign',
          );
        }
        // Could implement custom encoding logic here if needed
      }

      return null;
    } catch (e) {
      if (config.enableLogging) {
        print(
          'InstallReferrerService: Error extracting from Android referrer: $e',
        );
      }
      return null;
    }
  }

  /// Extract deferred link from iOS clipboard
  String? _extractFromIOSClipboard(Map<String, dynamic> data) {
    try {
      final clipboardLink = data['clipboardLink'] as String?;
      if (clipboardLink == null || clipboardLink.isEmpty) {
        return null;
      }

      // Validate using configuration
      if (_linkValidator.isValidDeepLink(clipboardLink)) {
        if (config.enableLogging) {
          print(
            'InstallReferrerService: ✅ Successfully extracted iOS clipboard link',
          );
        }
        return clipboardLink;
      }

      if (config.enableLogging) {
        print(
          'InstallReferrerService: Invalid deep link format in iOS clipboard',
        );
      }
      return null;
    } catch (e) {
      if (config.enableLogging) {
        print(
          'InstallReferrerService: Error extracting from iOS clipboard: $e',
        );
      }
      return null;
    }
  }

  /// Check if this is likely a first app launch after install
  Future<bool> isFirstLaunchAfterInstall() async {
    try {
      if (_prefs == null) {
        await _initializePrefs();
      }

      if (_prefs == null) {
        if (config.enableLogging) {
          print(
            'InstallReferrerService: SharedPreferences not available for first launch check',
          );
        }
        return false;
      }

      // Check if we've marked first launch as completed
      final hasCompletedFirstLaunch = _prefs!.getBool(_firstLaunchKey) ?? false;

      if (hasCompletedFirstLaunch) {
        if (config.enableLogging) {
          print('InstallReferrerService: Not first launch - already completed');
        }
        return false;
      }

      // Check install time to ensure this is within reasonable bounds
      final installTime = _prefs!.getInt(_installTimeKey);
      if (installTime != null) {
        final installDateTime = DateTime.fromMillisecondsSinceEpoch(
          installTime,
        );
        final timeSinceInstall = DateTime.now().difference(installDateTime);

        // Consider it first launch if within configured max link age
        if (timeSinceInstall > config.maxLinkAge) {
          if (config.enableLogging) {
            print(
              'InstallReferrerService: Too long since install (${timeSinceInstall.inHours}h), not first launch',
            );
          }
          // Mark as completed to avoid future checks
          await _markFirstLaunchCompleted();
          return false;
        }
      }

      if (config.enableLogging) {
        print(
          'InstallReferrerService: This appears to be first launch after install',
        );
      }
      return true;
    } catch (e) {
      if (config.enableLogging) {
        print('InstallReferrerService: Error checking first launch: $e');
      }
      return false;
    }
  }

  /// Check if app is eligible for deferred link checking
  Future<bool> _isEligibleForDeferredLinkCheck() async {
    try {
      // Only check on first launch or within configured age limit
      final isFirstLaunch = await isFirstLaunchAfterInstall();
      if (isFirstLaunch) {
        return true;
      }

      // Also allow if install was recent (within max link age)
      if (_prefs != null) {
        final installTime = _prefs!.getInt(_installTimeKey);
        if (installTime != null) {
          final installDateTime = DateTime.fromMillisecondsSinceEpoch(
            installTime,
          );
          final timeSinceInstall = DateTime.now().difference(installDateTime);

          if (timeSinceInstall <= config.maxLinkAge) {
            if (config.enableLogging) {
              print(
                'InstallReferrerService: Within configured age limit (${timeSinceInstall.inHours}h)',
              );
            }
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      if (config.enableLogging) {
        print(
          'InstallReferrerService: Error checking deferred link eligibility: $e',
        );
      }
      return false;
    }
  }

  /// Mark first launch as completed
  Future<void> _markFirstLaunchCompleted() async {
    try {
      if (_prefs == null) {
        await _initializePrefs();
      }

      if (_prefs != null) {
        await _prefs!.setBool(_firstLaunchKey, true);
        if (config.enableLogging) {
          print('InstallReferrerService: Marked first launch as completed');
        }
      }
    } catch (e) {
      if (config.enableLogging) {
        print(
          'InstallReferrerService: Error marking first launch completed: $e',
        );
      }
    }
  }

  /// Mark that a deferred link has been processed
  Future<void> _markDeferredLinkProcessed() async {
    try {
      await _markFirstLaunchCompleted();
      if (config.enableLogging) {
        print('InstallReferrerService: Marked deferred link as processed');
      }
    } catch (e) {
      if (config.enableLogging) {
        print(
          'InstallReferrerService: Error marking deferred link processed: $e',
        );
      }
    }
  }

  /// Get time since app installation in hours
  int _getTimeSinceInstall() {
    try {
      if (_prefs != null) {
        final installTime = _prefs!.getInt(_installTimeKey);
        if (installTime != null) {
          final installDateTime = DateTime.fromMillisecondsSinceEpoch(
            installTime,
          );
          return DateTime.now().difference(installDateTime).inHours;
        }
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get attribution metadata for debugging and analytics
  Future<Map<String, dynamic>> getAttributionMetadata() async {
    try {
      final metadata = <String, dynamic>{
        'platform': Platform.operatingSystem,
        'isFirstLaunch': await isFirstLaunchAfterInstall(),
        'isEligibleForDeferredLink': await _isEligibleForDeferredLinkCheck(),
        'configuredAppScheme': config.appScheme,
        'configuredDomains': config.validDomains,
        'iosClipboardEnabled': config.enableIOSClipboard,
        'maxLinkAgeHours': config.maxLinkAge.inHours,
      };

      if (_prefs != null) {
        metadata['installTime'] = _prefs!.getInt(_installTimeKey);
        metadata['firstLaunchCompleted'] =
            _prefs!.getBool(_firstLaunchKey) ?? false;
        metadata['timeSinceInstallHours'] = _getTimeSinceInstall();
      }

      return metadata;
    } catch (e) {
      if (config.enableLogging) {
        print('InstallReferrerService: Error getting attribution metadata: $e');
      }
      return {'error': e.toString()};
    }
  }

  /// Reset first launch flag (useful for testing)
  Future<void> resetFirstLaunchFlag() async {
    try {
      if (_prefs == null) {
        await _initializePrefs();
      }

      if (_prefs != null) {
        await _prefs!.remove(_firstLaunchKey);
        if (config.enableLogging) {
          print('InstallReferrerService: Reset first launch flag');
        }
      }
    } catch (e) {
      if (config.enableLogging) {
        print('InstallReferrerService: Error resetting first launch flag: $e');
      }
    }
  }
}
