import 'dart:collection';

import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

import 'log_entry.dart';
import 'unified_log_types.dart';

/// Global logger instance - use this for logging throughout your app
final logger = LoggingUsingLogger();

/// Configuration for AwesomeLogger behavior
class AwesomeLoggerConfig {
  /// Maximum number of log entries to keep in memory
  final int maxLogEntries;

  /// Whether to show file paths in console output
  final bool showFilePaths;

  /// Whether to show emojis in console output
  final bool showEmojis;

  /// Whether to use colors in console output
  final bool useColors;

  /// Number of stack trace lines to show (0 = none)
  final int stackTraceLines;

  /// Whether to enable circular buffer behavior.
  ///
  /// When true (default): oldest logs are replaced with new ones when maxLogEntries is reached.
  /// When false: logging stops when maxLogEntries is reached.
  final bool enableCircularBuffer;

  /// Default main filter to be selected when opening the logger history page
  /// Options: LogSource.general (Logger Logs), LogSource.api (API Logs), LogSource.flutter (Flutter Error Logs)
  /// If null, no main filter will be pre-selected (shows all logs)
  final LogSource? defaultMainFilter;

  const AwesomeLoggerConfig({
    this.maxLogEntries = 1000,
    this.showFilePaths = true,
    this.showEmojis = true,
    this.useColors = true,
    this.stackTraceLines = 0,
    this.enableCircularBuffer = true,
    this.defaultMainFilter,
  });

  /// Create a copy with updated fields
  AwesomeLoggerConfig copyWith({
    int? maxLogEntries,
    bool? showFilePaths,
    bool? showEmojis,
    bool? useColors,
    int? stackTraceLines,
    bool? enableCircularBuffer,
    LogSource? defaultMainFilter,
  }) {
    return AwesomeLoggerConfig(
      maxLogEntries: maxLogEntries ?? this.maxLogEntries,
      showFilePaths: showFilePaths ?? this.showFilePaths,
      showEmojis: showEmojis ?? this.showEmojis,
      useColors: useColors ?? this.useColors,
      stackTraceLines: stackTraceLines ?? this.stackTraceLines,
      enableCircularBuffer: enableCircularBuffer ?? this.enableCircularBuffer,
      defaultMainFilter: defaultMainFilter ?? this.defaultMainFilter,
    );
  }
}

/// Mixin that provides a pre-scoped logger using the class's runtimeType.
///
/// This is the most convenient way to add class-aware logging to any class.
/// The logger will automatically use the class name as the source.
///
/// Note: The `logger` getter shadows any imported global `logger` variable,
/// so all `logger.d()`, `logger.i()` etc. calls within the class will
/// automatically include the class name as source.
///
/// Example:
/// ```dart
/// import 'package:flutter_awesome_logger/flutter_awesome_logger.dart';
/// import 'my_logger.dart'; // your global logger
///
/// class CubitAppConfig extends Cubit<StateAppConfig> with AwesomeLoggerMixin {
///   CubitAppConfig() : super(const StateAppConfig(config: null)) {
///     logger.d('CubitAppConfig instance created'); // source: 'CubitAppConfig'
///   }
///
///   void loadConfig() {
///     logger.i('Loading config...'); // source: 'CubitAppConfig'
///   }
/// }
/// ```
mixin AwesomeLoggerMixin {
  /// A scoped logger that uses this class's runtimeType as the source.
  ///
  /// This getter shadows any imported global `logger` variable within the class,
  /// so you can use `logger.d()`, `logger.i()` etc. naturally.
  /// All logs will automatically include the class name for easy filtering.
  ScopedLogger get logger => _globalLogger.scoped(runtimeType.toString());
}

/// Internal reference to the global logger for use by the mixin
final _globalLogger = LoggingUsingLogger();

/// A scoped logger that automatically includes a source identifier with every log.
///
/// Use this when you want all logs from a class/component to have the same source.
/// Example:
/// ```dart
/// class MyService {
///   final _logger = logger.scoped('MyService');
///   // Or use runtimeType: late final _logger = logger.scoped(runtimeType.toString());
///
///   void doSomething() {
///     _logger.d('Doing something'); // Logs with source: 'MyService'
///   }
/// }
/// ```
class ScopedLogger {
  final String _source;
  final LoggingUsingLogger _logger;

