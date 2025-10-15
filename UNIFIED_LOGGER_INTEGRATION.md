# 🚀 Unified Logger Integration Guide

## Overview

The `flutter_awesome_deeplink` plugin now supports unified logging with external logger instances, allowing you to see all plugin logs in your app's main logger system, including production-ready loggers like [`flutter_awesome_logger`](https://pub.dev/packages/flutter_awesome_logger).

## 🎯 Key Benefits

- **✅ Single Logger Instance**: Plugin uses your app's logger, not a separate one
- **✅ Production Logs**: View plugin logs in production using `flutter_awesome_logger`'s floating button
- **✅ Unified UI**: All logs appear in the same beautiful logger interface
- **✅ Zero Duplication**: No separate logging systems or instances
- **✅ Flexible Fallback**: Works with any logger or falls back to `dart:developer` log

## 🔧 Integration Steps

### 1. Add flutter_awesome_logger to Your App

```yaml
# pubspec.yaml
dependencies:
  flutter_awesome_logger: ^1.0.0
  flutter_awesome_deeplink:
    path: ../flutter_awesome_deeplink  # Your local plugin path
```

### 2. Setup Your App's Logger

```dart
// lib/service_modules/my_logger/my_logger.dart
import 'package:flutter_awesome_logger/flutter_awesome_logger.dart';

final logger = FlutterAwesomeLogger.loggingUsingLogger;
```

### 3. Wrap Your App with FlutterAwesomeLogger

```dart
// lib/main.dart or your main app file
import 'package:flutter_awesome_logger/flutter_awesome_logger.dart';
import 'package:your_app/service_modules/my_logger/my_logger.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FlutterAwesomeLogger(
        enabled: true, // Enable for production logging
        // Auto-configure logger settings
        loggerConfig: const AwesomeLoggerConfig(
          maxLogEntries: 500,
          showFilePaths: true,
          showEmojis: true,
          useColors: true,
        ),
        // Floating logger UI configuration
        config: const FloatingLoggerConfig(
          backgroundColor: Colors.deepPurple,
          icon: Icons.developer_mode,
          showCount: true,
          enableGestures: true,
          autoSnapToEdges: true,
        ),
        child: const YourHomePage(),
      ),
    );
  }
}
```

### 4. Pass Logger to Plugin

```dart
// In your deep link initialization
import 'package:flutter_awesome_deeplink/flutter_awesome_deeplink.dart';
import 'package:your_app/service_modules/my_logger/my_logger.dart';

Future<void> _initializeDeepLinkPlugin() async {
  try {
    await FlutterAwesomeDeeplink.initialize(
      config: DeferredLinkConfig(
        appScheme: 'myapp',
        validDomains: ['myapp.com'],
        validPaths: ['/app/', '/content/'],
        enableLogging: true,
        externalLogger: logger, // 🎯 Pass your logger instance
        onDeepLink: (link) {
          // Handle deep links
          logger.i('Deep link received: $link');
          MyRouter.handleDeepLink(link);
        },
        onError: (error) {
          logger.e('Deep link error: $error');
        },
        onAttributionData: (data) {
          logger.i('Attribution data: $data');
        },
      ),
    );
    
    logger.i('FlutterAwesomeDeeplink initialized successfully');
  } catch (e) {
    logger.e('Error initializing deep link plugin', error: e);
  }
}
```

## 🎨 Production Usage

### Floating Logger Button

With this integration, you'll see a floating logger button in your app that shows:

- **🔗 Deep Link Events**: All plugin attribution and navigation events
- **📱 App Logs**: Your regular app logs
- **🌐 API Logs**: If using the Dio interceptor
- **❌ Errors**: All errors from both app and plugin

### Log Categories

The plugin logs will appear with clear prefixes:

```
🔍 FlutterAwesomeDeeplink DEBUG: Initialized for android
ℹ️ FlutterAwesomeDeeplink INFO: Android deferred links enabled: true
⚠️ FlutterAwesomeDeeplink WARNING: No deferred link found
❌ FlutterAwesomeDeeplink ERROR: Attribution timeout
```

