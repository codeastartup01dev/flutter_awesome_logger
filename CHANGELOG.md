# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [3.0.2] (2025-12-09)

### 🎨 UI/UX Improvements
- 🎯 **Enhanced Class Filter UI** - Major improvements to the class filter bottom sheet
- 🗑️ **Universal Clear Button** - Added prominent "Clear All Filters" button at the top that clears all selected filters from all modes
- 🏷️ **Always-Visible Selected Items** - Selected filter chips are now always visible at the top, regardless of current filter mode
- 📊 **Filter Mode Badges** - Filter mode chips (All/Source/Path) now show badges indicating how many items are selected for each mode
- 🎨 **Better Visual Hierarchy** - Improved layout with clear button and selected items prominently displayed
- ⚡ **Mode-Agnostic Clearing** - Clear button works across all filter modes, not just the currently active one

### 🔧 Technical Enhancements
- 🏗️ **Unified Filter Management** - Single clear function that handles all filter types simultaneously
- 📱 **Responsive UI Components** - Better organization of filter controls and selected items display
- 🎯 **Smart State Management** - Improved handling of filter state across different modes

### 📱 User Experience
- 🚀 **Faster Filter Management** - Quick access to clear all filters from any filter mode
- 👁️ **Better Visibility** - Selected items always visible, no need to switch modes to see what's selected
- 📊 **Visual Feedback** - Clear indication of which filter modes have active selections
- 🎨 **Cleaner Interface** - More intuitive layout with logical grouping of controls

---

## [3.0.1] (2025-12-09)

### 🐛 Bug Fixes
- 🔧 **Import Conflict Resolution** - Fixed naming conflicts between global logger and mixin's logger getter
- 📦 **Cleaner Exports** - Removed global `logger` from package exports to prevent shadowing issues
- 🎯 **Better Mixin Experience** - AwesomeLoggerMixin now works seamlessly without requiring `this.logger`

### 📚 Documentation
- 📖 **Improved Examples** - Updated demo files and documentation for cleaner mixin usage
- 💡 **Better Migration Guide** - Clearer instructions for avoiding import conflicts

---

## [3.0.0] (2025-12-09)

### 🎉 Major Release - Scoped Logger & Mixin Support

This release introduces powerful new ways to add automatic source tracking to your logs, making it easier to filter and identify logs by class/component.

### Added
- 🏷️ **AwesomeLoggerMixin** - New mixin for automatic class-based source tracking using `runtimeType`
  - Simply add `with AwesomeLoggerMixin` to any class
  - Use `logger.d()`, `logger.i()`, `logger.w()`, `logger.e()` - source is automatically set to class name
  - Perfect for Cubits, Blocs, Services, Repositories, and any class
  - No need for `this.logger` - just use `logger` directly!
- 🎯 **ScopedLogger** - New scoped logger class with pre-configured source identifier
  - All logs automatically include the source name
  - Same API as regular logger (`d`, `i`, `w`, `e` methods)
- 🔧 **`logger.scoped()` Method** - Create scoped logger instances with custom source names
  - `final _logger = logger.scoped('MyClassName')` for manual source control
  - `late final _logger = logger.scoped(runtimeType.toString())` for automatic class name

### Changed
- ⚠️ **Breaking Change**: Removed global `logger` from package exports
  - Users should create their own `logger` instance via `FlutterAwesomeLogger.loggingUsingLogger`
  - This prevents naming conflicts with the mixin's `logger` getter
  - Migration: Create a `my_logger.dart` file with `final logger = FlutterAwesomeLogger.loggingUsingLogger;`

### Usage Examples

**Using AwesomeLoggerMixin (Recommended):**
```dart
class CubitAppConfig extends Cubit<StateAppConfig> with AwesomeLoggerMixin {
  CubitAppConfig() : super(const StateAppConfig()) {
    logger.d('Instance created'); // source: 'CubitAppConfig'
  }
  
  void loadConfig() {
    logger.i('Loading config...'); // source: 'CubitAppConfig'
  }
}
```