  ScopedLogger._(this._source, this._logger);

  /// Log debug message with pre-configured source
  void d(String message) => _logger.d(message, source: _source);

  /// Log info message with pre-configured source
  void i(String message) => _logger.i(message, source: _source);

  /// Log warning message with pre-configured source
  void w(String message) => _logger.w(message, source: _source);

  /// Log error message with pre-configured source
  void e(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace, source: _source);

  /// Get the source name for this scoped logger
  String get source => _source;
}

/// Main logger class - handles logging with memory storage and console output
class LoggingUsingLogger {
  static AwesomeLoggerConfig _config = const AwesomeLoggerConfig();
  static Logger? _logger;
  static final Queue<LogEntry> _logHistory = Queue<LogEntry>();
  static bool _storageEnabled = true; // Global flag for log storage
  static bool _pauseLogging = false; // Global flag to pause all logging

  /// Configure the logger behavior
  static void configure(AwesomeLoggerConfig config) {
    _config = config;
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: config.stackTraceLines,
        colors: config.useColors,
        printEmojis: config.showEmojis,
        lineLength: 120,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
    );
  }

  /// Enable or disable log storage globally
  static void setStorageEnabled(bool enabled) {
    _storageEnabled = enabled;
  }

  /// Pause or resume all logging (both console and storage)
  static void setPauseLogging(bool paused) {
    _pauseLogging = paused;
  }

  /// Get current pause logging state
  static bool get isPaused => _pauseLogging;

  /// Get current configuration
  static AwesomeLoggerConfig get config => _config;

  /// Get logger instance (creates with default config if not configured)
  static Logger get _loggerInstance {
    return _logger ??= Logger(
      printer: PrettyPrinter(
        methodCount: _config.stackTraceLines,
        colors: _config.useColors,
        printEmojis: _config.showEmojis,
        lineLength: 120,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
    );
  }

  /// Create a scoped logger with a pre-configured source identifier.
  ///
  /// All logs from the returned [ScopedLogger] will automatically include
  /// the specified source, making it easy to filter logs by class/component.
  ///
  /// Example with manual source:
  /// ```dart
  /// class CubitAppConfig extends Cubit<StateAppConfig> {
  ///   final _logger = logger.scoped('CubitAppConfig');
  ///
  ///   void loadConfig() {
  ///     _logger.d('Loading config...'); // source: 'CubitAppConfig'
  ///   }
  /// }
  /// ```
  ///
  /// Example with runtimeType (recommended for automatic class name):
  /// ```dart
  /// class CubitAppConfig extends Cubit<StateAppConfig> {
  ///   late final _logger = logger.scoped(runtimeType.toString());
  ///
  ///   void loadConfig() {
  ///     _logger.d('Loading config...'); // source: 'CubitAppConfig'
  ///   }
  /// }
  /// ```
  ScopedLogger scoped(String source) => ScopedLogger._(source, this);

  /// Extract file path from stack trace for debugging
  static String _getFilePath() {
    final frames = StackTrace.current.toString().split('\n');
    for (var i = 2; i < frames.length; i++) {
      final frame = frames[i].trim();
      // Skip internal logger files
      if (!frame.contains('awesome_logger.dart') &&
          !frame.contains('log_entry.dart') &&
          !frame.contains('logging_using_logger.dart')) {
        final match = RegExp(r'(.*) \((.+?):(\d+):(\d+)\)').firstMatch(frame);
        if (match != null) {
          final filePath = match.group(2) ?? '';
          final line = match.group(3) ?? '';
          final column = match.group(4) ?? '';

          String relativePath;
          if (filePath.startsWith('package:')) {
            final parts = filePath.split('/');
            relativePath = parts.sublist(1).join('/');
          } else {
            final currentDir = path.current;
            relativePath = path.relative(filePath, from: currentDir);
          }

          // Clean up path to start from lib/ if possible
          final libIndex = relativePath.indexOf('lib/');
          if (libIndex != -1) {
            relativePath = relativePath.substring(libIndex);
          } else if (!relativePath.startsWith('lib/')) {
            relativePath = 'lib/$relativePath';
          }

          return './$relativePath:$line:$column';
        }
      }
    }
    return 'unknown';
  }

  /// Format error with stack trace information
  static String _formatErrorStackTrace(Object error, StackTrace? stackTrace) {
    final traceString = stackTrace?.toString() ?? StackTrace.current.toString();

    final frames = traceString.split('\n');
    final formattedFrames = frames
        .where(
      (frame) =>
          !frame.contains('awesome_logger.dart') &&
          !frame.contains('log_entry.dart') &&
          !frame.contains('logging_using_logger.dart'),
    )
        .map((frame) {
      final match = RegExp(
        r'(?:#\d+\s+)?(\S+)\s+\((.+?):(\d+):(\d+)\)',
      ).firstMatch(frame.trim());
      if (match != null) {
        final method = match.group(1) ?? '';
        String filePath = match.group(2) ?? '';
        final line = match.group(3) ?? '';
        final column = match.group(4) ?? '';

        String relativePath;
        if (filePath.startsWith('package:')) {
          final parts = filePath.split('/');
          relativePath = parts.sublist(1).join('/');
        } else {
          final currentDir = path.current;
          relativePath = path.relative(filePath, from: currentDir);
        }

        // Ensure the path starts from 'lib'
        final libIndex = relativePath.indexOf('lib/');
        if (libIndex != -1) {
          relativePath = relativePath.substring(libIndex);
        } else if (!relativePath.startsWith('lib/')) {
          relativePath = 'lib/$relativePath';
        }

        return '$method (./$relativePath:$line:$column)';
      }
      return frame;
    }).join('\n');

    return '${error.toString()}\n$formattedFrames';
  }

  /// Add log entry to memory storage
  void _addLogEntry(String message, String level,
      {String? stackTrace, String? source}) {
    // Only store logs if storage is enabled
    if (!_storageEnabled) return;

    // If circular buffer is disabled and we're at max capacity, don't add new logs
    if (!_config.enableCircularBuffer &&
        _logHistory.length >= _config.maxLogEntries) {
      return;
    }

    // Always get file path for terminal navigation
    final filePath = _getFilePath();

    final entry = LogEntry(
      message: message,
      filePath: filePath,
      source: source, // Explicit source name (if provided)
      level: level,
      timestamp: DateTime.now(),
      stackTrace: stackTrace,
    );

    _logHistory.addFirst(entry);
    if (_logHistory.length > _config.maxLogEntries) {
      _logHistory.removeLast();
    }
  }

  /// Log debug message
  ///
  /// [message] - The log message
  /// [source] - Optional source identifier (e.g., class name).
  ///            Useful for filtering logs by component/feature.
  ///            Example: `logger.d('Loading data', source: 'HomeScreen')`
  void d(String message, {String? source}) {
    if (_pauseLogging) return;

    final filePath = _getFilePath();
    _addLogEntry(message, 'DEBUG', source: source);

    if (_config.showFilePaths) {
      final sourceInfo = source != null ? '[$source] ' : '';
      _loggerInstance.d('$sourceInfo$message\n[$filePath]');
    } else {
      final sourceInfo = source != null ? '[$source] ' : '';
      _loggerInstance.d('$sourceInfo$message');
    }
  }

  /// Log info message
  ///
  /// [message] - The log message
  /// [source] - Optional source identifier (e.g., class name).
  ///            Useful for filtering logs by component/feature.
  ///            Example: `logger.i('User logged in', source: 'AuthService')`
  void i(String message, {String? source}) {
    if (_pauseLogging) return;

    final filePath = _getFilePath();
    _addLogEntry(message, 'INFO', source: source);

    if (_config.showFilePaths) {
      final sourceInfo = source != null ? '[$source] ' : '';
      _loggerInstance.i('$sourceInfo$message\n[$filePath]');
    } else {
      final sourceInfo = source != null ? '[$source] ' : '';
      _loggerInstance.i('$sourceInfo$message');
    }
  }

  /// Log warning message
  ///
  /// [message] - The log message
  /// [source] - Optional source identifier (e.g., class name).
  ///            Useful for filtering logs by component/feature.
  ///            Example: `logger.w('Cache miss', source: 'CacheManager')`
  void w(String message, {String? source}) {
    if (_pauseLogging) return;

    final filePath = _getFilePath();
    _addLogEntry(message, 'WARNING', source: source);

    if (_config.showFilePaths) {
      final sourceInfo = source != null ? '[$source] ' : '';
      _loggerInstance.w('$sourceInfo$message\n[$filePath]');
    } else {
      final sourceInfo = source != null ? '[$source] ' : '';
      _loggerInstance.w('$sourceInfo$message');
    }
  }

  /// Log error message with optional error object and stack trace
  ///
  /// [message] - The log message
  /// [error] - Optional error object
  /// [stackTrace] - Optional stack trace
  /// [source] - Optional source identifier (e.g., class name).
  ///            Useful for filtering logs by component/feature.
  ///            Example: `logger.e('Failed to load', error: e, source: 'DataRepo')`
  void e(String message,
      {Object? error, StackTrace? stackTrace, String? source}) {
    if (_pauseLogging) return;

    final filePath = _getFilePath();
    String? formattedError;
    final sourceInfo = source != null ? '[$source] ' : '';

    if (error != null) {
      formattedError = _formatErrorStackTrace(error, stackTrace);
      _addLogEntry(message, 'ERROR',
          stackTrace: formattedError, source: source);

      if (_config.showFilePaths) {
        _loggerInstance.e('$sourceInfo$message\n[$filePath]\n$formattedError');
      } else {
        _loggerInstance.e('$sourceInfo$message: ${error.toString()}');
      }
    } else {
      _addLogEntry(message, 'ERROR', source: source);

      if (_config.showFilePaths) {
        _loggerInstance.e('$sourceInfo$message\n[$filePath]');
      } else {
        _loggerInstance.e('$sourceInfo$message');
      }
    }
  }

  /// Clear all stored logs from memory
  static void clearLogs() {
    _logHistory.clear();
  }

  /// Get all stored logs
  static List<LogEntry> getLogs() {
    return List.from(_logHistory);
  }

  /// Get logs filtered by level
  static List<LogEntry> getLogsByLevel(String level) {
    return _logHistory.where((log) => log.level == level).toList();
  }

  /// Get recent logs within specified duration
  static List<LogEntry> getRecentLogs({
    Duration duration = const Duration(minutes: 5),
  }) {
    final cutoff = DateTime.now().subtract(duration);
    return _logHistory.where((log) => log.timestamp.isAfter(cutoff)).toList();
  }

  /// Get log count by level
  static Map<String, int> getLogCountByLevel() {
    final counts = <String, int>{};
    for (final log in _logHistory) {
      counts[log.level] = (counts[log.level] ?? 0) + 1;
    }
    return counts;
  }

  /// Get logs from specific file
  static List<LogEntry> getLogsFromFile(String filePath) {
    return _logHistory.where((log) => log.filePath.contains(filePath)).toList();
  }

  /// Export logs as formatted text
  static String exportLogs({List<LogEntry>? logs}) {
    final logsToExport = logs ?? getLogs();

    if (logsToExport.isEmpty) {
      return 'No logs to export';
    }

    final buffer = StringBuffer();
    buffer.writeln('=== AWESOME FLUTTER LOGGER EXPORT ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total Logs: ${logsToExport.length}');
    buffer.writeln();

    for (final log in logsToExport) {
      buffer.writeln('=== ${log.level} ===');
      buffer.writeln('Time: ${log.timestamp}');
      buffer.writeln('File: ${log.filePath}');
      buffer.writeln('Message: ${log.message}');
      if (log.stackTrace != null) {
        buffer.writeln('Stack Trace:');
        buffer.writeln(log.stackTrace);
      }
      buffer.writeln('=' * 50);
      buffer.writeln();
    }

    return buffer.toString();
  }
}
