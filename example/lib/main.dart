import 'package:flutter/material.dart';
import 'package:flutter_awesome_logger/flutter_awesome_logger.dart';

import 'pages/pages.dart';

/// Global navigator key for navigation
final navigatorKey = GlobalKey<NavigatorState>();

/// Main entry point of the application
void main() {
  runApp(const MyApp());
}

/// Root application widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Future that resolves to true after 3 seconds to demonstrate delayed logger enabling
  Future<bool> _shouldEnableLogger() async {
    await Future.delayed(const Duration(seconds: 3));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey:
          navigatorKey, // IMPORTANT: Required for logger history page navigation
      title: 'Awesome Flutter Logger Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: FlutterAwesomeLogger(
        // 🔄 Enable logging after 3 seconds using Future (or use enabled: true for immediate)
        enabled: _shouldEnableLogger(),
        navigatorKey:
            navigatorKey, // IMPORTANT: Required for logger history page navigation

        // ✨ Logger configuration (optional)
        loggerConfig: const AwesomeLoggerConfig(
          maxLogEntries: 500,
          showFilePaths: true,
          showEmojis: true,
          useColors: true,
          defaultMainFilter: LogSource.api, // 🎯 Set API Logs as default filter
        ),

        // 🔍 BLoC observer configuration (optional) - automatically configures Bloc.observer
        blocObserverConfig: const AwesomeBlocObserverConfig(
          logEvents: true,
          logTransitions: true,
          logChanges: true,
          logCreate: true,
          logClose: true,
          logErrors: true,
          printToConsole: true,
          maxConsoleLength: 200,
        ),

        // 🎨 Floating logger UI configuration (optional)
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
