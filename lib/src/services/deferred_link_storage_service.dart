import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;

import '../models/deferred_link_config.dart';

/// Cross-platform storage service for deferred deep links
///
/// Manages persistent storage of deferred links across platforms:
/// - **Web**: Uses localStorage for immediate storage
/// - **Native**: Uses SharedPreferences for persistent storage
///
/// Provides automatic expiration, metadata tracking, and migration capabilities.
class DeferredLinkStorageService {
  final DeferredLinkConfig config;
  SharedPreferences? _prefs;

  /// Storage keys (configurable via DeferredLinkConfig)
  late final String _deferredLinkKey;
  late final String _deferredLinkTimestampKey;
  late final String _deferredLinkMetaKey;

  DeferredLinkStorageService(this.config) {
    // Initialize configurable storage keys
    _deferredLinkKey = '${config.storageKeyPrefix}deferred_link';
    _deferredLinkTimestampKey =
        '${config.storageKeyPrefix}deferred_link_timestamp';
    _deferredLinkMetaKey = '${config.storageKeyPrefix}deferred_link_meta';

    if (config.enableLogging) {
      print(
        'DeferredLinkStorageService: Initialized with prefix "${config.storageKeyPrefix}"',
      );
    }

    if (!kIsWeb) {
      _initializeSharedPreferences();
    }
  }

