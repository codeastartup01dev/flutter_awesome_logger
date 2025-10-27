import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shake/shake.dart';

import '../api_logger/api_log_entry.dart';
import '../api_logger/api_logger_service.dart';
import '../bloc_logger/awesome_bloc_observer.dart';
import '../core/log_entry.dart';
import '../core/logging_using_logger.dart';
import '../ui/awesome_logger_history_page.dart';
import 'floating_logger_config.dart';
import 'floating_logger_manager.dart';

/// Advanced floating logger with real-time stats and preferences
class FlutterAwesomeLogger extends StatefulWidget {
  // ============================================================================
  // LOGGER INSTANCE
  // ============================================================================

  /// Get the global logger instance
  ///
  /// Usage:
  /// ```dart
  /// final logger = FlutterAwesomeLogger.loggingUsingLogger;
  /// logger.d('Debug message');
  /// logger.i('Info message');
  /// logger.w('Warning message');
  /// logger.e('Error message');
  /// ```
  static LoggingUsingLogger get loggingUsingLogger => logger;

  // ============================================================================
  // LOGGER CONFIGURATION
  // ============================================================================

  /// Configure the logger behavior
  ///
  /// Usage:
  /// ```dart
  /// FlutterAwesomeLogger.configure(AwesomeLoggerConfig(
  ///   maxLogEntries: 500,
  ///   showFilePaths: true,
  ///   showEmojis: true,
  ///   useColors: true,
  /// ));
  /// ```
  static void configure(AwesomeLoggerConfig loggerConfig) {
    LoggingUsingLogger.configure(loggerConfig);
  }

  /// Get current logger configuration
  static AwesomeLoggerConfig getLoggerConfig() => LoggingUsingLogger.config;

  // ============================================================================
  // LOGGING CONTROL
  // ============================================================================

  /// Enable or disable log storage globally
  ///
  /// Usage:
  /// ```dart
  /// FlutterAwesomeLogger.setStorageEnabled(false); // Disable storage
  /// FlutterAwesomeLogger.setStorageEnabled(true);  // Enable storage
  /// ```
  static void setStorageEnabled(bool enabled) {
    LoggingUsingLogger.setStorageEnabled(enabled);
  }

  /// Pause or resume all logging (both console and storage)
  ///
  /// Usage:
  /// ```dart
  /// FlutterAwesomeLogger.setPauseLogging(true);  // Pause logging
  /// FlutterAwesomeLogger.setPauseLogging(false); // Resume logging
  /// ```
  static void setPauseLogging(bool paused) {
    LoggingUsingLogger.setPauseLogging(paused);
  }

  /// Get current pause logging state
  static bool get isPaused => LoggingUsingLogger.isPaused;

  // ============================================================================
  // LOG MANAGEMENT
  // ============================================================================

  /// Clear all stored logs from memory
  static void clearLogs() {
    LoggingUsingLogger.clearLogs();
  }

  /// Get all stored logs
  static List<LogEntry> getLogs() {
    return LoggingUsingLogger.getLogs();
  }

  /// Get logs filtered by level
  ///
  /// Usage:
  /// ```dart
  /// final errorLogs = FlutterAwesomeLogger.getLogsByLevel('ERROR');
  /// final debugLogs = FlutterAwesomeLogger.getLogsByLevel('DEBUG');
  /// ```
  static List<LogEntry> getLogsByLevel(String level) {
    return LoggingUsingLogger.getLogsByLevel(level);
  }

  /// Get recent logs within specified duration
  ///
  /// Usage:
  /// ```dart
  /// final recentLogs = FlutterAwesomeLogger.getRecentLogs(
  ///   duration: Duration(minutes: 10),
  /// );
  /// ```
  static List<LogEntry> getRecentLogs({
    Duration duration = const Duration(minutes: 5),
  }) {
    return LoggingUsingLogger.getRecentLogs(duration: duration);
  }

  /// Get log count by level
  static Map<String, int> getLogCountByLevel() {
    return LoggingUsingLogger.getLogCountByLevel();
  }

