/// Configuration class for normal deep link handling
///
/// This handles real-time deep links when the app is already installed.
/// Uses the app_links package for cross-platform deep link detection.
class NormalDeepLinkConfig {
  /// App's custom URL scheme (e.g., 'myapp')
  /// Used for custom scheme deep links like myapp://content?id=123
  final String appScheme;

  /// List of valid domains that can trigger deep links
  /// Example: ['myapp.com', 'app.myapp.com']
  final List<String> validDomains;

  /// List of valid path patterns for deep links
  /// Example: ['/app/', '/content/', '/challenge/']
  final List<String> validPaths;

  /// Callback function called when a normal deep link is received
  ///
  /// This handles real-time deep links when the app is already installed:
  /// ```dart
  /// onNormalLink: (uri) {
  ///   final id = uri.queryParameters['id'];
  ///   if (uri.path.contains('/challenge')) {
  ///     GoRouter.of(context).push('/challenge/$id');
  ///   }
  /// }
  /// ```
  final Function(Uri uri)? onNormalLink;

  /// Callback function called when an error occurs during normal deep link processing
  final Function(String error)? onError;

  /// Enable detailed logging for debugging
  /// Default: false (disable in production)
  final bool enableLogging;

  /// Storage key prefix for normal deep link data
  /// Default: 'flutter_awesome_deeplink_normal_'
  final String storageKeyPrefix;

  const NormalDeepLinkConfig({
    required this.appScheme,
    required this.validDomains,
    this.validPaths = const ['/'],
    this.onNormalLink,
    this.onError,
    this.enableLogging = false,
    this.storageKeyPrefix = 'flutter_awesome_deeplink_normal_',
  });

  /// Create a copy of this config with updated values
  NormalDeepLinkConfig copyWith({
    String? appScheme,
    List<String>? validDomains,
    List<String>? validPaths,
    Function(Uri)? onNormalLink,
    Function(String)? onError,
    bool? enableLogging,
    String? storageKeyPrefix,
  }) {
    return NormalDeepLinkConfig(
      appScheme: appScheme ?? this.appScheme,
      validDomains: validDomains ?? this.validDomains,
      validPaths: validPaths ?? this.validPaths,
      onNormalLink: onNormalLink ?? this.onNormalLink,
      onError: onError ?? this.onError,
      enableLogging: enableLogging ?? this.enableLogging,
      storageKeyPrefix: storageKeyPrefix ?? this.storageKeyPrefix,
    );
  }

  @override
  String toString() {
    return 'NormalDeepLinkConfig('
        'appScheme: $appScheme, '
        'validDomains: $validDomains, '
        'validPaths: $validPaths, '
        'enableLogging: $enableLogging'
        ')';
  }
}
