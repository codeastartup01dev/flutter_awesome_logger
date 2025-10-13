import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_awesome_logger/flutter_awesome_logger.dart';

void main() {
  // 🚀 No manual setup needed! Configuration is done in the widget below
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Awesome Flutter Logger Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: FlutterAwesomeLogger(
        enabled: true,

        // ✨ Auto-configure logger - no need for manual setup in main()!
        loggerConfig: const AwesomeLoggerConfig(
          enabled: true,
          storeLogs: true,
          maxLogEntries: 500,
          showFilePaths: true,
          showEmojis: true,
          useColors: true,
        ),

        // 🔄 Auto-initialize floating logger (true by default)
        autoInitialize: true,

        // 🎨 Floating logger UI configuration
        config: const FloatingLoggerConfig(
          backgroundColor: Colors.deepPurple,
          icon: Icons.developer_mode,
          showCount: true,
          enableGestures: true,
          autoSnapToEdges: true,
        ),

        child: const DemoPage(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  late Dio _dio;
  int _logCounter = 0;

  @override
  void initState() {
    super.initState();
    _setupDio();
    logger.i('DemoPage initialized with Awesome Flutter Logger!');
  }

  void _setupDio() {
    _dio = Dio();
    // Add the awesome logger interceptor
    _dio.interceptors.add(FlutterAwesomeLoggerDioInterceptor());
    logger.d('Dio configured with AwesomeLoggerInterceptor');
  }

  void _generateDifferentLogs() {
    setState(() {
      _logCounter++;
    });

    logger.d('Debug log #$_logCounter - This is a debug message');
    logger.i('Info log #$_logCounter - Application state updated');
    logger.w('Warning log #$_logCounter - This is a warning message');

    if (_logCounter % 3 == 0) {
      try {
        throw Exception('Sample error for demonstration');
      } catch (e, stackTrace) {
        logger.e(
          'Error log #$_logCounter - Something went wrong!',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<void> _makeApiCall(String endpoint) async {
    try {
      logger.i('Making API call to: $endpoint');
      final response = await _dio.get(endpoint);
      logger.i('API call successful: ${response.statusCode}');
    } catch (e) {
      logger.e('API call failed', error: e);
    }
  }

  void _openLogger() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoggerHistoryPage()),
    );
  }

  void _toggleLoggerVisibility() async {
    await FloatingLoggerManager.toggle();
    final isVisible = await FloatingLoggerManager.isVisible();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Floating logger ${isVisible ? 'shown' : 'hidden'}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Awesome Logger Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: _toggleLoggerVisibility,
            tooltip: 'Toggle Floating Logger',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _openLogger,
            tooltip: 'Open Logger History',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🚀 Awesome Flutter Logger Demo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This demo showcases the new auto-configuration approach - no manual setup needed in main()!',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text('✨ Auto-configured logger (no manual setup)'),
                    Text(
                      '🎯 Floating logger button (look for the purple button!)',
                    ),
                    Text('📊 General logging with different levels'),
                    Text('🌐 API request/response logging'),
                    Text('🎨 Beautiful UI for browsing logs'),
                    Text('💾 Persistent settings and positioning'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Demo Actions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _generateDifferentLogs,
              icon: const Icon(Icons.note_add),
              label: Text('Generate Logs ($_logCounter generated)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () =>
                  _makeApiCall('https://jsonplaceholder.typicode.com/posts/1'),
              icon: const Icon(Icons.web),
              label: const Text('Make Successful API Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _makeApiCall('https://httpstat.us/500'),
              icon: const Icon(Icons.error),
              label: const Text('Make Failing API Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () =>
                  _makeApiCall('https://nonexistent-domain-xyz.com/api'),
              icon: const Icon(Icons.cloud_off),
              label: const Text('Make Network Error Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _openLogger,
              icon: const Icon(Icons.history),
              label: const Text('Open Logger History'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _toggleLoggerVisibility,
              icon: const Icon(Icons.visibility),
              label: const Text('Toggle Floating Logger'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const Spacer(),
            const Card(
              color: Colors.blue,
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Icon(Icons.info, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      'Tap the floating purple button to access logs quickly!',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
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
}
