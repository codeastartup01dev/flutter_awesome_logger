import 'dart:async';

import 'package:flutter/material.dart';

import '../api_logger/api_log_entry.dart';
import '../api_logger/api_logger_service.dart';
import '../core/flutter_awesome_logger.dart';
import '../ui/logger_history_page.dart';
import 'floating_logger_config.dart';
import 'floating_logger_manager.dart';

/// Advanced floating logger with real-time stats and preferences
class AwesomeFloatingLogger extends StatefulWidget {
  /// Child widget to wrap
  final Widget child;

  /// Whether the floating logger is enabled
  final bool enabled;

  /// Configuration for the floating logger
  final FloatingLoggerConfig config;

  /// Navigator key to use for navigation (optional)
  /// If not provided, will try to find navigator from context
  final GlobalKey<NavigatorState>? navigatorKey;

  const AwesomeFloatingLogger({
    super.key,
    required this.child,
    this.enabled = true,
    this.config = const FloatingLoggerConfig(),
    this.navigatorKey,
  });

  @override
  State<AwesomeFloatingLogger> createState() => _AwesomeFloatingLoggerState();
}

class _AwesomeFloatingLoggerState extends State<AwesomeFloatingLogger> {
  bool _isVisible = true;
  Offset _position = const Offset(20, 100);
  Timer? _statsTimer;
  int _generalLogs = 0;
  int _apiLogs = 0;
  int _apiErrors = 0;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _startStatsTimer();

