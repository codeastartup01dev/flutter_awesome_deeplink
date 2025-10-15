import 'dart:developer' as developer;

/// **Plugin Logger Utility**
///
/// Provides unified logging for the flutter_awesome_deeplink plugin.
/// Can use an external logger instance (like flutter_awesome_logger) or fall back to dart:developer log.
class PluginLogger {
  final bool enableLogging;
  final dynamic externalLogger;

  const PluginLogger({required this.enableLogging, this.externalLogger});

  /// Log debug message
  void d(String message) {
    if (!enableLogging) return;

    if (externalLogger != null) {
      try {
        // Try to use the external logger's debug method
        if (externalLogger.d != null) {
          externalLogger.d('FlutterAwesomeDeeplink: $message');
        } else if (externalLogger.log != null) {
          externalLogger.log('DEBUG: FlutterAwesomeDeeplink: $message');
        } else {
          // Fallback to dart:developer log
          developer.log(message, name: 'FlutterAwesomeDeeplink', level: 500);
        }
      } catch (e) {
        // If external logger fails, fallback to dart:developer log
        developer.log(message, name: 'FlutterAwesomeDeeplink', level: 500);
      }
    } else {
      // Direct fallback to dart:developer log when no external logger
      developer.log(message, name: 'FlutterAwesomeDeeplink', level: 500);
    }
  }

  /// Log info message
  void i(String message) {
    if (!enableLogging) return;

    if (externalLogger != null) {
      try {
        // Try to use the external logger's info method
        if (externalLogger.i != null) {
          externalLogger.i('FlutterAwesomeDeeplink: $message');
        } else if (externalLogger.log != null) {
          externalLogger.log('INFO: FlutterAwesomeDeeplink: $message');
        } else {
          // Fallback to dart:developer log
          developer.log(message, name: 'FlutterAwesomeDeeplink', level: 800);
        }
      } catch (e) {
        // If external logger fails, fallback to dart:developer log
        developer.log(message, name: 'FlutterAwesomeDeeplink', level: 800);
      }
    } else {
      // Direct fallback to dart:developer log when no external logger
      developer.log(message, name: 'FlutterAwesomeDeeplink', level: 800);
    }
  }

  /// Log warning message
  void w(String message) {
    if (!enableLogging) return;

    if (externalLogger != null) {
      try {
        // Try to use the external logger's warning method
        if (externalLogger.w != null) {
          externalLogger.w('FlutterAwesomeDeeplink: $message');
        } else if (externalLogger.log != null) {
          externalLogger.log('WARNING: FlutterAwesomeDeeplink: $message');
        } else {
          // Fallback to dart:developer log
          developer.log(message, name: 'FlutterAwesomeDeeplink', level: 900);
        }
      } catch (e) {
        // If external logger fails, fallback to dart:developer log
        developer.log(message, name: 'FlutterAwesomeDeeplink', level: 900);
      }
    } else {
      // Direct fallback to dart:developer log when no external logger
      developer.log(message, name: 'FlutterAwesomeDeeplink', level: 900);
    }
  }

  /// Log error message
  void e(String message, {dynamic error, StackTrace? stackTrace}) {
    if (!enableLogging) return;

    final fullMessage = error != null
        ? 'FlutterAwesomeDeeplink: $message - Error: $error'
        : 'FlutterAwesomeDeeplink: $message';

    if (externalLogger != null) {
      try {
        // Try to use the external logger's error method
        if (externalLogger.e != null) {
          externalLogger.e(fullMessage, error: error, stackTrace: stackTrace);
        } else if (externalLogger.log != null) {
          externalLogger.log('ERROR: $fullMessage');
        } else {
          // Fallback to dart:developer log
          developer.log(
            fullMessage,
            name: 'FlutterAwesomeDeeplink',
            level: 1000,
            error: error,
            stackTrace: stackTrace,
          );
        }
      } catch (e) {
        // If external logger fails, fallback to dart:developer log
        developer.log(
          fullMessage,
          name: 'FlutterAwesomeDeeplink',
          level: 1000,
          error: error,
          stackTrace: stackTrace,
        );
      }
    } else {
      // Direct fallback to dart:developer log when no external logger
      developer.log(
        fullMessage,
        name: 'FlutterAwesomeDeeplink',
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
