import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_awesome_logger/flutter_awesome_logger.dart';

import '../cubit/user_cubit.dart';
import 'cubit_demo_page.dart';

/// Global logger instance
final logger = FlutterAwesomeLogger.loggingUsingLogger;

/// Main demo page showing various logger features
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
    logger.i('DemoPage initialized - Logger will be enabled in 3 seconds!');
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
      MaterialPageRoute(builder: (context) => const AwesomeLoggerHistoryPage()),
    );
  }

  void _toggleLoggerVisibility() {
    FlutterAwesomeLogger.toggleVisibility();
    final isVisible = FlutterAwesomeLogger.isVisible();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Floating logger ${isVisible ? 'shown' : 'hidden'}'),
        ),
      );
    }
  }

  void _openCubitDemo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => UserCubit(_dio),
          child: const CubitDemoPage(),
        ),
      ),
    );
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
      body: SingleChildScrollView(
        child: Padding(
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
                        '\n🎯 Floating logger button (look for the floating button!)',
                      ),
                      Text(
                        '\n📊 General logging with different levels using logger.d, logger.i, logger.w, logger.e',
                      ),
                      Text(
                        '\n🌐 API request/response logging using Dio interceptor (FlutterAwesomeLoggerDioInterceptor)',
                      ),
                      Text(
                        '\n🧊 BLoC/Cubit state management logging with AwesomeBlocObserver',
                      ),
                      Text(
                          '\n🎨 Unified UI for browsing and searching all logs in one place'),
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
                label: Text('Generate GeneralLogs ($_logCounter generated)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _makeApiCall(
                  'https://jsonplaceholder.typicode.com/posts/1/',
                ),
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
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _openCubitDemo(),
                icon: const Icon(Icons.account_tree),
                label: const Text('Example with Cubit (BLoC)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _openLogger,
                icon: const Icon(Icons.list_alt),
                label: const Text('Open Awesome Logger'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.purple.withValues(alpha: 0.1),
                  foregroundColor: Colors.purple,
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
              const SizedBox(height: 16),
              const Card(
                color: Colors.blue,
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Icon(Icons.info, color: Colors.white),
                      SizedBox(height: 8),
                      Text(
                        'Tap the floating button to access logs quickly!\n\n🤳 Shake your device to show/hide the logger button!\n\n🤳 Shake when logger is disabled to enable it!',
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
      ),
    );
  }
}