### Shake to Toggle

Users can shake the device to show/hide the floating logger button, making it perfect for production debugging.

## 🔧 Advanced Configuration

### Custom Logger Compatibility

The plugin works with any logger that has these methods:

```dart
class YourCustomLogger {
  void d(String message) { /* debug */ }
  void i(String message) { /* info */ }
  void w(String message) { /* warning */ }
  void e(String message, {dynamic error, StackTrace? stackTrace}) { /* error */ }
}
```

### Conditional Logging

Enable logging only in specific environments:

```dart
await FlutterAwesomeDeeplink.initialize(
  config: DeferredLinkConfig(
    // ... other config
    enableLogging: kDebugMode || isTestEnvironment,
    externalLogger: kDebugMode ? logger : null,
  ),
);
```

### Logger Fallback

If the external logger fails, the plugin automatically falls back to `dart:developer` log:

```dart
// Plugin automatically handles logger failures
try {
  externalLogger.i('FlutterAwesomeDeeplink: $message');
} catch (e) {
  developer.log(message, name: 'FlutterAwesomeDeeplink', level: 800); // Fallback
}
```

## 🧪 Testing the Integration

### 1. Run Your App

```bash
flutter run
```

### 2. Look for the Floating Logger Button

You should see a floating button (usually purple with a developer icon) on your screen.

### 3. Trigger Deep Link Events

- Initialize the plugin
- Test deep links
- Check attribution flows

### 4. View Logs

Tap the floating logger button to see all logs, including plugin logs with the `FlutterAwesomeDeeplink:` prefix.

### 5. Shake to Toggle

Shake your device to show/hide the logger button.

## 📱 Production Benefits

### For Developers

- **🔍 Debug Production Issues**: See what's happening in production apps
- **📊 Monitor Attribution**: Track deep link success rates
- **🐛 Catch Errors**: Identify issues users are experiencing
- **📈 Analytics**: Understand user flows and attribution patterns

### For Users

- **🎯 Hidden by Default**: Logger is invisible unless enabled
- **🤳 Shake to Enable**: Users can enable logging if needed for support
- **🚀 No Performance Impact**: Minimal overhead when disabled

## 🔄 Migration from Print Statements

If you were using the plugin before this update:

### Before (Separate Logging)

```dart
// Plugin used internal print statements
// App used separate logger
// No unified view of logs
```

### After (Unified Logging)

```dart
// Single logger instance
// All logs in one place
// Production-ready logging UI
// Unified debugging experience
```

## 🎉 Example Implementation

Check out the complete example in:

- **Plugin Example**: `/flutter_awesome_deeplink/example/lib/main.dart`
- **Challenge App**: `/challenge_app/lib/feature_modules/my_bottom_nav_bar.dart`

## 🐛 Troubleshooting

### Logger Not Working

1. **Check Logger Instance**: Ensure you're passing the correct logger instance
2. **Verify enableLogging**: Make sure `enableLogging: true` in config
3. **Test Logger Separately**: Verify your logger works independently

### Logs Not Appearing

1. **Check FloatingLogger Setup**: Ensure `FlutterAwesomeLogger` widget wraps your app
2. **Verify Logger Methods**: Ensure your logger has `d`, `i`, `w`, `e` methods
3. **Check Fallback**: Look for print statements if logger fails

### Performance Issues

1. **Disable in Production**: Set `enableLogging: false` for release builds
2. **Limit Log Entries**: Configure `maxLogEntries` in `AwesomeLoggerConfig`
3. **Use Conditional Logging**: Only enable when needed

## 🚀 Next Steps

1. **✅ Integrate the unified logger** using the steps above
2. **✅ Test in development** to ensure logs appear correctly
3. **✅ Deploy to production** with logging enabled for debugging
4. **✅ Monitor attribution success** using the logger data
5. **✅ Use shake-to-enable** for user support scenarios

This unified logging approach gives you production-ready debugging capabilities while maintaining a clean, professional user experience! 🎯
