# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.2] (2024-10-16)
- made sort logs toggle button to api and general logs tabs more intuitive and user-friendly

## [1.1.1] (2024-10-16)
- updated README.md for better clarity, readability and formatting

## [1.1.0] (2024-10-16)
- updated example app pubspec.yaml with sdk: ">=3.0.0 <4.0.0"

## [1.0.10] (2024-10-16)

- updated README.md to show screenshots properly

## [1.0.9] (2024-10-16)

### Improved README Documentation
- 📖 **Enhanced README Documentation** - Complete overhaul of README with professional formatting and responsive design
- ⚡ **Easiest Setup Guide** - Added ultra-simple 2-line setup instructions with MaterialApp example
- 📱 **Mobile-Responsive Screenshots** - Images now stack vertically on mobile devices with CSS media queries
- 🎯 **Professional Layout** - Replaced centered table layouts with clean, left-aligned professional sections
- 📋 **Comprehensive Logging Guides** - Detailed explanations for both API logs and general logs tabs
- ✨ **Enhanced Features Table** - Added long press floating button feature with 4 detailed interaction methods
- 🎨 **Modern Badges and Styling** - Updated to for-the-badge style badges with Flutter/Dart technology indicators
- 📚 **Improved Navigation** - Added collapsible table of contents and better section organization
- 🔧 **Better Code Examples** - More practical examples with real-world usage patterns and best practices

## [1.0.8] (2024-10-16)

### Added
- 💬 **Simple Error Display** - Shows navigation error directly in the floating logger widget when navigation fails
- 📖 **Better Developer Experience** - Navigation errors now show both console output and visual in-widget message

### Fixed
- 🔧 **Navigation Context Issues** - Simplified error handling with reliable in-widget display and console output
- 🎯 **Error Visibility** - Users will always see navigation errors with clear instructions and code examples

## [1.0.7] (2024-10-16)

### Added
- 💬 **User-Friendly Error Dialog** - Added helpful dialog that appears when navigation fails, showing step-by-step solution
- 📖 **Better Developer Experience** - Navigation errors now show both console output and visual dialog with code examples

### Improved
- 🎯 **Error Handling** - Enhanced navigation error reporting with clear instructions and selectable documentation link

## [1.0.6] (2024-10-16)

### Fixed
- 🔧 **Navigator Key Handling** - Improved navigation logic to properly handle cases where `navigatorKey.currentState` is null
- 📱 **Navigation Robustness** - Better fallback mechanism when provided navigator key is not ready yet

## [1.0.5] (2024-10-16)

### Fixed
- 🔧 **Flutter Compatibility** - Replaced `Color.withValues()` with `Color.withOpacity()` for better compatibility with older Flutter versions
- 📱 **iOS Build Fix** - Fixed Xcode build errors related to undefined `withValues` method

## [1.0.4] (2024-10-16)

### Fixed
- 🔧 **Path Dependency Compatibility** - Changed `path` dependency from `^1.9.1` to `^1.9.0` to be compatible with Flutter SDK 3.24.5
- 📦 **Flutter SDK Compatibility** - Fixed version solving issues with flutter_test dependency conflicts

## [1.0.3] (2024-10-16)

### Changed
- 🔧 **Dart SDK Compatibility** - Lowered minimum Dart SDK requirement from `^3.8.1` to `>=3.0.0 <4.0.0`
- 📦 **Wider Compatibility** - Package now works with Dart SDK 3.0.0 and above, including 3.5.x versions

### Fixed
- 🐛 **Dependency Resolution** - Fixed version solving issues for projects using Dart SDK < 3.8.1

## [1.0.2] (2024-10-15)

### Changed
- ✨ **Synchronous Methods** - Removed unnecessary async/await from visibility and preference methods
- 📊 **Better Performance** - Visibility methods are now synchronous since they don't perform async operations
- 🎯 **Cleaner API** - No need for `await` when checking visibility or toggling



## [1.0.1] (2024-10-15)

