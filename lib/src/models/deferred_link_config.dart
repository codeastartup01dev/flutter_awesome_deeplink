/// Configuration class for Flutter Awesome Deeplink plugin
///
/// Provides comprehensive configuration options for deferred deep link attribution
/// with platform-optimized strategies and privacy-conscious defaults.
class DeferredLinkConfig {
  /// Custom app scheme (e.g., 'myapp', 'challengeapp')
  /// Used for validating custom scheme deep links like myapp://content?id=123
  final String appScheme;

  /// List of valid domains for web-based deep links
  /// Example: ['myapp.com', 'app.myapp.com', 'staging.myapp.com']
  final List<String> validDomains;

  /// List of valid path prefixes for deep links
  /// Example: ['/app/', '/content/', '/challenge/']
  final List<String> validPaths;

  /// Enable iOS clipboard checking for deferred link attribution
  ///
  /// **Privacy Note**: When enabled, the plugin will check the clipboard
  /// on first app launch to detect copied deep links. This provides 90%+
  /// attribution success on iOS but requires clipboard access.
  ///
  /// **Default**: false (privacy-first approach)
  final bool enableIOSClipboard;

  /// Maximum age for deferred links before they expire
  /// Links older than this duration will be automatically cleaned up
  ///
  /// **Default**: 7 days
  final Duration maxLinkAge;

  /// Custom prefix for storage keys to avoid conflicts
  /// Useful when multiple apps use the plugin on the same device
  ///
  /// **Default**: 'flutter_awesome_deeplink_'
  final String storageKeyPrefix;

  /// Callback function called when a deferred link is found and validated
  ///
  /// This is where you handle the deep link navigation in your app:
  /// ```dart
  /// onDeferredLink: (link) {
  ///   MyRouter.handleDeepLink(link);
  ///   // or
  ///   GoRouter.of(context).push('/content?id=${extractId(link)}');
  /// }
  /// ```
  final Function(String link)? onDeferredLink;

  /// Callback function called when an error occurs during attribution
  ///
  /// Useful for debugging and analytics:
  /// ```dart
  /// onError: (error) {
  ///   Analytics.track('deferred_link_error', {'error': error});
  ///   print('Deferred link error: $error');
  /// }
  /// ```
  final Function(String error)? onError;

  /// Callback function called with attribution metadata for debugging
  ///
  /// Provides detailed information about the attribution process:
  /// ```dart
  /// onAttributionData: (data) {
  ///   print('Attribution source: ${data['source']}');
  ///   print('Platform: ${data['platform']}');
  ///   print('Success: ${data['success']}');
  /// }
  /// ```
  final Function(Map<String, dynamic> data)? onAttributionData;

  /// Enable detailed logging for debugging
  ///
  /// **Default**: false (production mode)
  /// **Development**: Set to true for detailed attribution flow logs
  final bool enableLogging;

  /// Timeout duration for platform-specific attribution methods
  ///
  /// **Default**: 10 seconds
  /// Applies to Android Install Referrer API calls and iOS clipboard access
  final Duration attributionTimeout;

  /// Create a new deferred link configuration
  ///
  /// **Minimal Configuration Example**:
  /// ```dart
  /// DeferredLinkConfig(
  ///   appScheme: 'myapp',
  ///   validDomains: ['myapp.com'],
  ///   onDeferredLink: (link) => handleDeepLink(link),
  /// )
  /// ```
  ///
  /// **Full Configuration Example**:
  /// ```dart
  /// DeferredLinkConfig(
  ///   appScheme: 'myapp',
  ///   validDomains: ['myapp.com', 'app.myapp.com'],
  ///   validPaths: ['/app/', '/content/'],
  ///   enableIOSClipboard: true, // User opted in
  ///   maxLinkAge: Duration(days: 14),
  ///   storageKeyPrefix: 'myapp_deferred_',
  ///   enableLogging: true, // For development
  ///   onDeferredLink: (link) => MyRouter.handleDeepLink(link),
  ///   onError: (error) => Analytics.trackError(error),
  ///   onAttributionData: (data) => Analytics.trackAttribution(data),
  /// )
  /// ```
  const DeferredLinkConfig({
    required this.appScheme,
    required this.validDomains,
    this.validPaths = const ['/'],
    this.enableIOSClipboard = false, // Privacy-first default
    this.maxLinkAge = const Duration(days: 7),
    this.storageKeyPrefix = 'flutter_awesome_deeplink_',
    this.onDeferredLink,
    this.onError,
    this.onAttributionData,
    this.enableLogging = false,
    this.attributionTimeout = const Duration(seconds: 10),
  });