    // Listen to global visibility changes
    FloatingLoggerManager.visibilityNotifier.addListener(_onVisibilityChanged);
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
    final logs = FlutterAwesomeLogger.getLogs();
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
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only show if enabled and visible
    if (!widget.enabled || !_isVisible) {
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
    return Container(
      width: widget.config.size,
      height: widget.config.size,
      decoration: BoxDecoration(
        color: _apiErrors > 0 ? Colors.red : widget.config.backgroundColor,
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
                widget.config.icon,
                color: Colors.white,
                size: widget.config.size * 0.4,
              ),
            ),

            // General logs badge (top-left)
            if (widget.config.showCount && _generalLogs > 0)
              Positioned(
                left: 0,
                top: 0,
                child: _buildBadge(_generalLogs.toString(), Colors.grey[600]!),
              ),

            // API logs badge (top-right)
            if (widget.config.showCount && _apiLogs > 0)
              Positioned(
                right: 0,
                top: 0,
                child: _buildBadge(
                  _apiLogs.toString(),
                  _apiErrors > 0 ? Colors.red : Colors.green,
                ),
              ),

            // API errors badge (bottom-right) - only if there are errors
            if (widget.config.showCount && _apiErrors > 0)
              Positioned(
                right: 2,
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
    debugPrint('💡 SOLUTION: Use one of these approaches:');
    debugPrint('');
    debugPrint('🎯 APPROACH 1 (Recommended): Wrap individual pages');
    debugPrint('class MyApp extends StatelessWidget {');
    debugPrint('  @override');
    debugPrint('  Widget build(BuildContext context) {');
    debugPrint('    return MaterialApp(');
    debugPrint('      home: AwesomeFloatingLogger(');
    debugPrint('        child: const HomePage(), // ← Wrap the page');
    debugPrint('      ),');
    debugPrint('    );');
    debugPrint('  }');
    debugPrint('}');
    debugPrint('');
    debugPrint('🔑 APPROACH 2: Use Navigator Key (if wrapping MaterialApp)');
    debugPrint('class MyApp extends StatelessWidget {');
    debugPrint('  @override');
    debugPrint('  Widget build(BuildContext context) {');
    debugPrint('    final navigatorKey = GlobalKey<NavigatorState>();');
    debugPrint('    return AwesomeFloatingLogger(');
    debugPrint('      navigatorKey: navigatorKey, // ← Add this');
    debugPrint('      child: MaterialApp(');
    debugPrint('        navigatorKey: navigatorKey, // ← And this');
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
                  FlutterAwesomeLogger.clearLogs();
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

/// Simple floating logger button widget for basic usage
class SimpleFloatingLogger extends StatefulWidget {
  /// Child widget to wrap
  final Widget child;

  /// Whether the floating logger is enabled
  final bool enabled;

  /// Background color of the button
  final Color backgroundColor;

  /// Icon for the button
  final IconData icon;

  /// Size of the button
  final double size;

  /// Tooltip text
  final String? tooltip;

  /// Navigator key to use for navigation (optional)
  /// If not provided, will try to find navigator from context
  final GlobalKey<NavigatorState>? navigatorKey;

  const SimpleFloatingLogger({
    super.key,
    required this.child,
    this.enabled = true,
    this.backgroundColor = Colors.blue,
    this.icon = Icons.bug_report,
    this.size = 56.0,
    this.tooltip,
    this.navigatorKey,
  });

  @override
  State<SimpleFloatingLogger> createState() => _SimpleFloatingLoggerState();
}

class _SimpleFloatingLoggerState extends State<SimpleFloatingLogger> {
  Offset _position = const Offset(20, 100);
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          Positioned(
            left: _position.dx,
            top: _position.dy,
            child: _buildSimpleButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleButton(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => _isDragging = false,
      onPanUpdate: (details) {
        setState(() {
          _isDragging = true;
          _position = Offset(
            (_position.dx + details.delta.dx).clamp(
              0.0,
              MediaQuery.of(context).size.width - widget.size,
            ),
            (_position.dy + details.delta.dy).clamp(
              0.0,
              MediaQuery.of(context).size.height - widget.size - 100,
            ),
          );
        });
      },
      onPanEnd: (_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_isDragging && mounted) {
            _snapToEdge();
          }
        });
      },
      onTap: () {
        if (!_isDragging) {
          _openLogger(context);
        }
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.size / 2),
            onTap: () => _openLogger(context),
            child: Tooltip(
              message: widget.tooltip ?? 'Open Logger',
              child: Icon(
                widget.icon,
                color: Colors.white,
                size: widget.size * 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _snapToEdge([BuildContext? context]) {
    final screenWidth = context != null 
        ? MediaQuery.of(context).size.width
        : MediaQuery.of(this.context).size.width;

    setState(() {
      if (_position.dx < screenWidth / 2) {
        _position = Offset(20, _position.dy);
      } else {
        _position = Offset(screenWidth - widget.size - 20, _position.dy);
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
        MaterialPageRoute(builder: (context) => const LoggerHistoryPage()),
      );
    } catch (e) {
      // Push failed - provide helpful guidance
      _showNavigatorContextError();
    }
  }

  /// Shows helpful error message and solution when Navigator context issues occur
  void _showNavigatorContextError() {
    debugPrint('');
    debugPrint('🚨 SimpleFloatingLogger Navigation Error 🚨');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('❌ Could not find Navigator context for floating logger.');
    debugPrint('');
    debugPrint('💡 SOLUTION: Use one of these approaches:');
    debugPrint('');
    debugPrint('🎯 APPROACH 1 (Recommended): Wrap individual pages');
    debugPrint('class MyApp extends StatelessWidget {');
    debugPrint('  @override');
    debugPrint('  Widget build(BuildContext context) {');
    debugPrint('    return MaterialApp(');
    debugPrint('      home: SimpleFloatingLogger(');
    debugPrint('        child: const HomePage(), // ← Wrap the page');
    debugPrint('      ),');
    debugPrint('    );');
    debugPrint('  }');
    debugPrint('}');
    debugPrint('');
    debugPrint('🔑 APPROACH 2: Use Navigator Key (if wrapping MaterialApp)');
    debugPrint('class MyApp extends StatelessWidget {');
    debugPrint('  @override');
    debugPrint('  Widget build(BuildContext context) {');
    debugPrint('    final navigatorKey = GlobalKey<NavigatorState>();');
    debugPrint('    return SimpleFloatingLogger(');
    debugPrint('      navigatorKey: navigatorKey, // ← Add this');
    debugPrint('      child: MaterialApp(');
    debugPrint('        navigatorKey: navigatorKey, // ← And this');
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
      debugPrint('SimpleFloatingLogger: Logger is already open!');
    }
  }
}
