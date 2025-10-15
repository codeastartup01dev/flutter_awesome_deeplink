import 'package:flutter/material.dart';
import 'package:flutter_awesome_deeplink/flutter_awesome_deeplink.dart';

// Example: Create a simple logger for demonstration
// In a real app, you would use flutter_awesome_logger or your preferred logging solution
class ExampleLogger {
  void d(String message) => print('🔍 DEBUG: $message');
  void i(String message) => print('ℹ️ INFO: $message');
  void w(String message) => print('⚠️ WARNING: $message');
  void e(String message, {dynamic error, StackTrace? stackTrace}) {
    print('❌ ERROR: $message');
    if (error != null) print('Error details: $error');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create logger instance (in real app, use flutter_awesome_logger)
  final logger = ExampleLogger();

  // Initialize the deferred deep links plugin with unified logger
  await FlutterAwesomeDeeplink.initialize(
    config: DeferredLinkConfig(
      appScheme: 'awesomedeeplink',
      validDomains: ['example.com', 'myapp.example.com'],
      validPaths: ['/app/', '/content/'],
      enableDeferredLinkForIOS: true, // Enable for demo purposes
      maxLinkAge: Duration(days: 7),
      enableLogging: true, // Enable for demo
      externalLogger:
          logger, // 🎯 Pass your logger instance for unified logging
      onDeepLink: (link) {
        // Handle deferred link - this would typically navigate to content
        logger.i('Deferred link received: $link');
        // In a real app, you might do:
        // MyRouter.handleDeepLink(link);
        // or
        // GoRouter.of(context).push('/content?id=${extractId(link)}');
      },
      onError: (error) {
        logger.e('Deferred link error: $error');
      },
      onAttributionData: (data) {
        logger.i('Attribution data: $data');
      },
    ),
  );

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