  /// Get logs from specific file
  static List<LogEntry> getLogsFromFile(String filePath) {
    return LoggingUsingLogger.getLogsFromFile(filePath);
  }

  /// Export logs as formatted text
  static String exportLogs({List<LogEntry>? logs}) {
    return LoggingUsingLogger.exportLogs(logs: logs);
  }

  // ============================================================================
  // FLOATING LOGGER VISIBILITY MANAGEMENT
  // ============================================================================

  /// Check if floating logger is currently visible
  ///
  /// Usage:
  /// ```dart
  /// bool visible = FlutterAwesomeLogger.isVisible();
  /// ```
  static bool isVisible() {
    return FloatingLoggerManager.isVisible();
  }

  /// Set floating logger visibility
  ///
  /// Usage:
  /// ```dart
  /// FlutterAwesomeLogger.setVisible(false); // Hide
  /// FlutterAwesomeLogger.setVisible(true);  // Show
  /// ```
  static void setVisible(bool visible) {
    FloatingLoggerManager.setVisible(visible);
  }

  /// Toggle floating logger visibility
  ///
  /// Usage:
  /// ```dart
  /// FlutterAwesomeLogger.toggleVisibility();
  /// ```
  static void toggleVisibility() {
    FloatingLoggerManager.toggle();
  }

  /// Get the visibility notifier for listening to changes
  ///
  /// Usage:
  /// ```dart
  /// FlutterAwesomeLogger.visibilityNotifier.addListener(() {
  ///   print('Visibility changed: ${FlutterAwesomeLogger.visibilityNotifier.value}');
  /// });
  /// ```
  static ValueNotifier<bool> get visibilityNotifier =>
      FloatingLoggerManager.visibilityNotifier;

  /// Get saved position of floating logger
  static Offset? getSavedPosition() {
    return FloatingLoggerManager.getSavedPosition();
  }

  /// Save position of floating logger
  static void savePosition(Offset position) {
    FloatingLoggerManager.savePosition(position);
  }

  /// Clear all saved preferences
  static void clearPreferences() {
    FloatingLoggerManager.clearPreferences();
  }

  /// Initialize the logger manager
  static void initialize() {
    FloatingLoggerManager.initialize();
  }

  // ============================================================================
  // API LOGGER MANAGEMENT
  // ============================================================================

  /// Clear all API logs
  static void clearApiLogs() {
    ApiLoggerService.clearApiLogs();
  }

  /// Get all API logs
  static List<ApiLogEntry> getApiLogs() {
    return ApiLoggerService.getApiLogs();
  }

  /// Get API logs filtered by type
  ///
  /// Usage:
  /// ```dart
  /// final successLogs = FlutterAwesomeLogger.getApiLogsByType(ApiLogType.success);
  /// final errorLogs = FlutterAwesomeLogger.getApiLogsByType(ApiLogType.serverError);
  /// ```
  static List<ApiLogEntry> getApiLogsByType(ApiLogType type) {
    return ApiLoggerService.getApiLogsByType(type);
  }

  // ============================================================================
  // WIDGET PROPERTIES
  // ============================================================================

  /// Child widget to wrap
  final Widget child;

  /// Whether the floating logger is enabled and logs are stored.
  /// Can be a Future that resolves to a boolean for conditional enabling.
  final FutureOr<bool> enabled;

  /// Configuration for the floating logger
  final FloatingLoggerConfig config;

  /// Navigator key to use for navigation (optional)
  /// If not provided, will try to find navigator from context
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Optional logger configuration - if provided, will auto-configure the logger
  /// This eliminates the need to call LoggingUsingLogger.configure() manually
  final AwesomeLoggerConfig? loggerConfig;

  /// Optional BLoC observer configuration - if provided, will auto-configure Bloc.observer
  /// This eliminates the need to set Bloc.observer manually in main()
  final AwesomeBlocObserverConfig? blocObserverConfig;

  const FlutterAwesomeLogger({
    super.key,
    required this.child,
    this.enabled = true,
    this.config = const FloatingLoggerConfig(),
    this.navigatorKey,
    this.loggerConfig,
    this.blocObserverConfig,
  });

