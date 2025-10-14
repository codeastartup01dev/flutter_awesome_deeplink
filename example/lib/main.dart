import 'package:flutter/material.dart';
import 'package:flutter_awesome_deeplink/flutter_awesome_deeplink.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // OPTION 1: Initialize with BOTH normal and deferred deep links
  // This provides full functionality including post-install attribution
  await FlutterAwesomeDeeplink.initialize(
    // Required: Normal deep link configuration
    normalConfig: NormalDeepLinkConfig(
      appScheme: 'awesomedeeplink',
      validDomains: ['example.com', 'myapp.example.com'],
      validPaths: ['/app/', '/content/'],
      enableLogging: true, // Enable for demo
      onNormalLink: (uri) {
        // Handle normal deep links (real-time when app is installed)
        print('🔗 Normal deep link received: $uri');
        final id = uri.queryParameters['id'];
        final type = uri.queryParameters['type'] ?? 'unknown';

        // In a real app, you would navigate based on the URI:
        if (uri.path.contains('/content')) {
          print('  → Would navigate to content with ID: $id, type: $type');
          // GoRouter.of(context).push('/content/$id');
        } else if (uri.path.contains('/challenge')) {
          print('  → Would navigate to challenge with ID: $id, type: $type');
          // GoRouter.of(context).push('/challenge/$id');
        } else {
          print('  → Would handle generic deep link with ID: $id, type: $type');
        }
      },
      onError: (error) {
        print('❌ Normal deep link error: $error');
      },
    ),
    // Optional: Deferred deep link configuration (for post-install attribution)
    deferredConfig: DeferredLinkConfig(
      appScheme: 'awesomedeeplink',
      validDomains: ['example.com', 'myapp.example.com'],
      validPaths: ['/app/', '/content/'],
      enableIOSClipboard: true, // Enable for demo purposes
      maxLinkAge: Duration(days: 7),
      enableLogging: true, // Enable for demo
      onDeferredLink: (link) {
        // Handle deferred link (after app install from store)
        print('📱 Deferred link received: $link');
        // In a real app, you might do:
        // MyRouter.handleDeepLink(link);
        // or
        // GoRouter.of(context).push('/content?id=${extractId(link)}');
      },
      onError: (error) {
        print('❌ Deferred deep link error: $error');
      },
      onAttributionData: (data) {
        print('📊 Attribution data: $data');
      },
    ),
  );

  // OPTION 2: Initialize with NORMAL deep links only (simpler setup)
  // Uncomment this and comment out the above if you only need real-time deep links
  /*
  await FlutterAwesomeDeeplink.initialize(
    normalConfig: NormalDeepLinkConfig(
      appScheme: 'awesomedeeplink',
      validDomains: ['example.com', 'myapp.example.com'],
      validPaths: ['/app/', '/content/'],
      enableLogging: true,
      onNormalLink: (uri) {
        print('🔗 Normal deep link received: $uri');
        // Handle navigation here
      },
      onError: (error) {
        print('❌ Deep link error: $error');
      },
    ),
    // No deferredConfig = no post-install attribution
  );
  */

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Awesome Deeplink Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MyHomePage(title: 'Flutter Awesome Deeplink Demo'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _status = 'Ready';
  String? _storedLink;
  Map<String, dynamic>? _attributionMetadata;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _refreshStoredLink();
    await _refreshAttributionMetadata();
  }

  Future<void> _refreshStoredLink() async {
    try {
      final link = await FlutterAwesomeDeeplink.getStoredDeferredLink();
      setState(() {
        _storedLink = link;
      });
    } catch (e) {
      setState(() {
        _status = 'Error getting stored link: $e';
      });
    }
  }

  Future<void> _refreshAttributionMetadata() async {
    try {
      final metadata = await FlutterAwesomeDeeplink.getAttributionMetadata();
      setState(() {
        _attributionMetadata = metadata;
      });
    } catch (e) {
      setState(() {
        _status = 'Error getting metadata: $e';
      });
    }
  }

  Future<void> _storeTestLink(String link) async {
    setState(() {
      _isLoading = true;
      _status = 'Storing test link...';
    });

    try {
      await FlutterAwesomeDeeplink.storeDeferredLink(link);
      await _refreshStoredLink();
      setState(() {
        _status = 'Test link stored successfully!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error storing link: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearStoredLink() async {
    setState(() {
      _isLoading = true;
      _status = 'Clearing stored link...';
    });

    try {
      await FlutterAwesomeDeeplink.clearStoredDeferredLink();
      await _refreshStoredLink();
      setState(() {
        _status = 'Stored link cleared successfully!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error clearing link: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetFirstLaunch() async {
    setState(() {
      _isLoading = true;
      _status = 'Resetting first launch flag...';
    });

    try {
      await FlutterAwesomeDeeplink.resetFirstLaunchFlag();
      await _refreshAttributionMetadata();
      setState(() {
        _status = 'First launch flag reset - you can test attribution again!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error resetting first launch: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cleanupExpiredLinks() async {
    setState(() {
      _isLoading = true;
      _status = 'Cleaning up expired links...';
    });

    try {
      final cleaned = await FlutterAwesomeDeeplink.cleanupExpiredLinks();
      await _refreshStoredLink();
      setState(() {
        _status = cleaned
            ? 'Expired links cleaned up successfully!'
            : 'No expired links found to clean up.';
      });
    } catch (e) {
      setState(() {
        _status = 'Error during cleanup: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _validateTestLink(String link) {
    final isValid = FlutterAwesomeDeeplink.isValidDeepLink(link);
    final id = FlutterAwesomeDeeplink.extractLinkId(link);
    final params = FlutterAwesomeDeeplink.extractLinkParameters(link);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isValid ? '✅ Valid Link' : '❌ Invalid Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Link: $link'),
            const SizedBox(height: 8),
            Text('Valid: $isValid'),
            if (id != null) Text('ID: $id'),
            if (params.isNotEmpty) Text('Parameters: $params'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(_status),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Test Links Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Test Deferred Links',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),

                          // Custom scheme test
                          ElevatedButton(
                            onPressed: () => _storeTestLink(
                              'awesomedeeplink://content?id=test123',
                            ),
                            child: const Text('Store Custom Scheme Link'),
                          ),
                          const SizedBox(height: 8),

                          // Web link test
                          ElevatedButton(
                            onPressed: () => _storeTestLink(
                              'https://example.com/app/content?id=web456',
                            ),
                            child: const Text('Store Web Link'),
                          ),
                          const SizedBox(height: 8),

                          // Invalid link test
                          ElevatedButton(
                            onPressed: () =>
                                _storeTestLink('https://invalid.com/bad?no=id'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Try Invalid Link'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Link Validation Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Link Validation',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),

                          ElevatedButton(
                            onPressed: () => _validateTestLink(
                              'awesomedeeplink://content?id=test123',
                            ),
                            child: const Text('Validate Custom Scheme'),
                          ),
                          const SizedBox(height: 8),

                          ElevatedButton(
                            onPressed: () => _validateTestLink(
                              'https://example.com/app/content?id=web456',
                            ),
                            child: const Text('Validate Web Link'),
                          ),
                          const SizedBox(height: 8),

                          ElevatedButton(
                            onPressed: () =>
                                _validateTestLink('https://invalid.com/bad'),
                            child: const Text('Validate Invalid Link'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stored Link Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Currently Stored Link',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              _storedLink ?? 'No stored link',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: _storedLink != null
                                    ? Colors.black
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _refreshStoredLink,
                                  child: const Text('Refresh'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _storedLink != null
                                      ? _clearStoredLink
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Clear'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Attribution Metadata Section
                  if (_attributionMetadata != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attribution Metadata',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                _formatMetadata(_attributionMetadata!),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _refreshAttributionMetadata,
                              child: const Text('Refresh Metadata'),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Normal Deep Link Testing Section
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Normal Deep Link Testing',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Test real-time deep links (when app is already installed):',
                            style: TextStyle(color: Colors.blue.shade700),
                          ),
                          const SizedBox(height: 12),

                          // Test buttons for different deep link types
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _testNormalDeepLink(
                                    'awesomedeeplink://content?id=test123&type=demo',
                                  ),
                                  icon: const Icon(Icons.link),
                                  label: const Text('Test Custom Scheme Link'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _testNormalDeepLink(
                                    'https://example.com/app/challenge?id=456&type=challenge',
                                  ),
                                  icon: const Icon(Icons.web),
                                  label: const Text('Test Web Deep Link'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _clearLastProcessedLink(),
                                  icon: const Icon(Icons.clear),
                                  label: const Text(
                                    'Clear Duplicate Prevention',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Note: Normal deep links are handled in real-time via the onNormalLink callback. '
                              'Check the console for output when testing these links.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Testing Tools Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Testing Tools',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),

                          ElevatedButton(
                            onPressed: _resetFirstLaunch,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Reset First Launch Flag'),
                          ),
                          const SizedBox(height: 8),

                          ElevatedButton(
                            onPressed: _cleanupExpiredLinks,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Cleanup Expired Links'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Instructions Card
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How to Test Deferred Links',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '1. Store a test deferred link using the buttons above\n'
                            '2. Use "Reset First Launch Flag" to simulate a fresh install\n'
                            '3. Restart the app to trigger deferred link processing\n'
                            '4. Check the console for attribution logs\n\n'
                            'For iOS clipboard testing:\n'
                            '• Copy a valid deep link before opening the app\n'
                            '• The plugin will detect it on first launch\n\n'
                            'For Android testing:\n'
                            '• Install via Play Store with referrer parameters\n'
                            '• The plugin will extract links from Install Referrer API',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Test normal deep link handling by simulating a deep link
  void _testNormalDeepLink(String testLink) {
    try {
      final uri = Uri.parse(testLink);

      // Show a snackbar to indicate the test
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Testing normal deep link: $testLink'),
          backgroundColor: Colors.blue,
        ),
      );

      // The actual deep link would be handled by the app_links package
      // For testing purposes, we'll just validate the link
      final isValid = FlutterAwesomeDeeplink.isValidDeepLink(testLink);

      print('🧪 Testing normal deep link: $testLink');
      print('   Valid: $isValid');

      if (isValid) {
        final id = uri.queryParameters['id'];
        final type = uri.queryParameters['type'];
        print('   Extracted ID: $id, Type: $type');

        // In a real scenario, this would trigger the onNormalLink callback
        // which we set up in main() - but since this is a manual test,
        // we just log the information

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Valid deep link! ID: $id, Type: $type'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Invalid deep link format'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error testing normal deep link: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Clear the last processed link to test duplicate prevention
  void _clearLastProcessedLink() {
    try {
      FlutterAwesomeDeeplink.clearLastProcessedLink();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Cleared duplicate prevention cache'),
          backgroundColor: Colors.orange,
        ),
      );

      print('🧹 Cleared last processed link cache');
    } catch (e) {
      print('❌ Error clearing last processed link: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatMetadata(Map<String, dynamic> metadata) {
    final buffer = StringBuffer();

    void addEntry(String key, dynamic value, [int indent = 0]) {
      final prefix = '  ' * indent;
      if (value is Map) {
        buffer.writeln('$prefix$key:');
        value.forEach((k, v) => addEntry(k.toString(), v, indent + 1));
      } else if (value is List) {
        buffer.writeln('$prefix$key: [${value.join(', ')}]');
      } else {
        buffer.writeln('$prefix$key: $value');
      }
    }

    metadata.forEach((key, value) => addEntry(key, value));
    return buffer.toString().trim();
  }
}
