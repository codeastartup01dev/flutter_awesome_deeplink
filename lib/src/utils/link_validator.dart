import '../models/normal_deep_link_config.dart';
import '../models/deferred_link_config.dart';

/// Utility class for validating deep links against configuration
///
/// Provides comprehensive validation for different deep link formats:
/// - Custom schemes (myapp://content?id=123)
/// - Web-based links (https://myapp.com/app/content?id=123)
/// - Pattern-based fallback validation
class LinkValidator {
  final String appScheme;
  final List<String> validDomains;
  final List<String> validPaths;

  const LinkValidator({
    required this.appScheme,
    required this.validDomains,
    required this.validPaths,
  });

  /// Create LinkValidator from NormalDeepLinkConfig
  factory LinkValidator.fromNormalConfig(NormalDeepLinkConfig config) {
    return LinkValidator(
      appScheme: config.appScheme,
      validDomains: config.validDomains,
      validPaths: config.validPaths,
    );
  }

  /// Create LinkValidator from DeferredLinkConfig
  factory LinkValidator.fromDeferredConfig(DeferredLinkConfig config) {
    return LinkValidator(
      appScheme: config.appScheme,
      validDomains: config.validDomains,
      validPaths: config.validPaths,
    );
  }

  /// Validate if a link matches the configured criteria
  ///
  /// Returns true if the link is valid according to:
  /// 1. Custom scheme validation (if matches appScheme)
  /// 2. Web-based domain and path validation
  /// 3. Pattern-based fallback validation
  ///
  /// **Example Usage**:
  /// ```dart
  /// final validator = LinkValidator(config);
  /// final isValid = validator.isValidDeepLink('myapp://content?id=123');
  /// ```
  bool isValidDeepLink(String link) {
    try {
      final uri = Uri.parse(link);

      // 1. Custom scheme validation (e.g., myapp://content?id=123)
      if (uri.scheme == appScheme) {
        return _validateCustomScheme(uri);
      }

      // 2. Web-based deep link validation (e.g., https://myapp.com/app/content?id=123)
      if (_isWebScheme(uri.scheme)) {
        return _validateWebLink(uri);
      }

      // 3. Pattern-based fallback validation
      return _validateByPatterns(link);
    } catch (e) {
      // Note: Logging removed since we don't have enableLogging in the validator anymore
      return false;
    }
  }

  /// Validate custom scheme deep links
  ///
  /// Format: myapp://host?id=value
  /// Validates:
  /// - Required ID parameter
  /// - Optional host validation against valid paths
  bool _validateCustomScheme(Uri uri) {
    try {
      // Check if ID parameter is present and not empty
      final hasRequiredId =
          uri.queryParameters.containsKey('id') &&
          uri.queryParameters['id']?.isNotEmpty == true;

      if (!hasRequiredId) {
        return false;
      }

      // Optional: Validate host against configured paths
      if (validPaths.isNotEmpty && uri.host.isNotEmpty) {
        final hasValidHost = validPaths.any(
          (path) =>
              path.replaceAll('/', '').toLowerCase() == uri.host.toLowerCase(),
        );

        if (!hasValidHost) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate web-based deep links
  ///
  /// Format: https://myapp.com/app/content?id=value
  /// Validates:
  /// - Domain is in validDomains list
  /// - Path matches validPaths patterns
  /// - Required ID parameter is present
  bool _validateWebLink(Uri uri) {
    try {
      // Check if domain is valid
      if (!validDomains.contains(uri.host)) {
        return false;
      }

      // Check if path matches valid patterns
      final hasValidPath = validPaths.any(
        (validPath) => uri.path.contains(validPath),
      );

      if (!hasValidPath) {
        return false;
      }

      // Check for required ID parameter
      final hasRequiredId =
          uri.queryParameters.containsKey('id') &&
          uri.queryParameters['id']?.isNotEmpty == true;

      if (!hasRequiredId) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Pattern-based fallback validation
  ///
  /// Uses regex patterns to validate links that might not parse correctly
  /// or have non-standard formats
  bool _validateByPatterns(String link) {
    try {
      // Create validation patterns based on configuration
      final patterns = <RegExp>[
        // Custom scheme patterns
        RegExp('${appScheme}://\\w+\\?id=\\w+'),

        // Web link patterns for each valid domain and path combination
        ...validDomains.expand(
          (domain) => validPaths.map(
            (path) => RegExp('https?://$domain${RegExp.escape(path)}.*id=\\w+'),
          ),
        ),
      ];

      final hasValidPattern = patterns.any((pattern) => pattern.hasMatch(link));
      return hasValidPattern;
    } catch (e) {
      return false;
    }
  }

  /// Check if scheme is a web scheme (http/https)
  bool _isWebScheme(String scheme) {
    return scheme == 'http' || scheme == 'https';
  }

  /// Extract ID parameter from a valid deep link
  ///
  /// Returns the ID value if found, null otherwise
  ///
  /// **Example**:
  /// ```dart
  /// final id = validator.extractId('myapp://content?id=123&other=value');
  /// // Returns: '123'
  /// ```
  String? extractId(String link) {
    try {
      final uri = Uri.parse(link);
      return uri.queryParameters['id'];
    } catch (e) {
      return null;
    }
  }

  /// Extract all query parameters from a deep link
  ///
  /// Returns a map of all query parameters
  ///
  /// **Example**:
  /// ```dart
  /// final params = validator.extractParameters('myapp://content?id=123&type=challenge');
  /// // Returns: {'id': '123', 'type': 'challenge'}
  /// ```
  Map<String, String> extractParameters(String link) {
    try {
      final uri = Uri.parse(link);
      return uri.queryParameters;
    } catch (e) {
      return {};
    }
  }

  /// Get validation summary for debugging
  ///
  /// Returns detailed information about what would be validated
  Map<String, dynamic> getValidationSummary() {
    return {
      'appScheme': appScheme,
      'validDomains': validDomains,
      'validPaths': validPaths,
      'customSchemePattern': '${appScheme}://host?id=value',
      'webLinkPatterns': validDomains
          .expand(
            (domain) =>
                validPaths.map((path) => 'https://$domain$path?id=value'),
          )
          .toList(),
    };
  }
}
