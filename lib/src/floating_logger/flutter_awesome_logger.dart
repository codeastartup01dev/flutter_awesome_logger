import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../api_logger/api_log_entry.dart';
import '../api_logger/api_logger_service.dart';
import '../core/logging_using_logger.dart';
import '../ui/logger_history_page.dart';
import 'floating_logger_config.dart';
import 'floating_logger_manager.dart';

/// Advanced floating logger with real-time stats and preferences
class FlutterAwesomeLogger extends StatefulWidget {
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

  const FlutterAwesomeLogger({
    super.key,
    required this.child,
    this.enabled = true,
    this.config = const FloatingLoggerConfig(),
    this.navigatorKey,
    this.loggerConfig,
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

  @override
  void initState() {
    super.initState();

    // Auto-configure logger if config is provided
    if (widget.loggerConfig != null) {
      LoggingUsingLogger.configure(widget.loggerConfig!);
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

  /// Resolves the enabled state from FutureOr<bool> to bool
  void _resolveEnabledState() {
    final enabled = widget.enabled;

    if (enabled is bool) {
      // Synchronous case
      _setEnabledState(enabled);
    } else if (enabled is Future<bool>) {
      // Asynchronous case
      _enabledFuture = enabled;
      enabled
          .then((value) {
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
          })
          .catchError((error) {
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

  /// Sets the enabled state and updates dependent services
  void _setEnabledState(bool enabled) {
    _isEnabled = enabled;
    LoggingUsingLogger.setStorageEnabled(enabled);

    // Start stats timer if enabled
    if (enabled) {
      _startStatsTimer();
    } else {
      _statsTimer?.cancel();
      _statsTimer = null;
    }
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
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

  Future<void> _loadPreferences() async {
    final visible = await FloatingLoggerManager.isVisible();
    final savedPosition = await FloatingLoggerManager.getSavedPosition();

    // Update ValueNotifier to match stored preference
    FloatingLoggerManager.visibilityNotifier.value = visible;

    setState(() {
      _isVisible = visible;
      _position =
          savedPosition ??
          widget.config.initialPosition ??
          const Offset(20, 100);
    });
  }

  Future<void> _savePosition(Offset position) async {
    await FloatingLoggerManager.savePosition(position);
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
            color: Colors.black.withValues(alpha: 0.2),
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

  void _openLogger(BuildContext context) {
    // Check if logger is already open
    if (LoggerHistoryPage.isLoggerOpen) {
      // Show message that logger is already open
      _showLoggerAlreadyOpenMessage(context);
      return;
    }

    // Try to use provided navigator key first, then fallback to context
    NavigatorState? navigator;

    if (widget.navigatorKey?.currentState != null) {
      navigator = widget.navigatorKey!.currentState!;
    } else {
      // Try to find navigator from context
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
          builder: (context) =>
              LoggerHistoryPage(showFilePaths: widget.config.showFilePaths),
        ),
      );
    } catch (e) {
      // Push failed - provide helpful guidance
      _showNavigatorContextError();
    }
  }

  /// Shows helpful error message and solution when Navigator context issues occur
  void _showNavigatorContextError() {
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
