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
    this.defaultMainFilter,
  });

  /// Create a copy with updated fields
  AwesomeLoggerConfig copyWith({
    int? maxLogEntries,
    bool? showFilePaths,
    bool? showEmojis,
    bool? useColors,
    int? stackTraceLines,
    LogSource? defaultMainFilter,
  }) {
    return AwesomeLoggerConfig(
      maxLogEntries: maxLogEntries ?? this.maxLogEntries,
      showFilePaths: showFilePaths ?? this.showFilePaths,
      showEmojis: showEmojis ?? this.showEmojis,
      useColors: useColors ?? this.useColors,
      stackTraceLines: stackTraceLines ?? this.stackTraceLines,
      defaultMainFilter: defaultMainFilter ?? this.defaultMainFilter,
    );
  }
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

  /// Extract file path from stack trace for debugging
  static String _getFilePath() {
    final frames = StackTrace.current.toString().split('\n');
    for (var i = 2; i < frames.length; i++) {
      final frame = frames[i].trim();
      // Skip internal logger files
      if (!frame.contains('awesome_logger.dart') &&
          !frame.contains('log_entry.dart')) {
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
          !frame.contains('log_entry.dart'),
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
  void _addLogEntry(String message, String level, {String? stackTrace}) {
    // Only store logs if storage is enabled
    if (!_storageEnabled) return;

    final filePath = _getFilePath();
    final entry = LogEntry(
      message: message,
      filePath: filePath,
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
  void d(String message) {
    if (_pauseLogging) return;

    _addLogEntry(message, 'DEBUG');

    if (_config.showFilePaths) {
      _loggerInstance.d('$message\n[${_getFilePath()}]');
    } else {
      _loggerInstance.d(message);
    }
  }

  /// Log info message
  void i(String message) {
    if (_pauseLogging) return;

    _addLogEntry(message, 'INFO');

    if (_config.showFilePaths) {
      _loggerInstance.i('$message\n[${_getFilePath()}]');
    } else {
      _loggerInstance.i(message);
    }
  }

  /// Log warning message
  void w(String message) {
    if (_pauseLogging) return;

    _addLogEntry(message, 'WARNING');

    if (_config.showFilePaths) {
      _loggerInstance.w('$message\n[${_getFilePath()}]');
    } else {
      _loggerInstance.w(message);
    }
  }

  /// Log error message with optional error object and stack trace
  void e(String message, {Object? error, StackTrace? stackTrace}) {
    if (_pauseLogging) return;

    String? formattedError;

    if (error != null) {
      formattedError = _formatErrorStackTrace(error, stackTrace);
      _addLogEntry(message, 'ERROR', stackTrace: formattedError);

      if (_config.showFilePaths) {
        _loggerInstance.e('$message\n[${_getFilePath()}]\n$formattedError');
      } else {
        _loggerInstance.e('$message: ${error.toString()}');
      }
    } else {
      _addLogEntry(message, 'ERROR');

      if (_config.showFilePaths) {
        _loggerInstance.e('$message\n[${_getFilePath()}]');
      } else {
        _loggerInstance.e(message);
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
