// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_awesome_deeplink/flutter_awesome_deeplink.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flutter Awesome Deeplink Integration Tests', () {
    testWidgets('plugin initialization test', (WidgetTester tester) async {
      // Test plugin initialization
      await FlutterAwesomeDeeplink.initialize(
        config: DeferredLinkConfig(
          appScheme: 'testapp',
          validDomains: ['test.com'],
          enableLogging: true,
        ),
      );

      expect(FlutterAwesomeDeeplink.isInitialized, true);
    });

    testWidgets('deferred link storage test', (WidgetTester tester) async {
      // Ensure plugin is initialized
      if (!FlutterAwesomeDeeplink.isInitialized) {
        await FlutterAwesomeDeeplink.initialize(
          config: DeferredLinkConfig(
            appScheme: 'testapp',
            validDomains: ['test.com'],
          ),
        );
      }

      const testLink = 'testapp://content?id=integration_test';

      // Test storing and retrieving a deferred link
      await FlutterAwesomeDeeplink.storeDeferredLink(testLink);
      final storedLink = await FlutterAwesomeDeeplink.getStoredDeferredLink();
      expect(storedLink, testLink);

      // Test clearing the stored link
      await FlutterAwesomeDeeplink.clearStoredDeferredLink();
      final clearedLink = await FlutterAwesomeDeeplink.getStoredDeferredLink();
      expect(clearedLink, null);
    });

    testWidgets('link validation test', (WidgetTester tester) async {
      // Ensure plugin is initialized
      if (!FlutterAwesomeDeeplink.isInitialized) {
        await FlutterAwesomeDeeplink.initialize(
          config: DeferredLinkConfig(
            appScheme: 'testapp',
            validDomains: ['test.com'],
            validPaths: ['/app/'],
          ),
        );
      }

      // Test valid links
      expect(
        FlutterAwesomeDeeplink.isValidDeepLink('testapp://content?id=123'),
        true,
      );
      expect(
        FlutterAwesomeDeeplink.isValidDeepLink(
          'https://test.com/app/content?id=123',
        ),
        true,
      );

      // Test invalid links
      expect(
        FlutterAwesomeDeeplink.isValidDeepLink('invalid://content'),
        false,
      );
      expect(
        FlutterAwesomeDeeplink.isValidDeepLink(
          'https://invalid.com/content?id=123',
        ),
        false,
      );
    });

    testWidgets('attribution metadata test', (WidgetTester tester) async {
      // Ensure plugin is initialized
      if (!FlutterAwesomeDeeplink.isInitialized) {
        await FlutterAwesomeDeeplink.initialize(
          config: DeferredLinkConfig(
            appScheme: 'testapp',
            validDomains: ['test.com'],
          ),
        );
      }

      final metadata = await FlutterAwesomeDeeplink.getAttributionMetadata();

      expect(metadata, isA<Map<String, dynamic>>());
      expect(metadata['isInitialized'], true);
      expect(metadata['platform'], isNotNull);
      expect(metadata['config'], isA<Map<String, dynamic>>());
      expect(metadata['config']['appScheme'], 'testapp');
    });

    testWidgets('link parameter extraction test', (WidgetTester tester) async {
      // Ensure plugin is initialized
      if (!FlutterAwesomeDeeplink.isInitialized) {
        await FlutterAwesomeDeeplink.initialize(
          config: DeferredLinkConfig(
            appScheme: 'testapp',
            validDomains: ['test.com'],
          ),
        );
      }

      const testLink = 'testapp://content?id=123&type=test&user=integration';

      final id = FlutterAwesomeDeeplink.extractLinkId(testLink);
      expect(id, '123');

      final params = FlutterAwesomeDeeplink.extractLinkParameters(testLink);
      expect(params['id'], '123');
      expect(params['type'], 'test');
      expect(params['user'], 'integration');
    });
  });
}