  /// Create a copy of this configuration with updated values
  DeferredLinkConfig copyWith({
    String? appScheme,
    List<String>? validDomains,
    List<String>? validPaths,
    bool? enableIOSClipboard,
    Duration? maxLinkAge,
    String? storageKeyPrefix,
    Function(String)? onDeferredLink,
    Function(String)? onError,
    Function(Map<String, dynamic>)? onAttributionData,
    bool? enableLogging,
    Duration? attributionTimeout,
  }) {
    return DeferredLinkConfig(
      appScheme: appScheme ?? this.appScheme,
      validDomains: validDomains ?? this.validDomains,
      validPaths: validPaths ?? this.validPaths,
      enableIOSClipboard: enableIOSClipboard ?? this.enableIOSClipboard,
      maxLinkAge: maxLinkAge ?? this.maxLinkAge,
      storageKeyPrefix: storageKeyPrefix ?? this.storageKeyPrefix,
      onDeferredLink: onDeferredLink ?? this.onDeferredLink,
      onError: onError ?? this.onError,
      onAttributionData: onAttributionData ?? this.onAttributionData,
      enableLogging: enableLogging ?? this.enableLogging,
      attributionTimeout: attributionTimeout ?? this.attributionTimeout,
    );
  }

  @override
  String toString() {
    return 'DeferredLinkConfig('
        'appScheme: $appScheme, '
        'validDomains: $validDomains, '
        'validPaths: $validPaths, '
        'enableIOSClipboard: $enableIOSClipboard, '
        'maxLinkAge: $maxLinkAge, '
        'enableLogging: $enableLogging'
        ')';
  }
}

/// Attribution result data structure
///
/// Contains information about the deferred link attribution process
class AttributionResult {
  /// The deferred link that was found (if any)
  final String? link;

  /// The source of the attribution
  /// - 'android_install_referrer': Android Install Referrer API
  /// - 'ios_clipboard': iOS clipboard detection
  /// - 'storage_service': Cross-platform storage fallback
  /// - 'none': No deferred link found
  final String source;

  /// Whether the attribution was successful
  final bool success;

  /// Platform where attribution was performed
  final String platform;

  /// Time taken for attribution process
  final Duration processingTime;

  /// Additional metadata about the attribution
  final Map<String, dynamic> metadata;

  /// Error message if attribution failed
  final String? error;

  const AttributionResult({
    this.link,
    required this.source,
    required this.success,
    required this.platform,
    required this.processingTime,
    this.metadata = const {},
    this.error,
  });

  /// Create a successful attribution result
  factory AttributionResult.success({
    required String link,
    required String source,
    required String platform,
    required Duration processingTime,
    Map<String, dynamic> metadata = const {},
  }) {
    return AttributionResult(
      link: link,
      source: source,
      success: true,
      platform: platform,
      processingTime: processingTime,
      metadata: metadata,
    );
  }

  /// Create a failed attribution result
  factory AttributionResult.failure({
    required String source,
    required String platform,
    required Duration processingTime,
    String? error,
    Map<String, dynamic> metadata = const {},
  }) {
    return AttributionResult(
      source: source,
      success: false,
      platform: platform,
      processingTime: processingTime,
      error: error,
      metadata: metadata,
    );
  }

  /// Convert to map for callbacks and analytics
  Map<String, dynamic> toMap() {
    return {
      'link': link,
      'source': source,
      'success': success,
      'platform': platform,
      'processingTimeMs': processingTime.inMilliseconds,
      'metadata': metadata,
      'error': error,
    };
  }

  @override
  String toString() {
    return 'AttributionResult('
        'success: $success, '
        'source: $source, '
        'platform: $platform, '
        'link: $link, '
        'processingTime: ${processingTime.inMilliseconds}ms'
        ')';
  }
}