### Added
- 📖 **Additional Methods** - `getSavedPosition()`, `savePosition()`, `clearPreferences()`, `initialize()` now available through `FlutterAwesomeLogger`
```

## [1.0.0] (2024-10-15)

### 🎉 Major Release - Stable API

This release marks the first stable version of Flutter Awesome Logger with a clean, production-ready API.

### Added
- 🏭 **Factory Pattern Implementation** - Clean access to logger through `FlutterAwesomeLogger.loggingUsingLogger`
- 🎯 **Simplified API** - Single entry point for logger access without exposing internal implementation
- 📖 **Enhanced Documentation** - Updated README with comprehensive factory pattern examples
- 🔧 **Better Encapsulation** - Internal logging classes are no longer directly exposed

### Changed
- 🚀 **New Recommended Usage** - `final logger = FlutterAwesomeLogger.loggingUsingLogger;`
- 📦 **Cleaner Exports** - Only necessary classes and configs are exported
- 📚 **Updated Examples** - All code examples now use the new factory pattern
- 🎨 **Improved Developer Experience** - More intuitive API design

### Technical
- 🏗️ **Static Getter Implementation** - Added static `loggingUsingLogger` getter to `FlutterAwesomeLogger` widget class
- 🧹 **Code Cleanup** - Removed unnecessary factory classes and simplified architecture
- 📊 **Maintainability** - Easier to maintain and extend in future versions

### Migration Guide
If you were using the logger directly:
```dart
// Old way (still works but not recommended)
import 'package:flutter_awesome_logger/src/core/logging_using_logger.dart';
final logger = LoggingUsingLogger();