**Using Scoped Logger:**
```dart
class MyService {
  final _logger = logger.scoped('MyService');
  // Or: late final _logger = logger.scoped(runtimeType.toString());
  
  void doWork() {
    _logger.d('Working...'); // source: 'MyService'
  }
}
```

### Technical
- 🏗️ **Zero Boilerplate** - Mixin approach requires no additional code, just add `with AwesomeLoggerMixin`
- 🎯 **Production Ready** - Uses `runtimeType` which works correctly with inheritance
- 📦 **Backward Compatible** - Existing `source` parameter still works for one-off overrides
- 🔄 **Shadows Global Logger** - Mixin's `logger` getter shadows imported global logger within the class

### Exports
- Added `AwesomeLoggerMixin` to public exports
- Added `ScopedLogger` to public exports

---

## [2.1.2] (2025-12-06)

### Added
- 🎯 **Class-Based Filtering** - New "Classes" button in logger history page for filtering logs by class names
- 📱 **Class Filter Bottom Sheet** - Dedicated bottom sheet for class selection with multi-select functionality
- 🔄 **Dual View Modes** - Toggle between list view and compact chip view for class selection
- 📊 **Class Statistics** - Shows log count per class with visual indicators
- 🎨 **Smart Button Styling** - Classes button appears grey when no classes are available, purple when active
- 🔍 **Class Search** - Search and filter through available classes in the bottom sheet
- 📋 **Selected Classes Display** - Horizontal chip list showing currently selected classes
- 💡 **Educational Content** - Informative message explaining class filtering when no classes exist
- 🏷️ **Source Parameter for Logging** - All log methods (`d`, `i`, `w`, `e`) now accept an optional `source` parameter for explicit source identification in release builds

### Enhanced
- 🎛️ **Advanced Filtering** - Expanded filtering capabilities beyond log levels and API methods
- 📱 **Better UX** - Improved filter section with more granular control options
- 🎯 **Source-Aware Filtering** - Class filtering only applies to general logs, respects main source filters
- 📖 **Release Build Support** - Added documentation for handling file path extraction limitations in production builds

### Technical
- 🏗️ **FilterManager Enhancement** - Added `selectedClasses` state management and class filtering logic
- 📊 **LogDataService Updates** - New methods for extracting and counting classes from logs
- 🎨 **UI Components** - New `ClassFilterBottomSheet` and `ClassChipTile` widgets with responsive design
- 📱 **Material Design 3** - Full theming support for the new filter components

### Documentation
- ⚠️ **Release Build Limitations** - Added comprehensive documentation explaining why file paths show as "unknown" in production
- 💡 **Best Practices** - Added examples for using the `source` parameter effectively in production apps


## [2.1.1] (2025-10-31)

### Fixed
- 🔧 **Source File Path Display** - Fixed incorrect source file path in logger history page showing `logging_using_logger.dart` instead of actual calling file (e.g., `api_demo_page.dart`)
- 📍 **Stack Trace Filtering** - Improved stack trace filtering to properly exclude internal logger files and show correct source locations

## [2.1.0] (2025-10-31)

### Added
- 🎛️ **Settings Modal** - Added comprehensive settings modal accessible via app bar settings icon
- 🔄 **Circular Buffer Configuration** - New `enableCircularBuffer` parameter in `AwesomeLoggerConfig` for controlling log replacement behavior
- ⚙️ **Runtime Configuration** - All logger settings can now be modified at runtime through the settings modal
- 📊 **Dynamic Max Log Entries** - Real-time adjustment of maximum log entries limit
- 🎨 **Console Output Toggles** - Runtime toggles for file paths, emojis, and colors in console output
- 📈 **Current Stats Display** - Shows current number of stored logs in settings modal

### Changed
- 🚀 **Improved UX** - Moved configuration from inline UI to dedicated settings modal for cleaner interface
- 📱 **Better Mobile Experience** - Settings modal handles keyboard and screen sizes gracefully
- 🎯 **Enhanced Developer Experience** - Immediate feedback on configuration changes

