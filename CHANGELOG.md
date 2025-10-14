# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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