// New way (recommended)
import 'package:flutter_awesome_logger/flutter_awesome_logger.dart';
final logger = FlutterAwesomeLogger.loggingUsingLogger;
```

All existing functionality remains the same - only the access pattern has been improved.

## [0.1.9] (2024-10-14)

### Added
- 🤳 **Shake to Enable Logger** - Shake your device to enable the entire logger system when it's disabled (perfect for production builds)
- 🎯 **Dual Shake Detection System** - Separate detectors for toggle visibility vs enable logger functionality
- 🏗️ **Smart State Management** - Automatic switching between shake detectors based on logger state

### Changed
- 🔄 **Updated Shake Package** - Upgraded to shake ^3.0.0 with improved callback signatures
- 📝 **Clearer Property Names** - Renamed `enableShakeToToggle` to `enableShakeToShowHideFloatingButton` and `enableShakeToEnable` to `enableShakeToEnableLogger`
- 🎨 **Enhanced Configuration** - More descriptive parameter names for better developer experience

### Fixed
- 🐛 **Flutter Analyze Issues** - Fixed all linting errors and warnings
- 🔧 **Callback Type Compatibility** - Updated shake detector callbacks to match new package API
- 📖 **Documentation Updates** - Corrected interceptor class name and updated version references

### Technical
- 🏗️ **Proper Resource Management** - Only one shake detector active at a time for optimal performance
- 🎯 **Type Safety** - Improved type checking and eliminated unnecessary type assertions
- 📊 **Code Quality** - All Flutter analyze checks pass with zero issues

## [0.1.8] (2024-10-14)

### Added
- 🎯 **Shake to Toggle** - Shake your device to show/hide the floating logger button(Only active when logger is enabled)



## [0.1.7] (2024-10-14)

### Added
- ⏸️ **Pause/Resume Logging** - Global pause state that temporarily stops all logging (console output and storage)
- 🎯 **Visual Pause Indicators** - Floating button changes color/icon when logging is paused, plus banner in logger history
- 🎮 **Pause Controls** - Long press floating button opens options menu with pause/resume, plus dedicated button in app bar
- 🔄 **Async Logger Initialization** - `enabled` parameter now accepts `FutureOr<bool>` for conditional initialization
- 🏗️ **Simplified API** - Removed unnecessary `storeLogs` and `autoInitialize` parameters

### Changed
- 🚀 **Unified Control** - Single `enabled` parameter now controls both floating logger visibility AND log storage
- 📱 **Enhanced Floating Logger** - Better visual feedback and more intuitive controls
- 🎨 **Improved UI** - Pause banner in logger history page with clear messaging and quick resume action
- 📖 **Updated Documentation** - Cleaner examples and better explanations of async capabilities

### Fixed
- 🐛 **API Logging Pause Issue** - API logs now properly respect the global pause state
- 🎯 **Configuration Simplification** - Removed confusing parameters that served no real purpose
- 🔧 **Code Cleanup** - Removed dead code and unnecessary complexity

### Breaking Changes
- ⚠️ **`AwesomeLoggerConfig.storeLogs` removed** - Use `FlutterAwesomeLogger.enabled` to control storage
- ⚠️ **`FlutterAwesomeLogger.autoInitialize` removed** - No longer needed
- ⚠️ **`FlutterAwesomeLogger.enabled` type changed** - Now accepts `FutureOr<bool>` instead of `bool`

### Technical
- 🏗️ **Future Resolution** - Proper async handling in widget lifecycle
- 🎯 **State Management** - Improved pause state synchronization across UI components
- 📊 **Performance** - Cleaner initialization logic and reduced unnecessary operations

## [0.1.6] (2024-10-14)

- updated dependencies and flutter analysis fixes.

## [0.1.5] (2024-10-13)

### Added
- added screenshots showcasing the flutter_awesome_logger capabilities to README.md

## [0.1.4] (2024-10-13)

### Added
- 🎯 **Comprehensive unfocus functionality** - Search field unfocuses on all interactions
- 🔄 **Smart keyboard management** - Dismisses keyboard when scrolling, tapping buttons, or interacting with UI
- 📱 **Enhanced mobile UX** - Follows platform conventions for keyboard behavior

### Fixed
- 🔧 **Layout issues in example app** - Fixed ParentDataWidget errors and pixel overflow
- 🎨 **Responsive design improvements** - Better layout handling for different screen sizes
- 📜 **SingleChildScrollView integration** - Proper scrolling behavior without layout conflicts

### Improved
- ⌨️ **Keyboard interaction patterns** - Consistent unfocus behavior across all tabs
- 🎯 **Touch interactions** - All buttons, filters, and controls dismiss keyboard automatically
- 📊 **User experience** - Smoother navigation and interaction flow

### Technical
- 🏗️ **Widget hierarchy fixes** - Resolved Expanded/Flex widget constraint issues
- 📱 **Scroll view optimization** - Proper handling of unbounded height constraints
- 🎯 **Event handling** - Added FocusScope management to all interactive elements

## [0.1.3] (2024-10-13)

### Changed
- 🚫 **Removed SharedPreferences dependency** - No longer stores logs or preferences locally
- 🔄 **In-memory storage** - Visibility and position are now stored only for current session
- 📦 **Lighter package** - Reduced dependencies for better performance

### Breaking Changes
- ⚠️ **Persistent storage removed** - Floating logger position and visibility reset on app restart
- 📱 **Session-only state** - All preferences are cleared when app closes

## [0.1.2] (2024-10-13)

- added correct usage of navigator key in debug print and example app

## [0.1.1] (2024-10-13)

- refactor: rename AwesomeLoggerInterceptor to FlutterAwesomeLoggerDioInterceptor

## [0.1.0] (2024-10-13)

### Added
- Initial release of Flutter Awesome Logger
- Core logging functionality with configurable options
- Floating logger button with draggable interface
- Automatic API logging with Dio interceptor
- Beautiful UI for viewing log history
- Support for multiple log levels (debug, info, warning, error, verbose)
- Persistent log storage using SharedPreferences
- Search and filter capabilities in log viewer
- Customizable floating button appearance
- Comprehensive configuration options
- Example app demonstrating all features

### Features
- 📱 Floating logger button that stays accessible
- 🌐 Automatic API request/response logging
- 🎨 Modern, clean UI design
- 📊 Multiple log levels with color coding
- 💾 Persistent storage across app sessions
- 🔍 Search and filter functionality
- 🎯 Highly configurable settings
- 📱 Responsive design for all screen sizes