### Technical
- 🏗️ **Modal Architecture** - Implemented `StatefulBuilder` for proper state management in bottom sheet
- 📱 **Keyboard Handling** - Proper keyboard dismissal and viewport adjustments
- 🎨 **Theme Integration** - Full Material 3 theming support in settings modal

## [2.0.0] (2025-10-31)
- removed bloc dependency

## [1.2.3] (2024-10-27)
- fixes to support older flutter versions

## [1.2.2] (2024-10-27)

### Removed
- 🗑️ **Shake Package Dependency** - Removed shake package (^3.0.0) from dependencies
- 🤳 **Shake-to-Toggle Functionality** - Removed shake-to-show/hide floating button feature
- 🤳 **Shake-to-Enable Functionality** - Removed shake-to-enable logger when disabled feature
- ⚙️ **Shake Configuration Options** - Removed `enableShakeToShowHideFloatingButton`, `enableShakeToEnableLogger`, and `shakeSensitivity` from `FloatingLoggerConfig`

### Changed
- 📖 **Updated Documentation** - Removed all shake-related references from README.md and example documentation
- 🧹 **Code Cleanup** - Simplified floating logger configuration without shake-related parameters
- 📱 **Example App** - Updated example app to use simplified configuration without shake features

### Technical
- 🏗️ **Reduced Dependencies** - Smaller package footprint by removing shake dependency
- 🎯 **Simplified Configuration** - Cleaner API surface without shake-related configuration options
- 📦 **Package Size Optimization** - Reduced overall package size and complexity

## [1.2.1] (2024-10-23)
- updated README.md with new screenshots

## [1.2.0] (2024-10-23)

### 🎉 Major UI Overhaul - Unified Logger Experience

This release introduces a completely redesigned logging experience with a unified interface that combines both general and API logs in one seamless view.

### Added
- 🎯 **Unified Logger Interface** - New `AwesomeLoggerHistoryPage` combines general and API logs in chronological order
- 🔍 **Advanced Filtering System** - Expandable filter sections with smart sub-filters for logger levels and API methods
- 📊 **Intelligent Statistics** - Real-time statistics with clickable filtering capabilities
- 🎨 **Enhanced Visual Design** - Modern card-based layout with improved readability and navigation
- ⚡ **Smart Filter Management** - Collapsible filter sections with active filter indicators
- 🔄 **Improved Sorting** - Better sort toggle with visual feedback and intuitive controls

### Changed
- 🚀 **Simplified API** - Removed separate tab-based UI in favor of unified chronological view
- 📱 **Better Mobile Experience** - Optimized layout for all screen sizes with responsive design
- 🎯 **Streamlined Navigation** - Single entry point for all logging functionality
- 📖 **Updated Documentation** - README and examples now reflect the new unified approach

### Removed
- ⚠️ **Breaking Change**: Removed `LoggerHistoryPage` - use `AwesomeLoggerHistoryPage` instead
- ⚠️ **Breaking Change**: Removed separate `ApiLogsTab` and `GeneralLogsTab` widgets
- 🧹 **Code Cleanup** - Removed unused filter chip components and redundant UI files

### Fixed
- 🔧 **Flutter Analyze Issues** - Fixed all deprecated `withOpacity` usage, replaced with `withValues`
- 🐛 **Unused Variable Warnings** - Removed unused local variables in statistics calculation
- 📝 **Code Style Issues** - Added proper curly braces and removed unnecessary `this.` qualifiers

### Technical
- 🏗️ **Unified Architecture** - Single page handles all log types with smart filtering
- 📊 **Performance Improvements** - More efficient log rendering and filtering
- 🎯 **Better State Management** - Improved filter state handling and UI updates
- 🧪 **Enhanced Testing** - All tests pass with zero analysis issues

### Migration Guide
```dart
// Old way (no longer available)
Navigator.push(context, MaterialPageRoute(
  builder: (context) => const LoggerHistoryPage(),
));

// New way (recommended)
Navigator.push(context, MaterialPageRoute(
  builder: (context) => const AwesomeLoggerHistoryPage(),
));
```

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