  @override
  State<FlutterAwesomeLogger> createState() => _FlutterAwesomeLoggerState();
}

class _FlutterAwesomeLoggerState extends State<FlutterAwesomeLogger> {
  bool _isVisible = true;
  Offset _position = const Offset(20, 100);
  Timer? _statsTimer;
  int _generalLogs = 0;
  int _apiLogs = 0;
  int _apiErrors = 0;
  bool _isLoggingPaused = false;
  bool? _isEnabled; // null = waiting for future, true/false = resolved
  Future<bool>? _enabledFuture;
  ShakeDetector? _shakeDetector;
  ShakeDetector? _enableShakeDetector; // Separate detector for enabling logger
  bool _showNavigationError = false; // Show navigation error message in widget

  @override
  void initState() {
    super.initState();

    // Auto-configure logger if config is provided
    if (widget.loggerConfig != null) {
      LoggingUsingLogger.configure(widget.loggerConfig!);
    }

    // Auto-configure BLoC observer if config is provided
    if (widget.blocObserverConfig != null) {
      _configureBlocObserver(widget.blocObserverConfig!);
    }

    // Handle enabled parameter (FutureOr<bool>)
    _resolveEnabledState();

    _loadPreferences();

    // Listen to global visibility changes
    FloatingLoggerManager.visibilityNotifier.addListener(_onVisibilityChanged);
  }

  @override
  void didUpdateWidget(FlutterAwesomeLogger oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-resolve enabled state if widget changed
    if (!identical(oldWidget.enabled, widget.enabled)) {
      _resolveEnabledState();
    }
  }

  /// Resolves the enabled state from FutureOr&lt;bool&gt; to bool
  void _resolveEnabledState() {
    final enabled = widget.enabled;

    if (enabled is bool) {
      // Synchronous case
      _setEnabledState(enabled);
    } else {
      // Asynchronous case
      _enabledFuture = enabled;
      enabled.then((value) {
        if (mounted && _enabledFuture == enabled) {
          setState(() {
            _setEnabledState(value);
          });
          if (value) {
            debugPrint(
              'FlutterAwesomeLogger: Logger enabled via Future resolution',
            );
          }
        }
      }).catchError((error) {
        // Default to false on error
        if (mounted && _enabledFuture == enabled) {
          setState(() {
            _setEnabledState(false);
          });
        }
        debugPrint('Error resolving logger enabled state: $error');
      });
    }
  }

  /// Configures the BLoC observer with proper handling of existing observers
  void _configureBlocObserver(AwesomeBlocObserverConfig config) {
    final currentObserver = Bloc.observer;

    // Check if we already have an AwesomeBlocObserver configured
    if (currentObserver is AwesomeBlocObserver) {
      debugPrint(
        'FlutterAwesomeLogger: AwesomeBlocObserver already configured, skipping auto-configuration',
      );
      return;
    }

    // Warn if there's already a custom observer
    if (currentObserver.runtimeType != BlocObserver) {
      debugPrint(
        'FlutterAwesomeLogger: Warning - Existing BlocObserver detected (${currentObserver.runtimeType}). '
        'Auto-configuring AwesomeBlocObserver will override it. '
        'Consider removing blocObserverConfig from FlutterAwesomeLogger if you want to keep your custom observer.',
      );
    }

    // Configure the AwesomeBlocObserver
    Bloc.observer = AwesomeBlocObserver(config: config);

    debugPrint(
      'FlutterAwesomeLogger: AwesomeBlocObserver configured automatically',
    );
  }

  /// Sets the enabled state and updates dependent services
  void _setEnabledState(bool enabled) {
    _isEnabled = enabled;
    LoggingUsingLogger.setStorageEnabled(enabled);

    // Start stats timer if enabled
    if (enabled) {
      _startStatsTimer();
      _initializeShakeDetector();
      _disposeEnableShakeDetector(); // Stop enable detector when logger is active
    } else {
      _statsTimer?.cancel();
      _statsTimer = null;
      _disposeShakeDetector();
      _initializeEnableShakeDetector(); // Start enable detector when logger is disabled
    }
  }

