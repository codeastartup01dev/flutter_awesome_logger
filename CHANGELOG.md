# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2024-10-13

### Added
- ✨ **Auto-configuration support** - New optional parameters in `FlutterAwesomeLogger` widget
- 🔧 **Optional logger configuration** - `loggerConfig` parameter for automatic logger setup
- 🎛️ **Optional auto-initialization** - `autoInitialize` parameter (default: true)
- 📚 **Improved developer experience** - No manual setup required for basic usage
- 🛠️ **Backward compatibility** - Manual configuration still supported
- 📝 **Enhanced documentation** - Updated README with auto-configuration examples

### Changed
- 🔄 **Example app** - Now demonstrates auto-configuration approach
- 📖 **README** - Added both auto and manual configuration options
- 🏗️ **Architecture** - Cleaner separation of concerns

### Features
- 🎯 **Simplified setup** - Just pass config to widget, no main() setup needed
- 🔄 **Flexible configuration** - Choose auto or manual setup based on needs
- 💡 **Better UX** - Configuration where you use it (in the widget)
- ⚡ **Zero breaking changes** - Fully backward compatible

## [0.1.0] - 2024-10-13

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