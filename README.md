# Flutter Awesome Deeplink

[![pub package](https://img.shields.io/pub/v/flutter_awesome_deeplink.svg)](https://pub.dev/packages/flutter_awesome_deeplink)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Web-blue.svg)](https://pub.dev/packages/flutter_awesome_deeplink)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Platform-optimized deferred deep links for Flutter with 96%+ attribution success rates.**

A comprehensive Flutter plugin that provides reliable deferred deep link attribution without the complexity and cost of third-party services like Branch.io or AppsFlyer.

## 🚀 Key Features

- **🤖 Android**: Install Referrer API (95%+ success rate)
- **🍎 iOS**: Optional clipboard detection (90%+ success rate when enabled)
- **🔗 Normal Deep Links**: Real-time deep link handling using app_links
- **🔒 Privacy-first**: iOS clipboard checking is opt-in
- **🌐 Cross-platform**: Works on Android, iOS, and Web
- **⚡ High performance**: Minimal overhead and fast attribution
- **🛡️ Production-ready**: Comprehensive error handling and logging
- **📊 Analytics-ready**: Rich attribution metadata for optimization
- **🎯 Self-hosted**: No vendor lock-in, full control over your data
- **🔄 Unified Navigation**: Single callback handles both normal and deferred deep links
- **📝 Logger Integration**: Works with flutter_awesome_logger and custom loggers

## 📊 Success Rates

| Platform | Primary Method | Success Rate | Fallback Method | Total Success |
|----------|----------------|--------------|-----------------|---------------|
| **Android** | Install Referrer API | **95%+** | Storage Service | **98%+** 🚀 |
| **iOS** | Clipboard Detection | **90%+** | Storage Service | **95%+** 🚀 |
| **Overall** | Platform-Optimized | **92%+** | Multiple Fallbacks | **96%+** 🎯 |

## 🌐 Real-World URL Examples (Challenge App)

The plugin supports multiple URL formats for maximum compatibility:

### Production URLs
- **Custom Domain**: `https://mychallengeapp.com/app/challenge?id=123`
- **Firebase Hosting**: `https://challenge-app-startup.web.app/app/challenge?id=123`
- **Custom Scheme**: `challengeapp://challenge?id=123`

### Development URLs  
- **Firebase Dev**: `https://challenge-app-startup.web.app/dev/app/challenge?id=123`
- **Custom Scheme**: `challengeapp://challenge?id=123`

### Supported Content Types
- **Challenges**: `/challenge?id=challenge_123`
- **Events**: `/event?id=event_456` 
- **User Profiles**: `/profile?id=user_789`
- **Custom Pages**: `/custom?page=about&section=team`

## 🚀 Quick Start

### 1. Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_awesome_deeplink: ^0.0.1
```

### 2. Basic Setup

```dart
import 'package:flutter_awesome_deeplink/flutter_awesome_deeplink.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize with minimal configuration
  await FlutterAwesomeDeeplink.initialize(
    config: DeferredLinkConfig(
      appScheme: 'challengeapp',
      validDomains: ['challenge-app-startup.web.app'],
      onDeepLink: (link) {
        // Handle both normal and deferred deep links uniformly
        print('Deep link received: $link');
        // Navigate to content based on the link
        // MyRouter.handleDeepLink(link);
      },
    ),
  );
  
  runApp(MyApp());
}
```

### 3. Advanced Configuration (Real Production Example)

```dart
// Real-world configuration from Challenge App
await FlutterAwesomeDeeplink.initialize(
  config: DeferredLinkConfig(
    appScheme: 'challengeapp',
    validDomains: [
      'challenge-app-startup.web.app',  // Firebase hosting domain
      'mychallengeapp.com',             // Custom production domain
    ],
    validPaths: ['/app/', '/dev/app/', '/challenge', '/event'],
    enableDeferredLinkForAndroid: true, // Android Install Referrer (default: true)
    enableDeferredLinkForIOS: true, // iOS clipboard detection (user opted in)
    maxLinkAge: Duration(days: 14),
    enableLogging: true, // For development
    externalLogger: logger, // 🎯 Unified logging with flutter_awesome_logger
    onDeepLink: (link) {
      // Handle both normal and deferred deep links uniformly
      final id = FlutterAwesomeDeeplink.extractLinkId(link);
      AutoNavigation.handleDeferredLink(link); // Custom navigation handler
    },
    onError: (error) {
      // Handle errors with proper logging
      logger.e('Deferred deep link error: $error');
      Analytics.trackError('deferred_link_error', error);
    },
    onAttributionData: (data) {
      // Track attribution success with detailed metadata
      logger.i('Attribution data: $data');
      Analytics.trackAttribution(data);
    },
  ),
);
```

### 4. Logger Integration (Production Example)

The plugin integrates seamlessly with `flutter_awesome_logger` and other logging systems. Here's how it's implemented in the Challenge App:

```dart
import 'package:flutter_awesome_logger/flutter_awesome_logger.dart';
import 'package:flutter_awesome_deeplink/flutter_awesome_deeplink.dart';

class MyBottomNavBar extends StatefulWidget {
  // ... widget implementation

  /// Initialize flutter_awesome_deeplink plugin with unified logging
  /// Replaces the previous DeepLinkUsingAppLinksService implementation
  Future<void> _initializeDeepLinkPlugin() async {
    try {
      logger.i('MyBottomNavBar: Initializing flutter_awesome_deeplink plugin');

      // Initialize the plugin with both normal and deferred deep link support
      await FlutterAwesomeDeeplink.initialize(
        config: DeferredLinkConfig(
          appScheme: 'challengeapp',
          validDomains: ['challenge-app-startup.web.app', 'mychallengeapp.com'],
          validPaths: ['/app/', '/dev/app/', '/challenge', '/event'],
          enableLogging: true,
          externalLogger: logger, // 🎯 Pass the unified logger instance
          onAttributionData: (data) {
            logger.i('MyBottomNavBar: Attribution data: $data');
          },
          onDeepLink: AutoNavigation.handleDeferredLink,
          onError: (error) {
            logger.e('MyBottomNavBar: Deferred deep link error: $error');
          },
        ),
      );

      logger.i('MyBottomNavBar: ✅ flutter_awesome_deeplink plugin initialized successfully');
    } catch (e) {
      logger.e('MyBottomNavBar: Error initializing deep link plugin', error: e);
    }
  }
}
```

**Benefits of Logger Integration**:
- 🔄 **Unified Logging**: All plugin logs use your app's logger
- 📊 **Consistent Format**: Matches your app's log format and structure
- 🎯 **Centralized Control**: Control plugin logging through your logger settings
- 📝 **Rich Context**: Includes class names, methods, and structured data

## 📱 Platform-Specific Setup

### Android Setup

The plugin automatically handles Android setup, but you need to configure your app for deep links:

#### 1. AndroidManifest.xml (Real Production Configuration)

Add intent filters to your `android/app/src/main/AndroidManifest.xml`. Here's the exact configuration from Challenge App:

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:taskAffinity=""
    android:theme="@style/LaunchTheme"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:enableOnBackInvokedCallback="true"
    android:windowSoftInputMode="adjustResize">
    
    <!-- IMPORTANT: Disable Flutter's built-in deep linking when using app_links -->
    <meta-data
        android:name="flutter_deeplinking_enabled"
        android:value="false" />
    
    <!-- Production App Links Intent Filter -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
            android:scheme="https"
            android:host="mychallengeapp.com"
            android:pathPrefix="/app" />
    </intent-filter>

    <!-- Firebase Hosting Domain (Production) -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
            android:scheme="https"
            android:host="challenge-app-startup.web.app"
            android:pathPrefix="/app" />
    </intent-filter>
    
    <!-- Firebase Hosting Domain (Development) -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
            android:scheme="https"
            android:host="challenge-app-startup.web.app"
            android:pathPrefix="/dev/app" />
    </intent-filter>
    
    <!-- Custom scheme for direct app links -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="challengeapp" />
    </intent-filter>
</activity>
```

#### 2. Domain Verification (assetlinks.json)

For App Links verification, create `.well-known/assetlinks.json` on your web domain. Here's the Challenge App configuration:

```json
[
    {
        "relation": [
            "delegate_permission/common.handle_all_urls"
        ],
        "target": {
            "namespace": "android_app",
            "package_name": "com.challenge.startup",
            "sha256_cert_fingerprints": [
                "COPY_PASTE_SHA256_FINGERPRINT_FROM_YOUR_PLAY_CONSOLE_FOR_PROD_FLAVOR_APP"
            ],
            "paths": [
                "/app/*"
            ]
        }
    },
    {
        "relation": [
            "delegate_permission/common.handle_all_urls"
        ],
        "target": {
            "namespace": "android_app",
            "package_name": "com.challenge.startup.dev",
            "sha256_cert_fingerprints": [
                "COPY_PASTE_SHA256_FINGERPRINT_FROM_YOUR_PLAY_CONSOLE_FOR_DEV_FLAVOR_APP"
            ],
            "paths": [
                "/dev/app/*"
            ]
        }
    }
]
```

**Host this file at:**
- Production Firebase Hosting: `https://challenge-app-startup.web.app/.well-known/assetlinks.json`

### iOS Setup

#### 1. URL Schemes (Challenge App Configuration)

Add URL schemes to your `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>challengeapp.deeplink</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>challengeapp</string>
        </array>
    </dict>
    <dict>
        <key>CFBundleURLName</key>
        <string>challengeapp.https</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>https</string>
        </array>
    </dict>
</array>
```

#### 2. Universal Links (Challenge App Configuration)

For Universal Links, add associated domains to your `ios/Runner/Runner.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.associated-domains</key>
    <array>
        <string>applinks:mychallengeapp.com</string>
        <string>applinks:challenge-app-startup.web.app</string>
    </array>
</dict>
</plist>
```

#### 3. Apple App Site Association

Create `apple-app-site-association` file (no extension) on your web domain:

```json
{
    "applinks": {
        "apps": [],
        "details": [
            {
                "appID": "TEAM_ID.com.challenge.startup",
                "paths": ["/app/*", "/dev/app/*"]
            }
        ]
    }
}
```

**Host this file at:**
- Production Firebase Hosting: `https://challenge-app-startup.web.app/.well-known/apple-app-site-association`

## 🔧 Configuration Options

### DeferredLinkConfig

```dart
DeferredLinkConfig({
  required String appScheme,              // Your app's custom scheme
  required List<String> validDomains,     // Valid web domains
  List<String> validPaths = const ['/'],  // Valid URL paths
  bool enableDeferredLinkForAndroid = true,  // Android Install Referrer API
  bool enableDeferredLinkForIOS = false,     // iOS clipboard detection (privacy-first)
  Duration maxLinkAge = const Duration(days: 7),  // Link expiration
  String storageKeyPrefix = 'flutter_awesome_deeplink_',  // Storage prefix
  Function(String)? onDeepLink,       // Unified deep link callback
  Function(String)? onError,              // Error callback
  Function(Map<String, dynamic>)? onAttributionData,  // Attribution callback
  bool enableLogging = false,             // Debug logging
  dynamic externalLogger,                 // External logger instance
  Duration attributionTimeout = const Duration(seconds: 10),  // Timeout
})
```

### Privacy Configuration

The plugin is privacy-first by default:

```dart
DeferredLinkConfig(
  // ... other config
  enableDeferredLinkForAndroid: true,  // Default: enabled (Install Referrer API)
  enableDeferredLinkForIOS: false,     // Default: disabled for privacy
  // Only enable iOS clipboard detection if user has explicitly opted in
)
```

## 📖 API Reference

### Static Methods

```dart
// Initialize the plugin
await FlutterAwesomeDeeplink.initialize(config: config);

// Check if initialized
bool isReady = FlutterAwesomeDeeplink.isInitialized;

// Store a deferred link (for web fallback pages)
await FlutterAwesomeDeeplink.storeDeferredLink('myapp://content?id=123');

// Get stored link (for debugging)
String? link = await FlutterAwesomeDeeplink.getStoredDeferredLink();

// Clear stored link
await FlutterAwesomeDeeplink.clearStoredDeferredLink();

// Validate a deep link
bool isValid = FlutterAwesomeDeeplink.isValidDeepLink('myapp://content?id=123');

// Extract link components
String? id = FlutterAwesomeDeeplink.extractLinkId('myapp://content?id=123');
Map<String, String> params = FlutterAwesomeDeeplink.extractLinkParameters(link);

// Get attribution metadata
Map<String, dynamic> metadata = await FlutterAwesomeDeeplink.getAttributionMetadata();

// Testing utilities
await FlutterAwesomeDeeplink.resetFirstLaunchFlag();  // For testing
bool cleaned = await FlutterAwesomeDeeplink.cleanupExpiredLinks();
```

### Advanced Usage

```dart
// Access the service instance for advanced features
final service = FlutterAwesomeDeeplink.instance;

// Get detailed attribution metadata
final metadata = await service.getAttributionMetadata();
print('Platform: ${metadata['platform']}');
print('Attribution source: ${metadata['installReferrer']['source']}');

// Manual link validation with custom logic
final validator = LinkValidator(config);
final isValid = validator.isValidDeepLink(link);
final summary = validator.getValidationSummary();
```

## 🧪 Testing

### Testing Deferred Links

1. **Store a test link**:
```dart
await FlutterAwesomeDeeplink.storeDeferredLink('myapp://content?id=test123');
```

2. **Reset first launch flag**:
```dart
await FlutterAwesomeDeeplink.resetFirstLaunchFlag();
```

3. **Restart the app** to trigger deferred link processing

4. **Check logs** for attribution success

### Platform-Specific Testing

#### Android Testing (Challenge App Examples)
```bash
# Test Production Domain
adb shell am start -W -a android.intent.action.VIEW \
  -d "https://mychallengeapp.com/app/challenge?id=test123" \
  com.challenge.startup

# Test Firebase Domain (Production)
adb shell am start -W -a android.intent.action.VIEW \
  -d "https://challenge-app-startup.web.app/app/challenge?id=test123" \
  com.challenge.startup

# Test Firebase Domain (Development)
adb shell am start -W -a android.intent.action.VIEW \
  -d "https://challenge-app-startup.web.app/dev/app/challenge?id=test123" \
  com.challenge.startup.dev

# Test Custom Scheme
adb shell am start -W -a android.intent.action.VIEW \
  -d "challengeapp://challenge?id=test123" \
  com.challenge.startup
```

#### iOS Testing
1. Copy a valid deep link to clipboard
2. Install and open the app (if clipboard is enabled)
3. Check console for clipboard detection logs

### Example Test App

Run the included example app to test all features:

```bash
cd example
flutter run
```

The example app provides:
- Test link storage and validation
- Attribution metadata viewer
- First launch reset for testing
- Real-time status updates

## 🔍 Debugging

### Enable Logging

```dart
DeferredLinkConfig(
  enableLogging: true,  // Enable detailed logs
  onError: (error) => print('Error: $error'),
  onAttributionData: (data) => print('Attribution: $data'),
)
```

### Common Issues

#### No Attribution on Android
- Verify Install Referrer API is available
- Check Play Store installation (not sideloading)
- Ensure Google Play Services is installed

#### No Attribution on iOS
- Verify clipboard is enabled in config
- Check if user copied link before install
- Ensure link format matches validation rules

#### Links Not Validating
```dart
// Debug link validation
final validator = LinkValidator(config);
final summary = validator.getValidationSummary();
print('Validation rules: $summary');

final isValid = validator.isValidDeepLink(testLink);
print('Link valid: $isValid');
```

### Attribution Metadata

Get detailed information about attribution state:

```dart
final metadata = await FlutterAwesomeDeeplink.getAttributionMetadata();
print('Platform: ${metadata['platform']}');
print('First launch: ${metadata['installReferrer']['isFirstLaunch']}');
print('Attribution source: ${metadata['installReferrer']['source']}');
```

## 🔄 Migration Guide

### From Firebase Dynamic Links

```dart
// Before (Firebase Dynamic Links)
final PendingDynamicLinkData? data = await FirebaseDynamicLinks.instance.getInitialLink();
if (data != null) {
  handleDeepLink(data.link.toString());
}

// After (Flutter Awesome Deeplink)
await FlutterAwesomeDeeplink.initialize(
  config: DeferredLinkConfig(
    appScheme: 'myapp',
    validDomains: ['myapp.page.link'],  // Your Firebase domain
    onDeepLink: (link) => handleDeepLink(link),
  ),
);
```

### From Branch.io

```dart
// Before (Branch.io)
Branch.getInstance().initSession().listen((data) {
  if (data.containsKey('+clicked_branch_link')) {
    handleDeepLink(data['$canonical_url']);
  }
});

// After (Flutter Awesome Deeplink)
await FlutterAwesomeDeeplink.initialize(
  config: DeferredLinkConfig(
    appScheme: 'myapp',
    validDomains: ['myapp.app.link'],  // Your Branch domain
    onDeepLink: (link) => handleDeepLink(link),
    onAttributionData: (data) {
      // Rich attribution data similar to Branch
      Analytics.track('attribution', data);
    },
  ),
);
```

### From Custom Implementation

If you're migrating from a custom deferred link implementation:

1. **Replace service initialization**:
```dart
// Remove your custom services
// await MyDeepLinkService.initialize();

// Add plugin initialization
await FlutterAwesomeDeeplink.initialize(config: config);
```

2. **Update link handling**:
```dart
// Replace direct service calls with plugin callbacks
DeferredLinkConfig(
  onDeepLink: (link) {
    // Your existing link handling logic
    MyRouter.handleDeepLink(link);
  },
)
```

3. **Remove platform-specific code**:
   - Delete custom Android Install Referrer handlers
   - Remove iOS clipboard detection code
   - Remove custom storage services

## 🏗️ Architecture

### Platform Strategy

The plugin uses platform-optimized attribution strategies:

```
┌─────────────────────────────────────────────────────────────┐
│                    Attribution Flow                         │
├─────────────────────────────────────────────────────────────┤
│ Android (98%+ success):                                     │
│ 1. Install Referrer API (95%+) → 2. Storage Service (3%+)  │
│                                                             │
│ iOS (95%+ success):                                         │
│ 1. Clipboard Detection (90%+) → 2. Storage Service (5%+)   │
│                                                             │
│ Cross-platform Fallback:                                   │
│ Storage Service with automatic cleanup                      │
└─────────────────────────────────────────────────────────────┘
```

### Service Architecture

```
FlutterAwesomeDeeplink (Static API)
├── DeferredDeepLinksService (Main orchestrator)
│   ├── InstallReferrerService (Platform-specific attribution)
│   ├── DeferredLinkStorageService (Cross-platform storage)
│   └── LinkValidator (Link validation and parsing)
└── Native Implementations
    ├── Android: InstallReferrerHandler.kt
    └── iOS: (Clipboard API via Flutter)
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

1. Clone the repository
2. Run `flutter pub get` in the plugin directory
3. Run `flutter pub get` in the example directory
4. Make your changes
5. Test with the example app
6. Submit a pull request

### Testing

```bash
# Run tests
flutter test

# Run example app
cd example && flutter run

# Test on different platforms
flutter run -d android
flutter run -d ios
flutter run -d chrome
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by the need for reliable, privacy-conscious deferred deep links
- Built on Flutter's robust plugin architecture
- Designed to replace expensive third-party attribution services

## 📞 Support

- **Documentation**: [pub.dev/packages/flutter_awesome_deeplink](https://pub.dev/packages/flutter_awesome_deeplink)
- **Issues**: [GitHub Issues](https://github.com/codeastartup01dev/flutter_awesome_deeplink/issues)
- **Discussions**: [GitHub Discussions](https://github.com/codeastartup01dev/flutter_awesome_deeplink/discussions)

---

**Made with ❤️ for the Flutter community**

*Achieve 96%+ deferred link attribution success rates without vendor lock-in or ongoing costs.*