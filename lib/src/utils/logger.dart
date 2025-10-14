/// Simple logger utility for the plugin
///
/// Provides conditional logging based on configuration
class PluginLogger {
  final bool enableLogging;
  final String prefix;

  const PluginLogger({
    required this.enableLogging,
    this.prefix = 'FlutterAwesomeDeeplink',
  });

  /// Log debug message
  void d(String message) {
    if (enableLogging) {
      // ignore: avoid_print
      print('$prefix: $message');
    }
  }

  /// Log info message
  void i(String message) {
    if (enableLogging) {
      // ignore: avoid_print
      print('$prefix: $message');
    }
  }

  /// Log warning message
  void w(String message) {
    if (enableLogging) {
      // ignore: avoid_print
      print('$prefix: WARNING: $message');
    }
  }

  /// Log error message
  void e(String message) {
    if (enableLogging) {
      // ignore: avoid_print
      print('$prefix: ERROR: $message');
    }
  }
}
