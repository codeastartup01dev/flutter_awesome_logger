# Flutter Awesome Logger 🚀

A comprehensive Flutter logging package that makes debugging a breeze! Features a floating logger, automatic API logging with Dio interceptor, and a beautiful UI for viewing logs.

[![pub package](https://img.shields.io/pub/v/flutter_awesome_logger.svg)](https://pub.dev/packages/flutter_awesome_logger)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## ✨ Features

- 📱 **Floating Logger Button** - Always accessible debug button that floats over your app
- 🌐 **Automatic API Logging** - Built-in Dio interceptor for seamless API request/response logging
- 🎨 **Beautiful UI** - Clean, modern interface for viewing logs with syntax highlighting
- 📊 **Multiple Log Levels** - Support for debug, info, warning, error, and verbose logs
- 💾 **Persistent Storage** - Logs are stored and persist across app sessions
- 🔍 **Search & Filter** - Easily find specific logs with search and filtering capabilities
- 🎯 **Configurable** - Highly customizable with various configuration options
- 📱 **Responsive Design** - Works perfectly on all screen sizes

## 📸 Screenshots

*Add screenshots of your logger UI here*

## 🚀 Getting Started

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_awesome_logger: ^0.1.0
```

Then run:

```bash
flutter pub get
```

### Basic Usage

#### **Option 1: Auto-Configuration (Recommended - Easiest)**

Simply wrap your app with `FlutterAwesomeLogger` and pass the configuration:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_awesome_logger/flutter_awesome_logger.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FlutterAwesomeLogger(
        // Auto-configure logger settings
        loggerConfig: const AwesomeLoggerConfig(
          enabled: true,
          storeLogs: true,
          maxLogEntries: 500,
          showFilePaths: true,
          showEmojis: true,
          useColors: true,
        ),
        // Auto-initialize (true by default)
        autoInitialize: true,
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

#### **Option 2: Manual Configuration (Advanced)**

For more control, configure manually in main():

```dart
import 'package:flutter/material.dart';
import 'package:flutter_awesome_logger/flutter_awesome_logger.dart';

void main() {
  // Manual configuration
  LoggingUsingLogger.configure(
    const AwesomeLoggerConfig(
      enabled: true,
      storeLogs: true,
      maxLogEntries: 500,
      showFilePaths: true,
      showEmojis: true,
      useColors: true,
    ),
  );

  // Manual initialization
  FloatingLoggerManager.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FlutterAwesomeLogger(
        // Don't auto-configure since we did it manually
        autoInitialize: false,
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

3. **Start logging:**

```dart
import 'package:flutter_awesome_logger/flutter_awesome_logger.dart';

// Use the global logger instance
logger.d('Debug message');
logger.i('Info message');
logger.w('Warning message');
logger.e('Error message');
logger.v('Verbose message');
```

### API Logging with Dio

Automatically log all your API requests and responses:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_awesome_logger/flutter_awesome_logger.dart';

final dio = Dio();

// Add the awesome logger interceptor
dio.interceptors.add(AwesomeLoggerDioInterceptor());

// Now all your API calls will be automatically logged!
final response = await dio.get('https://api.example.com/data');
```

## 🔧 Configuration Options

### AwesomeLoggerConfig

```dart
const AwesomeLoggerConfig({
  bool storeLogs = true,           // Store logs in memory for UI display
  int maxLogEntries = 1000,        // Maximum number of log entries to keep
  bool enabled = true,             // Enable/disable logger
  bool showFilePaths = true,       // Show file paths in console output
  bool showEmojis = true,          // Show emojis in console output
  bool useColors = true,           // Use colors in console output
  int stackTraceLines = 0,         // Number of stack trace lines to show
});
```

### FloatingLoggerConfig

```dart
const FloatingLoggerConfig({
  Color backgroundColor = Colors.blue,     // Background color of the floating button
  IconData icon = Icons.bug_report,       // Icon for the floating button
  bool showCount = true,                  // Show log count badge
  bool enableGestures = true,             // Enable drag gestures
  bool autoSnapToEdges = true,            // Auto-snap to screen edges
  double size = 56.0,                     // Size of the floating button
});
```

## 📚 Advanced Usage

### Custom Log Formatting

```dart
// Log with custom formatting
logger.logCustom(
  level: LogLevel.info,
  message: 'Custom formatted message',
  error: someError,
  stackTrace: someStackTrace,
);
```

### Accessing Log History

```dart
// Get all stored logs
final logs = FlutterAwesomeLogger.getLogs();

// Get logs by level
final errorLogs = FlutterAwesomeLogger.getLogsByLevel(LogLevel.error);

// Clear all logs
FlutterAwesomeLogger.clearLogs();
```

### Programmatically Show Logger UI

```dart
// Show the logger history page
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const LoggerHistoryPage(),
  ),
);
```

## 🎨 Customization

The logger UI is highly customizable. You can:

- Change colors and themes
- Customize the floating button appearance
- Configure log display formats
- Add custom filters and search options

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🐛 Issues

If you encounter any issues or have feature requests, please file them in the [issue tracker](https://github.com/codeastartup01dev/flutter_awesome_logger/issues).

## 📞 Support

- 📧 Email: codeastartup01dev@gmail.com
- 🐦 Twitter: [@codeastartup01dev](https://twitter.com/codeastartup01dev)
- 💬 Discord: [Join our community](https://discord.gg/codeastartup01dev)

---

Made with ❤️ by [codeastartup01dev](https://github.com/codeastartup01dev)