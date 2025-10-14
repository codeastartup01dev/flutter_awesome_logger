# Flutter Awesome Logger 🚀

A comprehensive Flutter logging package that makes debugging a breeze! Features a floating logger, automatic API logging with Dio interceptor, and a beautiful UI for viewing logs.

[![pub package](https://img.shields.io/pub/v/flutter_awesome_logger.svg)](https://pub.dev/packages/flutter_awesome_logger)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## ✨ Features

- 📱 **Floating Logger Button** - Always accessible debug button that floats over your app (can be disabled)
- 🌐 **Automatic API Logging** - Built-in Dio interceptor for seamless API request/response logging
- 🎨 **Beautiful UI** - Clean, modern interface for viewing logs with syntax highlighting
- 📊 **Multiple Log Levels** - Support for debug, info, warning, error, and verbose logs
- 💾 **Smart Storage** - Logs are stored only when logger is enabled, conserving memory
- ⏸️ **Pause/Resume Logging** - Temporarily pause all logging with visual indicators
- 🔍 **Search & Filter** - Easily find specific logs with search and filtering capabilities
- 🎯 **Simple Configuration** - Single `enabled` property controls both UI and storage
- 📱 **Responsive Design** - Works perfectly on all screen sizes

## 📸 Screenshots

<table>
  <tr>
    <td align="center">
      <img width="300" height="650" alt="Floating Logger Button" src="https://github.com/user-attachments/assets/83129e99-7e21-400a-a52c-74ecb1ab3492" />
      <br>
      <em>Floating Logger Button</em>
    </td>
    <td align="center">
      <img width="300" height="650" alt="API Logs View" src="https://github.com/user-attachments/assets/707bd799-f7d6-40ae-9331-bafbf7a58680" />
      <br>
      <em>API Logs View</em>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img width="300" height="650" alt="General Logs View" src="https://github.com/user-attachments/assets/61c2606e-f22f-496f-98e9-d39d6da3ccfd" />
      <br>
      <em>General Logs View</em>
    </td>
    <td align="center">
      <img width="300" height="650" alt="Log Details" src="https://github.com/user-attachments/assets/a6947367-578c-4df4-b73f-eece6a411b14" />
      <br>
      <em>Log Details</em>
    </td>
  </tr>
</table>

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
        enabled: true, // Shows floating logger AND enables log storage
        // Auto-configure logger settings
        loggerConfig: const AwesomeLoggerConfig(
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

For more control, configure manually in main(). Note: Manual configuration doesn't automatically control log storage - use Option 1 for simpler setup.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_awesome_logger/flutter_awesome_logger.dart';

void main() {
  // Manual configuration
  LoggingUsingLogger.configure(
    const AwesomeLoggerConfig(
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
        enabled: true, // Controls both floating logger AND log storage
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
  int maxLogEntries = 1000,        // Maximum number of log entries to keep
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

### Pause/Resume Logging

```dart
// Pause all logging (both console and storage)
LoggingUsingLogger.setPauseLogging(true);

// Resume logging
LoggingUsingLogger.setPauseLogging(false);

// Check if logging is paused
bool isPaused = LoggingUsingLogger.isPaused;
```

## 🎨 Customization

The logger UI is highly customizable. You can:

- Change colors and themes
- Customize the floating button appearance
- Configure log display formats
- Add custom filters and search options
- Pause/resume logging as needed
- Control logging behavior with simple configuration

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
