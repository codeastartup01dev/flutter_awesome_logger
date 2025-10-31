<div align="center">

# Flutter Awesome Logger 🚀

*A comprehensive Flutter logging package that makes debugging a breeze!*

[![pub package](https://img.shields.io/pub/v/flutter_awesome_logger.svg?style=for-the-badge)](https://pub.dev/packages/flutter_awesome_logger)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=for-the-badge)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)


**Features a floating logger, automatic API logging with Dio interceptor, comprehensive API demo page, and a unified beautiful UI for viewing all logs in one place.**

[📖 Documentation](#-getting-started) • [🚀 Installation](#installation) • [💡 Examples](#basic-usage) • [🎨 Customization](#-customization)

</div>

## 📋 Table of Contents

- [✨ Features](#-features)
- [📸 Screenshots](#-screenshots)
- [🚀 Getting Started](#-getting-started)
  - [Installation](#installation)
  - [Basic Usage](#basic-usage)
  - [How to Get Logs in the Unified Interface](#-how-to-get-logs-in-the-unified-interface)
- [🔧 Configuration Options](#-configuration-options)
- [⚙️ Settings Modal](#️-settings-modal)
- [📚 Advanced Usage](#-advanced-usage)
- [🎨 Customization](#-customization)
- [🤝 Contributing](#-contributing)
- [📝 License](#-license)
- [🐛 Issues & Support](#-issues--support)
- [📞 Connect With Us](#-connect-with-us)

---

## ✨ Features

<div align="center">

| Feature | Description |
|---------|-------------|
| 📱 **Floating Logger Button** | Always accessible debug button that floats over your app - drag to reposition, auto-snaps to edges |
| 👆 **Long Press Floating Button** | **Tap:** Opens logger UI instantly • **Long Press:** Shows quick actions menu • **Drag:** Repositions button • **Double Tap:** Toggles pause/resume logging |
| 🌐 **Automatic API Logging** | Built-in Dio interceptor for seamless API logging - captures requests, responses, errors, and timing automatically |
| 📱 **API Demo Page** | Comprehensive demo page showcasing GET, POST, and error handling with real API calls and automatic logging |
| 🎨 **Unified Beautiful UI** | Clean, modern interface with syntax highlighting - unified view for all logs, advanced filtering, and intuitive navigation |
| 📊 **Multiple Log Levels** | Support for debug, info, warning, error, and verbose logs - color-coded with filtering and search capabilities |
| 💾 **Smart Storage** | Logs stored only when logger is enabled - conserves memory and respects privacy settings |
| ⏸️ **Pause/Resume Logging** | Temporarily pause all logging with visual indicators - useful for focusing on specific app sections |
| 🔍 **Search & Filter** | Easily find specific logs with advanced filtering - search by text, level, timestamp, or source file |
| 🎯 **Simple Configuration** | Single `enabled` property controls both UI and storage - async support for conditional initialization |
| ⚙️ **Settings Modal** | Comprehensive runtime configuration via settings modal - adjust all logger options on-the-fly |
| 🔄 **Circular Buffer** | Configurable log replacement behavior - choose between replacing oldest logs or stopping when limit reached |
| 📱 **Responsive Design** | Works perfectly on all screen sizes - adaptive layouts for phones, tablets, and different orientations |

</div>

## 📸 Screenshots

<div align="center">

### 🖼️ App Screenshots Gallery

<img width="650" height="700" alt="awesome_flutter_logger_1" src="https://github.com/user-attachments/assets/51c14160-9c47-4712-b362-adcf9f032558" />
<img width="650" height="700" alt="awesome_flutter_logger_2" src="https://github.com/user-attachments/assets/b71cf4bc-4dae-480b-873f-70082fae7139" />

</div>

## 🚀 Getting Started

### Installation

<div align="center">

#### 📦 Add to your `pubspec.yaml`

</div>

```yaml
dependencies:
  flutter_awesome_logger: ^latest_version
```

<div align="center">

#### 🔄 Install the package

</div>

```bash
# Using Flutter CLI
flutter pub get

# Or using Dart CLI
dart pub get
```

<div align="center">

#### 📱 Import in your Dart code

</div>

```dart
import 'package:flutter_awesome_logger/flutter_awesome_logger.dart';
```

### Basic Usage

<div>

#### ⚡ **Easiest Setup (Just 2 Lines!)**

The absolute simplest way to get started - just wrap your app:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_awesome_logger/flutter_awesome_logger.dart';

// Global navigator key for navigation (required for logger history page)
final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FlutterAwesomeLogger(
      navigatorKey: navigatorKey, // Required if  logger history page does not open on floating button press
      child: MaterialApp(
        navigatorKey: navigatorKey, // Required if logger history page does not open on floating button press
        home: const YourHomePage(),
      ),
    );
  }
}
```

**That's it! 🎉** The logger is now active with default settings. You'll see:
- 📱 Floating logger button on your screen
- 📊 Unified logger interface ready for all your logs

---

#### 🚀 **API Demo Page (Advanced Example)**

For a comprehensive demonstration of API logging capabilities, check out our example app's dedicated API demo page:

```dart
// Navigate to API demo page from your app
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const ApiDemoPage()),
);
```

**What the API demo includes:**
- ✅ **GET Requests** - Fetch all users and individual users by ID
- ✅ **POST Requests** - Create new users with sample data
- ✅ **Error Handling** - Simulate and handle API errors (404, network issues)
- ✅ **Loading States** - Beautiful loading indicators during requests
- ✅ **User Cards** - Attractive display of user data with avatars and details
- ✅ **Auto-logging** - Every request is automatically logged with full details
- ✅ **cURL Generation** - Copy-paste ready cURL commands for testing

**Features demonstrated:**
- Real-time API logging with Dio interceptor
- Error state management and user feedback
- Professional UI with loading states and error displays
- Comprehensive user data model with JSON parsing
- Multiple HTTP methods (GET, POST) with proper error handling

---

## 📋 How to Get Logs in the Unified Interface

### 🌐 API Logs
*For HTTP requests and responses*

To capture API logs in the unified logger interface, add the Dio interceptor:

**Step 1: Add the interceptor to your Dio instance**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_awesome_logger/flutter_awesome_logger.dart';

final dio = Dio();
dio.interceptors.add(FlutterAwesomeLoggerDioInterceptor());

// Now all API calls are automatically logged!
final response = await dio.get('https://jsonplaceholder.typicode.com/users');
```

**What you get:**
- ✅ **Automatic capture** - All requests and responses logged automatically
- ✅ **cURL generation** - Copy-paste ready cURL commands for testing
- ✅ **Error handling** - Network errors and HTTP errors captured
- ✅ **Performance timing** - Request duration tracking
- ✅ **Advanced filtering** - Filter by status code, method, or endpoint
- ✅ **Search functionality** - Search through URLs, headers, and response content

---

### 📊 General Logs
*For application logs and debugging*

To capture general logs in the unified logger interface:

**Step 1: Create a logger instance**
// Create global logger instance (recommended: make a new file eg. my_logger.dart)
```dart
import 'package:flutter_awesome_logger/flutter_awesome_logger.dart';

final logger = FlutterAwesomeLogger.loggingUsingLogger;
```

**Step 2: Use the logger throughout your app**

```dart
import 'my_logger.dart';

class MyService {
  void performOperation() {
    // Debug information (development only)
    logger.d('Starting complex operation with parameters: $params');
    
    // General information (important events)
    logger.i('User logged in successfully');
    
    // Warnings (potential issues)
    logger.w('API rate limit approaching: ${remaining} requests left');
    
    // Errors (with full context)
    try {
      // Your code here
    } catch (e, stackTrace) {
      logger.e('Failed to process user data', error: e, stackTrace: stackTrace);
    }
  }
}
```

**What you get:**
- ✅ **Multiple log levels** - DEBUG (grey), INFO (blue), WARNING (orange), ERROR (red)
- ✅ **Stack trace support** - Full error context with file paths and line numbers
- ✅ **Source tracking** - See exactly which file and method generated each log
- ✅ **Advanced filtering** - Filter by log level, source file, or search content
- ✅ **Export capabilities** - Copy individual logs or export entire filtered sets
- ✅ **Real-time updates** - Logs appear instantly as your app runs

---

## 🔧 Configuration Options

<div align="center">

### ⚙️ Flexible Configuration System

</div>

#### 🎛️ **FlutterAwesomeLogger Configuration**

<div align="center">

The `enabled` parameter supports both synchronous and asynchronous initialization:

</div>

<table width="100%">
<tr>
<td width="33%" align="center">

**🟢 Immediate Enable**
```dart
enabled: true
```
Logger starts immediately

</td>
<td width="33%" align="center">

**🔴 Immediate Disable**
```dart
enabled: false
```
Logger is disabled

</td>
<td width="33%" align="center">

**⏳ Async Enable**
```dart
enabled: someFuture()
```
Waits for Future resolution

</td>
</tr>
</table>

---

#### 📊 **AwesomeLoggerConfig**

<div align="center">

*Core logging behavior configuration*

</div>

<table width="100%">
<thead>
<tr>
<th width="25%">Property</th>
<th width="20%">Type</th>
<th width="20%">Default</th>
<th width="35%">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>maxLogEntries</code></td>
<td><code>int</code></td>
<td><code>1000</code></td>
<td>Maximum number of log entries to keep in memory</td>
</tr>
<tr>
<td><code>showFilePaths</code></td>
<td><code>bool</code></td>
<td><code>true</code></td>
<td>Display file paths in console output</td>
</tr>
<tr>
<td><code>showEmojis</code></td>
<td><code>bool</code></td>
<td><code>true</code></td>
<td>Show emojis in console output for better readability</td>
</tr>
<tr>
<td><code>useColors</code></td>
<td><code>bool</code></td>
<td><code>true</code></td>
<td>Enable colored console output</td>
</tr>
<tr>
<td><code>stackTraceLines</code></td>
<td><code>int</code></td>
<td><code>0</code></td>
<td>Number of stack trace lines to display</td>
</tr>
<tr>
<td><code>enableCircularBuffer</code></td>
<td><code>bool</code></td>
<td><code>true</code></td>
<td>Enable circular buffer - replace oldest logs when limit reached, or stop logging</td>
</tr>
</tbody>
</table>

```dart
const AwesomeLoggerConfig({
  int maxLogEntries = 1000,
  bool showFilePaths = true,
  bool showEmojis = true,
  bool useColors = true,
  int stackTraceLines = 0,
  bool enableCircularBuffer = true,
});
```

---

#### 🎨 **FloatingLoggerConfig**

<div align="center">

*Floating button UI and behavior configuration*

</div>

<table width="100%">
<thead>
<tr>
<th width="25%">Property</th>
<th width="20%">Type</th>
<th width="20%">Default</th>
<th width="35%">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>backgroundColor</code></td>
<td><code>Color</code></td>
<td><code>Colors.deepPurple</code></td>
<td>Background color of the floating button</td>
</tr>
<tr>
<td><code>icon</code></td>
<td><code>IconData</code></td>
<td><code>Icons.developer_mode</code></td>
<td>Icon displayed on the floating button</td>
</tr>
<tr>
<td><code>showCount</code></td>
<td><code>bool</code></td>
<td><code>true</code></td>
<td>Display log count badge on button</td>
</tr>
<tr>
<td><code>enableGestures</code></td>
<td><code>bool</code></td>
<td><code>true</code></td>
<td>Enable drag gestures for repositioning</td>
</tr>
<tr>
<td><code>autoSnapToEdges</code></td>
<td><code>bool</code></td>
<td><code>true</code></td>
<td>Automatically snap button to screen edges</td>
</tr>
<tr>
<td><code>size</code></td>
<td><code>double</code></td>
<td><code>60.0</code></td>
<td>Size of the floating button</td>
</tr>
</tbody>
</table>

```dart
const FloatingLoggerConfig({
  Color backgroundColor = Colors.deepPurple,
  IconData icon = Icons.developer_mode,
  bool showCount = true,
  bool enableGestures = true,
  bool autoSnapToEdges = true,
  double size = 60.0,
});
```

## 📚 Advanced Usage

### Accessing Log History

```dart
// Get all stored logs
final logs = FlutterAwesomeLogger.getLogs();

// Get logs by level
final errorLogs = FlutterAwesomeLogger.getLogsByLevel('ERROR');

// Get recent logs
final recentLogs = FlutterAwesomeLogger.getRecentLogs(
  duration: Duration(minutes: 10),
);

// Clear all logs
FlutterAwesomeLogger.clearLogs();

// Export logs as formatted text
String exportedLogs = FlutterAwesomeLogger.exportLogs();
```

### Programmatically Show Logger UI

```dart
// Show the unified logger history page
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AwesomeLoggerHistoryPage(),
  ),
);
```

### Pause/Resume Logging

```dart
// Pause all logging (both console and storage)
FlutterAwesomeLogger.setPauseLogging(true);

// Resume logging
FlutterAwesomeLogger.setPauseLogging(false);

// Check if logging is paused
bool isPaused = FlutterAwesomeLogger.isPaused;
```

### Control Floating Logger Visibility

```dart
// Check if floating logger is visible
bool isVisible = FlutterAwesomeLogger.isVisible();

// Show/hide the floating logger
FlutterAwesomeLogger.setVisible(true);  // Show
FlutterAwesomeLogger.setVisible(false); // Hide

// Toggle visibility
FlutterAwesomeLogger.toggleVisibility();
```

### Manage API Logs

```dart
// Get all API logs
final apiLogs = FlutterAwesomeLogger.getApiLogs();

// Get API logs by type
final successLogs = FlutterAwesomeLogger.getApiLogsByType(ApiLogType.success);
final errorLogs = FlutterAwesomeLogger.getApiLogsByType(ApiLogType.serverError);

// Clear API logs
FlutterAwesomeLogger.clearApiLogs();
```

---

## ⚙️ Settings Modal

<div align="center">

### 🎛️ Runtime Configuration

*The settings modal provides comprehensive runtime control over all logger behavior*

</div>

#### 🖱️ **Accessing Settings**

- **App Bar Icon**: Tap the settings icon (⚙️) in the logger history page app bar
- **Modal Interface**: Clean bottom sheet with organized configuration sections

#### 🔧 **Available Settings**

<table width="100%">
<thead>
<tr>
<th width="30%">Setting</th>
<th width="70%">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td><strong>📊 Max Log Entries</strong></td>
<td>Real-time adjustment of maximum log entries limit. Changes take effect immediately.</td>
</tr>
<tr>
<td><strong>🔄 Circular Buffer</strong></td>
<td>
  <strong>ON (default):</strong> Automatically replaces oldest logs when limit reached<br>
  <strong>OFF:</strong> Stops logging completely when limit reached
</td>
</tr>
<tr>
<td><strong>📁 Show File Paths</strong></td>
<td>Toggle display of file paths and line numbers in console output</td>
</tr>
<tr>
<td><strong>😀 Show Emojis</strong></td>
<td>Toggle emoji indicators in console logs for better readability</td>
</tr>
<tr>
<td><strong>🎨 Use Colors</strong></td>
<td>Toggle color coding for different log levels in console output</td>
</tr>
<tr>
<td><strong>📈 Current Stats</strong></td>
<td>Real-time display of currently stored log count</td>
</tr>
</tbody>
</table>

#### 💡 **Usage Tips**

- **Immediate Changes**: All settings take effect instantly - no app restart required
- **Mobile Friendly**: Modal handles keyboard input and different screen sizes
- **Visual Feedback**: Current behavior is clearly described for each setting
- **Live Stats**: See how many logs are currently stored as you adjust limits

#### 📱 **Example Configuration**

```dart
// Initial configuration
loggerConfig: const AwesomeLoggerConfig(
  maxLogEntries: 500,
  enableCircularBuffer: true, // Replace oldest logs
  showFilePaths: true,
  showEmojis: true,
  useColors: true,
),

// Runtime changes via settings modal:
// - Change maxLogEntries to 1000
// - Toggle enableCircularBuffer to false
// - Turn off showEmojis
// All changes apply immediately!
```

---

## 🎨 Customization

The logger UI is highly customizable. You can:

- Change colors and themes
- Customize the floating button appearance
- Configure log display formats
- Add custom filters and search options
- Pause/resume logging as needed
- Control logging behavior with simple configuration

---

<div align="center">

## 🤝 Contributing

**We welcome contributions!** 

[![Contributors](https://img.shields.io/github/contributors/codeastartup01dev/flutter_awesome_logger?style=for-the-badge)](https://github.com/codeastartup01dev/flutter_awesome_logger/graphs/contributors)
[![Pull Requests](https://img.shields.io/github/issues-pr/codeastartup01dev/flutter_awesome_logger?style=for-the-badge)](https://github.com/codeastartup01dev/flutter_awesome_logger/pulls)

Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

[🔧 Contribute](https://github.com/codeastartup01dev/flutter_awesome_logger/fork) • [📋 Issues](https://github.com/codeastartup01dev/flutter_awesome_logger/issues) • [💡 Feature Requests](https://github.com/codeastartup01dev/flutter_awesome_logger/issues/new)

</div>

---

<div align="center">

## 📝 License

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

</div>

---

<div align="center">

## 🐛 Issues & Support

<table width="100%">
<tr>
<td width="33%" align="center">

### 🐛 **Bug Reports**
Found a bug? Let us know!

[![Issues](https://img.shields.io/github/issues/codeastartup01dev/flutter_awesome_logger?style=for-the-badge&color=red)](https://github.com/codeastartup01dev/flutter_awesome_logger/issues)

[Report Bug](https://github.com/codeastartup01dev/flutter_awesome_logger/issues/new?template=bug_report.md)

</td>
<td width="33%" align="center">

### 💡 **Feature Requests**
Have an idea? Share it!

[![Feature Requests](https://img.shields.io/github/issues/codeastartup01dev/flutter_awesome_logger/enhancement?style=for-the-badge&color=blue)](https://github.com/codeastartup01dev/flutter_awesome_logger/labels/enhancement)

[Request Feature](https://github.com/codeastartup01dev/flutter_awesome_logger/issues/new?template=feature_request.md)

</td>
<td width="33%" align="center">

### 💬 **Discussions**
Join the conversation!

[![Discussions](https://img.shields.io/github/discussions/codeastartup01dev/flutter_awesome_logger?style=for-the-badge&color=green)](https://github.com/codeastartup01dev/flutter_awesome_logger/discussions)

[Start Discussion](https://github.com/codeastartup01dev/flutter_awesome_logger/discussions)

</td>
</tr>
</table>

</div>

---

<div align="center">

## 📞 Connect With Us

<table>
<tr>
<td align="center">

### 📧 **Email**
[codeastartup01dev@gmail.com](mailto:codeastartup01dev@gmail.com)

</td>
<td align="center">

### 🐦 **Twitter**
[@codeastartup01dev](https://twitter.com/codeastartup01dev)

</td>
<td align="center">

### 💬 **Discord**
[Join our community](https://discord.gg/codeastartup01dev)

</td>
</tr>
</table>

---

### ⭐ **Show Your Support**

If this package helped you, please consider giving it a ⭐ on GitHub!

[![GitHub stars](https://img.shields.io/github/stars/codeastartup01dev/flutter_awesome_logger?style=social)](https://github.com/codeastartup01dev/flutter_awesome_logger/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/codeastartup01dev/flutter_awesome_logger?style=social)](https://github.com/codeastartup01dev/flutter_awesome_logger/network/members)

---

<sub>Made with ❤️ by [codeastartup01dev](https://github.com/codeastartup01dev)</sub>

</div>
