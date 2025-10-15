import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_awesome_deeplink/flutter_awesome_deeplink.dart';

void main() {
  group('FlutterAwesomeDeeplink', () {
    test('should not be initialized before calling initialize()', () {
      expect(FlutterAwesomeDeeplink.isInitialized, false);
    });

    test(
      'should throw StateError when accessing instance before initialization',
      () {
        expect(
          () => FlutterAwesomeDeeplink.instance,
          throwsA(isA<StateError>()),
        );
      },
    );

    test('should validate deep links correctly', () async {
      // Initialize with test configuration
      await FlutterAwesomeDeeplink.initialize(
        config: DeferredLinkConfig(
          appScheme: 'testapp',
          validDomains: ['test.com'],
          validPaths: ['/app/'],
        ),
      );

      expect(FlutterAwesomeDeeplink.isInitialized, true);

      // Test valid custom scheme
      expect(
        FlutterAwesomeDeeplink.isValidDeepLink('testapp://content?id=123'),
        true,
      );

      // Test valid web link
      expect(
        FlutterAwesomeDeeplink.isValidDeepLink(
          'https://test.com/app/content?id=123',
        ),
        true,
      );

      // Test invalid link (no ID)
      expect(
        FlutterAwesomeDeeplink.isValidDeepLink('testapp://content'),
        false,
      );

      // Test invalid domain
      expect(
        FlutterAwesomeDeeplink.isValidDeepLink(
          'https://invalid.com/app/content?id=123',
        ),
        false,
      );
    });

    test('should extract link parameters correctly', () async {
      await FlutterAwesomeDeeplink.initialize(
        config: DeferredLinkConfig(
          appScheme: 'testapp',
          validDomains: ['test.com'],
        ),
      );

      const testLink = 'testapp://content?id=123&type=challenge&user=test';

      final id = FlutterAwesomeDeeplink.extractLinkId(testLink);
      expect(id, '123');

      final params = FlutterAwesomeDeeplink.extractLinkParameters(testLink);
      expect(params['id'], '123');
      expect(params['type'], 'challenge');
      expect(params['user'], 'test');
    });

    test('should handle deferred link storage', () async {
      await FlutterAwesomeDeeplink.initialize(
        config: DeferredLinkConfig(
          appScheme: 'testapp',
          validDomains: ['test.com'],
        ),
      );

      const testLink = 'testapp://content?id=123';

      // Initially no stored link
      final initialLink = await FlutterAwesomeDeeplink.getStoredDeferredLink();
      expect(initialLink, null);

      // Store a link
      await FlutterAwesomeDeeplink.storeDeferredLink(testLink);

      // Retrieve the stored link
      final storedLink = await FlutterAwesomeDeeplink.getStoredDeferredLink();
      expect(storedLink, testLink);

      // Clear the stored link
      await FlutterAwesomeDeeplink.clearStoredDeferredLink();

      // Verify it's cleared
      final clearedLink = await FlutterAwesomeDeeplink.getStoredDeferredLink();
      expect(clearedLink, null);
    });

    test('should provide attribution metadata', () async {
      await FlutterAwesomeDeeplink.initialize(
        config: DeferredLinkConfig(
          appScheme: 'testapp',
          validDomains: ['test.com'],
        ),
      );

      final metadata = await FlutterAwesomeDeeplink.getAttributionMetadata();

      expect(metadata, isA<Map<String, dynamic>>());
      expect(metadata['isInitialized'], true);
      expect(metadata['platform'], isNotNull);
      expect(metadata['config'], isA<Map<String, dynamic>>());
    });
  });

  group('DeferredLinkConfig', () {
    test('should create config with required parameters', () {
      final config = DeferredLinkConfig(
        appScheme: 'testapp',
        validDomains: ['test.com'],
      );

      expect(config.appScheme, 'testapp');
      expect(config.validDomains, ['test.com']);
      expect(config.validPaths, ['/']);
      expect(config.enableDeferredLinkForIOS, false); // Default should be false
      expect(config.maxLinkAge, const Duration(days: 7));
      expect(config.enableLogging, false);
    });

    test('should create config with custom parameters', () {
      final config = DeferredLinkConfig(
        appScheme: 'testapp',
        validDomains: ['test.com', 'app.test.com'],
        validPaths: ['/app/', '/content/'],
        enableDeferredLinkForIOS: true,
        maxLinkAge: const Duration(days: 14),
        enableLogging: true,
        storageKeyPrefix: 'custom_prefix_',
      );

      expect(config.appScheme, 'testapp');
      expect(config.validDomains, ['test.com', 'app.test.com']);
      expect(config.validPaths, ['/app/', '/content/']);
      expect(config.enableDeferredLinkForIOS, true);
      expect(config.maxLinkAge, const Duration(days: 14));
      expect(config.enableLogging, true);
      expect(config.storageKeyPrefix, 'custom_prefix_');
    });

    test('should support copyWith', () {
      final original = DeferredLinkConfig(
        appScheme: 'testapp',
        validDomains: ['test.com'],
      );

      final updated = original.copyWith(
        enableDeferredLinkForIOS: true,
        enableLogging: true,
      );

      expect(updated.appScheme, 'testapp'); // Unchanged
      expect(updated.validDomains, ['test.com']); // Unchanged
      expect(updated.enableDeferredLinkForIOS, true); // Changed
      expect(updated.enableLogging, true); // Changed
    });
  });

  group('AttributionResult', () {
    test('should create success result', () {
      final result = AttributionResult.success(
        link: 'testapp://content?id=123',
        source: 'test_source',
        platform: 'test_platform',
        processingTime: const Duration(milliseconds: 100),
      );

      expect(result.success, true);
      expect(result.link, 'testapp://content?id=123');
      expect(result.source, 'test_source');
      expect(result.platform, 'test_platform');
      expect(result.processingTime, const Duration(milliseconds: 100));
      expect(result.error, null);
    });

    test('should create failure result', () {
      final result = AttributionResult.failure(
        source: 'test_source',
        platform: 'test_platform',
        processingTime: const Duration(milliseconds: 50),
        error: 'Test error',
      );

      expect(result.success, false);
      expect(result.link, null);
      expect(result.source, 'test_source');
      expect(result.platform, 'test_platform');
      expect(result.processingTime, const Duration(milliseconds: 50));
      expect(result.error, 'Test error');
    });

    test('should convert to map correctly', () {
      final result = AttributionResult.success(
        link: 'testapp://content?id=123',
        source: 'test_source',
        platform: 'test_platform',
        processingTime: const Duration(milliseconds: 100),
        metadata: {'key': 'value'},
      );

      final map = result.toMap();

      expect(map['success'], true);
      expect(map['link'], 'testapp://content?id=123');
      expect(map['source'], 'test_source');
      expect(map['platform'], 'test_platform');
      expect(map['processingTimeMs'], 100);
      expect(map['metadata'], {'key': 'value'});
      expect(map['error'], null);
    });
  });
}