  /// Initialize SharedPreferences for native platforms
  Future<void> _initializeSharedPreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      if (config.enableLogging) {
        print('DeferredLinkStorageService: SharedPreferences initialized');
      }
    } catch (e) {
      if (config.enableLogging) {
        print(
          'DeferredLinkStorageService: Failed to initialize SharedPreferences: $e',
        );
      }
      config.onError?.call('Failed to initialize storage: $e');
    }
  }

  /// Store a deferred deep link with cross-platform support
  ///
  /// **Web**: Uses localStorage for immediate storage
  /// **Native**: Uses SharedPreferences for persistent storage
  ///
  /// Automatically adds timestamp and metadata for expiration tracking.
  Future<void> storeDeferredLink(String deepLinkUrl) async {
    try {
      final int timestamp = DateTime.now().millisecondsSinceEpoch;

      if (kIsWeb) {
        // Web platform: Use localStorage
        _storeInLocalStorage(deepLinkUrl, timestamp);
      } else {
        // Native platforms: Use SharedPreferences
        await _storeInSharedPreferences(deepLinkUrl, timestamp);
      }

      if (config.enableLogging) {
        print(
          'DeferredLinkStorageService: Stored deferred link: ${deepLinkUrl.substring(0, deepLinkUrl.length.clamp(0, 50))}...',
        );
      }
    } catch (e) {
      if (config.enableLogging) {
        print('DeferredLinkStorageService: Error storing deferred link: $e');
      }
      config.onError?.call('Failed to store deferred link: $e');
    }
  }

  /// Get stored deferred link with automatic expiration check
  ///
  /// Returns null if:
  /// - No link is stored
  /// - Link has expired (older than config.maxLinkAge)
  /// - Storage is not accessible
  Future<String?> getStoredDeferredLink() async {
    try {
      String? link;
      int? timestamp;

      if (kIsWeb) {
        // Web platform: Get from localStorage
        final result = _getFromLocalStorage();
        link = result['link'];
        timestamp = result['timestamp'];
      } else {
        // Native platforms: Get from SharedPreferences
        final result = await _getFromSharedPreferences();
        link = result['link'];
        timestamp = result['timestamp'];
      }

      if (link == null || timestamp == null) {
        if (config.enableLogging) {
          print('DeferredLinkStorageService: No stored link found');
        }
        return null;
      }

      // Check if the link has expired
      final DateTime linkTimestamp = DateTime.fromMillisecondsSinceEpoch(
        timestamp,
      );
      final DateTime now = DateTime.now();
      final Duration linkAge = now.difference(linkTimestamp);

      if (linkAge > config.maxLinkAge) {
        if (config.enableLogging) {
          print(
            'DeferredLinkStorageService: Deferred link expired (${linkAge.inDays} days old), removing',
          );
        }
        await clearStoredDeferredLink();
        return null;
      }

      if (config.enableLogging) {
        print(
          'DeferredLinkStorageService: Retrieved deferred link: ${link.substring(0, link.length.clamp(0, 50))}... (${linkAge.inHours}h old)',
        );
      }
      return link;
    } catch (e) {
      if (config.enableLogging) {
        print(
          'DeferredLinkStorageService: Error getting stored deferred link: $e',
        );
      }
      config.onError?.call('Failed to get stored deferred link: $e');
      return null;
    }
  }

  /// Clear stored deferred link from both platforms
  Future<void> clearStoredDeferredLink() async {
    try {
      if (kIsWeb) {
        // Web platform: Clear localStorage
        _clearFromLocalStorage();
      } else {
        // Native platforms: Clear SharedPreferences
        await _clearFromSharedPreferences();
      }

      if (config.enableLogging) {
        print('DeferredLinkStorageService: Cleared stored deferred link');
      }
    } catch (e) {
      if (config.enableLogging) {
        print(
          'DeferredLinkStorageService: Error clearing stored deferred link: $e',
        );
      }
      config.onError?.call('Failed to clear stored deferred link: $e');
    }
  }

  /// Get stored deferred link metadata for debugging and analytics
  ///
  /// Returns information about the stored link including:
  /// - Link content (truncated for privacy)
  /// - Storage timestamp
  /// - Platform information
  /// - Age in hours
  Future<Map<String, dynamic>?> getStoredLinkMetadata() async {
    try {
      if (kIsWeb) {
        final metaStr = html.window.localStorage[_deferredLinkMetaKey];
        if (metaStr != null) {
          return {
            'raw': metaStr,
            'platform': 'web',
            'storageKey': _deferredLinkKey,
          };
        }
      } else {
        if (_prefs == null) {
          await _initializeSharedPreferences();
        }

        if (_prefs != null) {
          final link = _prefs!.getString(_deferredLinkKey);
          final timestamp = _prefs!.getInt(_deferredLinkTimestampKey);

          if (link != null && timestamp != null) {
            final ageHours =
                (DateTime.now().millisecondsSinceEpoch - timestamp) /
                (1000 * 60 * 60);
            return {
              'linkPreview':
                  link.substring(0, link.length.clamp(0, 50)) + '...',
              'timestamp': timestamp,
              'platform': 'native',
              'ageHours': ageHours.round(),
              'isExpired': ageHours > config.maxLinkAge.inHours,
              'storageKey': _deferredLinkKey,
            };
          }
        }
      }

      return null;
    } catch (e) {
      if (config.enableLogging) {
        print('DeferredLinkStorageService: Error getting metadata: $e');
      }
      return {'error': e.toString()};
    }
  }

  // Web-specific localStorage methods
  void _storeInLocalStorage(String link, int timestamp) {
    if (!kIsWeb) return;

    try {
      html.window.localStorage[_deferredLinkKey] = link;
      html.window.localStorage[_deferredLinkTimestampKey] = timestamp
          .toString();

      // Store additional metadata for debugging
      final meta = {
        'platform': 'web',
        'userAgent': html.window.navigator.userAgent,
        'timestamp': timestamp,
        'url': html.window.location.href,
        'storagePrefix': config.storageKeyPrefix,
      };
      html.window.localStorage[_deferredLinkMetaKey] = meta.toString();

      if (config.enableLogging) {
        print(
          'DeferredLinkStorageService: Stored in localStorage with key: $_deferredLinkKey',
        );
      }
    } catch (e) {
      if (config.enableLogging) {
        print('DeferredLinkStorageService: Error storing in localStorage: $e');
      }
      config.onError?.call('localStorage storage failed: $e');
    }
  }

  Map<String, dynamic> _getFromLocalStorage() {
    if (!kIsWeb) return {'link': null, 'timestamp': null};

    try {
      final link = html.window.localStorage[_deferredLinkKey];
      final timestampStr = html.window.localStorage[_deferredLinkTimestampKey];
      final timestamp = timestampStr != null
          ? int.tryParse(timestampStr)
          : null;

      return {'link': link, 'timestamp': timestamp};
    } catch (e) {
      if (config.enableLogging) {
        print(
          'DeferredLinkStorageService: Error getting from localStorage: $e',
        );
      }
      return {'link': null, 'timestamp': null};
    }
  }

  void _clearFromLocalStorage() {
    if (!kIsWeb) return;

    try {
      html.window.localStorage.remove(_deferredLinkKey);
      html.window.localStorage.remove(_deferredLinkTimestampKey);
      html.window.localStorage.remove(_deferredLinkMetaKey);

      if (config.enableLogging) {
        print(
          'DeferredLinkStorageService: Cleared localStorage with prefix: ${config.storageKeyPrefix}',
        );
      }
    } catch (e) {
      if (config.enableLogging) {
        print('DeferredLinkStorageService: Error clearing localStorage: $e');
      }
    }
  }

  // Native-specific SharedPreferences methods
  Future<void> _storeInSharedPreferences(String link, int timestamp) async {
    if (_prefs == null) {
      await _initializeSharedPreferences();
    }

    if (_prefs == null) {
      if (config.enableLogging) {
        print('DeferredLinkStorageService: SharedPreferences not available');
      }
      config.onError?.call('SharedPreferences not available');
      return;
    }

    try {
      await _prefs!.setString(_deferredLinkKey, link);
      await _prefs!.setInt(_deferredLinkTimestampKey, timestamp);

      if (config.enableLogging) {
        print(
          'DeferredLinkStorageService: Stored in SharedPreferences with key: $_deferredLinkKey',
        );
      }
    } catch (e) {
      if (config.enableLogging) {
        print(
          'DeferredLinkStorageService: Error storing in SharedPreferences: $e',
        );
      }
      config.onError?.call('SharedPreferences storage failed: $e');
    }
  }

  Future<Map<String, dynamic>> _getFromSharedPreferences() async {
    if (_prefs == null) {
      await _initializeSharedPreferences();
    }

    if (_prefs == null) {
      return {'link': null, 'timestamp': null};
    }

    try {
      final link = _prefs!.getString(_deferredLinkKey);
      final timestamp = _prefs!.getInt(_deferredLinkTimestampKey);

      return {'link': link, 'timestamp': timestamp};
    } catch (e) {
      if (config.enableLogging) {
        print(
          'DeferredLinkStorageService: Error getting from SharedPreferences: $e',
        );
      }
      return {'link': null, 'timestamp': null};
    }
  }

  Future<void> _clearFromSharedPreferences() async {
    if (_prefs == null) {
      await _initializeSharedPreferences();
    }

    if (_prefs == null) {
      return;
    }

    try {
      await _prefs!.remove(_deferredLinkKey);
      await _prefs!.remove(_deferredLinkTimestampKey);
      await _prefs!.remove(_deferredLinkMetaKey);

      if (config.enableLogging) {
        print(
          'DeferredLinkStorageService: Cleared SharedPreferences with prefix: ${config.storageKeyPrefix}',
        );
      }
    } catch (e) {
      if (config.enableLogging) {
        print(
          'DeferredLinkStorageService: Error clearing SharedPreferences: $e',
        );
      }
    }
  }

  /// Cleanup expired links (can be called periodically)
  ///
  /// Useful for maintenance and keeping storage clean
  Future<bool> cleanupExpiredLinks() async {
    try {
      final metadata = await getStoredLinkMetadata();
      if (metadata != null && metadata['isExpired'] == true) {
        await clearStoredDeferredLink();
        if (config.enableLogging) {
          print('DeferredLinkStorageService: Cleaned up expired link');
        }
        return true;
      }
      return false;
    } catch (e) {
      if (config.enableLogging) {
        print('DeferredLinkStorageService: Error during cleanup: $e');
      }
      return false;
    }
  }
}