  /// Initialize shake detector if enabled
  void _initializeShakeDetector() {
    if (!widget.config.enableShakeToShowHideFloatingButton) return;

    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: (_) {
        if (mounted) {
          _toggleLoggerVisibility();
        }
      },
      minimumShakeCount: 1,
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 3000,
      shakeThresholdGravity: widget.config.shakeSensitivity.toDouble(),
    );
  }

  /// Dispose shake detector
  void _disposeShakeDetector() {
    _shakeDetector?.stopListening();
    _shakeDetector = null;
  }

  /// Initialize shake detector for enabling logger when disabled
  void _initializeEnableShakeDetector() {
    if (!widget.config.enableShakeToEnableLogger) return;

    _enableShakeDetector = ShakeDetector.autoStart(
      onPhoneShake: (_) {
        if (mounted) {
          _enableLogger();
        }
      },
      minimumShakeCount: 1,
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 3000,
      shakeThresholdGravity: widget.config.shakeSensitivity.toDouble(),
    );
  }

  /// Dispose enable shake detector
  void _disposeEnableShakeDetector() {
    _enableShakeDetector?.stopListening();
    _enableShakeDetector = null;
  }

  /// Enable logger via shake when disabled
  void _enableLogger() {
    setState(() {
      _setEnabledState(true);
    });

    debugPrint('FlutterAwesomeLogger: Shake detected - enabling logger');

    // Show a brief message to user
    if (mounted) {
      // You could show a snackbar or toast here if needed
      debugPrint('Logger enabled via shake gesture');
    }
  }

  /// Toggle logger visibility with haptic feedback
  void _toggleLoggerVisibility() {
    FloatingLoggerManager.toggle();

    // Provide haptic feedback
    if (mounted) {
      // Light haptic feedback to confirm shake was detected
      // Note: HapticFeedback requires additional import, keeping it simple for now
      debugPrint('FlutterAwesomeLogger: Shake detected - toggling visibility');
    }
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    _disposeShakeDetector();
    _disposeEnableShakeDetector();
    FloatingLoggerManager.visibilityNotifier.removeListener(
      _onVisibilityChanged,
    );
    super.dispose();
  }

  void _onVisibilityChanged() {
    final newVisibility = FloatingLoggerManager.visibilityNotifier.value;
    if (mounted) {
      setState(() {
        _isVisible = newVisibility;
      });
    }
  }

  void _loadPreferences() {
    final visible = FloatingLoggerManager.isVisible();
    final savedPosition = FloatingLoggerManager.getSavedPosition();

    // Update ValueNotifier to match stored preference
    FloatingLoggerManager.visibilityNotifier.value = visible;

    setState(() {
      _isVisible = visible;
      _position = savedPosition ??
          widget.config.initialPosition ??
          const Offset(20, 100);
    });
  }

  void _savePosition(Offset position) {
    FloatingLoggerManager.savePosition(position);
  }

  void _startStatsTimer() {
    _updateStats();
    _statsTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) _updateStats();
    });
  }

  void _updateStats() {
    final logs = LoggingUsingLogger.getLogs();
    final apiLogsData = ApiLoggerService.getApiLogs();
    final errors = apiLogsData
        .where(
          (log) =>
              log.type == ApiLogType.clientError ||
              log.type == ApiLogType.serverError ||
              log.type == ApiLogType.networkError,
        )
        .length;

    setState(() {
      _generalLogs = logs.length;
      _apiLogs = apiLogsData.length;
      _apiErrors = errors;
      _isLoggingPaused = LoggingUsingLogger.isPaused;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only show if enabled (default to false while resolving future) and visible
    final isEnabled = _isEnabled ?? false;
    if (!isEnabled || !_isVisible) {
      return widget.child;
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          // Main app content
          widget.child,

          // Floating logger widget
          Positioned(
            left: _position.dx,
            top: _position.dy,
            child: _buildFloatingWidget(context),
          ),

          // Navigation error message (when all other methods fail)
          if (_showNavigationError)
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: _buildNavigationErrorWidget(),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingWidget(BuildContext context) {
    Color backgroundColor;
    if (_isLoggingPaused) {
      backgroundColor = Colors.grey;
    } else if (_apiErrors > 0) {
      backgroundColor = Colors.red;
    } else {
      backgroundColor = widget.config.backgroundColor;
    }

    return Container(
      width: widget.config.size,
      height: widget.config.size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(widget.config.size / 2),
        border: widget.config.backgroundColor != Colors.transparent
            ? null
            : Border.all(color: Colors.grey, width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0x33000000), // black with 20% opacity
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openLogger(context),
        onPanUpdate: widget.config.enableGestures
            ? (details) {
                setState(() {
                  _position = Offset(
                    (_position.dx + details.delta.dx).clamp(
                      0.0,
                      MediaQuery.of(context).size.width - widget.config.size,
                    ),
                    (_position.dy + details.delta.dy).clamp(
                      0.0,
                      MediaQuery.of(context).size.height - 100,
                    ),
                  );
                });
              }
            : null,
        onPanEnd: widget.config.enableGestures
            ? (_) {
                _savePosition(_position);
                if (widget.config.autoSnapToEdges) {
                  _snapToEdge(context);
                }
              }
            : null,
        onLongPress: () => _showOptionsMenu(),
        child: Stack(
          children: [
            // Center icon
            Center(
              child: Icon(
                _isLoggingPaused ? Icons.pause : widget.config.icon,
                color: Colors.white,
                size: widget.config.size * 0.4,
              ),
            ),
            // API logs badge (top-left)
            if (widget.config.showCount && _apiLogs > 0)
              Positioned(
                left: 0,
                top: 0,
                child: _buildBadge(
                  _apiLogs.toString(),
                  _apiErrors > 0 ? Colors.red : Colors.green,
                ),
              ),

            // General logs badge (top-right)
            if (widget.config.showCount && _generalLogs > 0)
              Positioned(
                right: 0,
                top: 0,
                child: _buildBadge(_generalLogs.toString(), Colors.grey[600]!),
              ),

            // API errors badge (bottom-left) - only if there are errors
            if (widget.config.showCount && _apiErrors > 0)
              Positioned(
                left: 2,
                bottom: 0,
                child: _buildBadge('⚠', Colors.orange, small: true),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color, {bool small = false}) {
    return Container(
      padding: EdgeInsets.all(small ? 2 : 3),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
      constraints: BoxConstraints(
        minWidth: small ? 14 : 18,
        minHeight: small ? 14 : 18,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: small ? 8 : 9,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _snapToEdge(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    setState(() {
      if (_position.dx < screenWidth / 2) {
        _position = Offset(widget.config.edgeMargin, _position.dy);
      } else {
        _position = Offset(
          screenWidth - widget.config.size - widget.config.edgeMargin,
          _position.dy,
        );
      }
    });
  }

  /// Builds the navigation error widget shown directly in the UI
  Widget _buildNavigationErrorWidget() {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Navigation Error',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showNavigationError = false;
                    });
                  },
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '❌ Could not find Navigator context for floating logger.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '🔑 Solution: Add navigatorKey to both MaterialApp and FlutterAwesomeLogger',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Text(
                '''final navigatorKey = GlobalKey<NavigatorState>();

return MaterialApp(
  navigatorKey: navigatorKey, // ← Add this
  home: FlutterAwesomeLogger(
    navigatorKey: navigatorKey, // ← Add this
    child: YourHomePage(),
  ),
);''',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showNavigationError = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Got it!'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  void _openLogger(BuildContext context) {
    // Check if logger is already open
    if (AwesomeLoggerHistoryPage.isLoggerOpen) {
      // Show message that logger is already open
      _showLoggerAlreadyOpenMessage(context);
      return;
    }

    // Try to use provided navigator key first, then fallback to context
    NavigatorState? navigator;

    // First try the provided navigatorKey
    if (widget.navigatorKey != null) {
      navigator = widget.navigatorKey!.currentState;
    }

    // If navigatorKey is null or its currentState is null, try context-based navigation
    if (navigator == null) {
      try {
        navigator = Navigator.of(context);
      } catch (e) {
        // Navigation failed - provide helpful guidance
        _showNavigatorContextError();
        return;
      }
    }

    try {
      navigator.push(
        MaterialPageRoute(
          builder: (context) => AwesomeLoggerHistoryPage(
            showFilePaths: widget.config.showFilePaths,
            defaultMainFilter: widget.loggerConfig?.defaultMainFilter,
          ),
        ),
      );
    } catch (e) {
      // Push failed - provide helpful guidance
      _showNavigatorContextError();
    }
  }

  /// Shows helpful error message and solution when Navigator context issues occur
  void _showNavigatorContextError() {
    // Print to console for debugging
    debugPrint('');
    debugPrint('🚨 AwesomeFloatingLogger Navigation Error 🚨');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('❌ Could not find Navigator context for floating logger.');
    debugPrint('');
    debugPrint('🔑Use Navigator Key:');
    debugPrint('class MyApp extends StatelessWidget {');
    debugPrint('  @override');
    debugPrint('  Widget build(BuildContext context) {');
    debugPrint(
      '    final navigatorKey = GlobalKey<NavigatorState>(); // or use call your global navigator key',
    );
    debugPrint('    return FlutterAwesomeLogger(');
    debugPrint('      navigatorKey: navigatorKey, // ← Add this');
    debugPrint('      child: MaterialApp(');
    debugPrint('        home: const HomePage(),');
    debugPrint('      ),');
    debugPrint('    );');
    debugPrint('  }');
    debugPrint('}');
    debugPrint('');
    debugPrint('📚 More info: https://pub.dev/packages/awesome_flutter_logger');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('');

    // Show dialog to user
    _showNavigatorErrorDialog();
  }

  /// Shows a user-friendly error message with navigation information
  void _showNavigatorErrorDialog() {
    // Show error message directly in the widget
    setState(() {
      _showNavigationError = true;
    });
  }

  /// Shows a snackbar message when logger is already open
  void _showLoggerAlreadyOpenMessage(BuildContext context) {
    // Get the current BuildContext or use navigator key
    BuildContext? dialogContext;

    if (widget.navigatorKey?.currentContext != null) {
      dialogContext = widget.navigatorKey!.currentContext!;
    } else {
      dialogContext = context;
    }

    try {
      // Schedule snackbar for next frame to avoid async gap
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && dialogContext != null) {
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            const SnackBar(
              content: Text('Logger is already open!'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    } catch (e) {
      // If snackbar fails, show debug message
      debugPrint('AwesomeFloatingLogger: Logger is already open!');
    }
  }

  void _showOptionsMenu() {
    // Get the current BuildContext or use navigator key
    BuildContext? dialogContext;

    if (widget.navigatorKey?.currentContext != null) {
      dialogContext = widget.navigatorKey!.currentContext!;
    } else {
      dialogContext = context;
    }

    try {
      showDialog(
        context: dialogContext,
        builder: (context) => AlertDialog(
          title: const Text('Logger Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  _isLoggingPaused ? Icons.play_arrow : Icons.pause,
                ),
                title: Text(
                  _isLoggingPaused ? 'Resume Logging' : 'Pause Logging',
                ),
                onTap: () {
                  Navigator.pop(context);
                  LoggingUsingLogger.setPauseLogging(!_isLoggingPaused);
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility_off),
                title: const Text('Hide Logger'),
                onTap: () {
                  Navigator.pop(context);
                  FloatingLoggerManager.setVisible(false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.clear_all),
                title: const Text('Clear All Logs'),
                onTap: () {
                  Navigator.pop(context);
                  LoggingUsingLogger.clearLogs();
                  ApiLoggerService.clearApiLogs();
                },
              ),
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('Open Logger'),
                onTap: () {
                  Navigator.pop(context);
                  _openLogger(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Dialog failed - provide helpful guidance
      _showNavigatorContextError();
    }
  }
}
