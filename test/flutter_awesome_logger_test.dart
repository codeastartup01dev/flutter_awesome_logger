import 'package:flutter/material.dart';
import 'package:flutter_awesome_logger/flutter_awesome_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AwesomeLoggerConfig', () {
    test('should have correct default values', () {
      final config = AwesomeLoggerConfig();
      expect(config.maxLogEntries, 1000);
      expect(config.showFilePaths, true);
      expect(config.showEmojis, true);
      expect(config.useColors, true);
      expect(config.stackTraceLines, 0);
      expect(config.enableCircularBuffer, true);
      expect(config.defaultMainFilter, null);
    });

    test('should allow custom configuration', () {
      final config = AwesomeLoggerConfig(
        maxLogEntries: 500,
        showFilePaths: false,
        showEmojis: false,
        useColors: false,
        stackTraceLines: 5,
        enableCircularBuffer: false,
        defaultMainFilter: LogSource.api,
      );

      expect(config.maxLogEntries, 500);
      expect(config.showFilePaths, false);
      expect(config.showEmojis, false);
      expect(config.useColors, false);
      expect(config.stackTraceLines, 5);
      expect(config.enableCircularBuffer, false);
      expect(config.defaultMainFilter, LogSource.api);
    });

    test('copyWith should create new instance with updated values', () {
      final original = AwesomeLoggerConfig();
      final updated = original.copyWith(
        maxLogEntries: 200,
        enableCircularBuffer: false,
      );

      expect(updated.maxLogEntries, 200);
      expect(updated.enableCircularBuffer, false);
      expect(updated.showFilePaths, original.showFilePaths); // unchanged
      expect(updated.showEmojis, original.showEmojis); // unchanged
    });
  });

  group('FloatingLoggerConfig', () {
    test('should have correct default values', () {
      final config = FloatingLoggerConfig();
      expect(config.backgroundColor, Colors.deepPurple);
      expect(config.icon, Icons.developer_mode);
      expect(config.showCount, true);
      expect(config.enableGestures, true);
      expect(config.size, 60.0);
      expect(config.autoSnapToEdges, true);
    });

    test('should allow custom configuration', () {
      final config = FloatingLoggerConfig(
        backgroundColor: Colors.red,
        icon: Icons.bug_report,
        showCount: false,
        enableGestures: false,
        size: 60.0,
        autoSnapToEdges: false,
      );

      expect(config.backgroundColor, Colors.red);
      expect(config.icon, Icons.bug_report);
      expect(config.showCount, false);
      expect(config.enableGestures, false);
      expect(config.size, 60.0);
      expect(config.autoSnapToEdges, false);
    });
  });

  group('FlutterAwesomeLogger', () {
    setUp(() {
      // Reset logger state before each test
      FlutterAwesomeLogger.configure(AwesomeLoggerConfig());
      FlutterAwesomeLogger.setStorageEnabled(true);
      FlutterAwesomeLogger.setPauseLogging(false);
      FlutterAwesomeLogger.clearLogs();
    });

    test('should configure logger with custom config', () {
      final customConfig = AwesomeLoggerConfig(
        maxLogEntries: 50,
        enableCircularBuffer: false,
      );

      FlutterAwesomeLogger.configure(customConfig);
      expect(FlutterAwesomeLogger.getLoggerConfig().maxLogEntries, 50);
      expect(
          FlutterAwesomeLogger.getLoggerConfig().enableCircularBuffer, false);
    });

    test('should store logs when enabled', () {
      final logger = FlutterAwesomeLogger.loggingUsingLogger;
      logger.i('Test info message');

      final logs = FlutterAwesomeLogger.getLogs();
      expect(logs.length, 1);
      expect(logs.first.level, 'INFO');
      expect(logs.first.message, 'Test info message');
    });

    test('should not store logs when disabled', () {
      FlutterAwesomeLogger.setStorageEnabled(false);

      final logger = FlutterAwesomeLogger.loggingUsingLogger;
      logger.w('Test warning message');

      final logs = FlutterAwesomeLogger.getLogs();
      expect(logs.isEmpty, true);
    });

    test('should respect pause logging', () {
      FlutterAwesomeLogger.setPauseLogging(true);

      final logger = FlutterAwesomeLogger.loggingUsingLogger;
      logger.e('Test error message');

      final logs = FlutterAwesomeLogger.getLogs();
      expect(logs.isEmpty, true);
    });

    test('should filter logs by level', () {
      final logger = FlutterAwesomeLogger.loggingUsingLogger;
      logger.d('Debug message');
      logger.i('Info message');
      logger.w('Warning message');
      logger.e('Error message');

      final errorLogs = FlutterAwesomeLogger.getLogsByLevel('ERROR');
      expect(errorLogs.length, 1);
      expect(errorLogs.first.level, 'ERROR');
    });

    test('should clear logs', () {
      final logger = FlutterAwesomeLogger.loggingUsingLogger;
      logger.i('Message 1');
      logger.i('Message 2');

      expect(FlutterAwesomeLogger.getLogs().length, 2);

      FlutterAwesomeLogger.clearLogs();
      expect(FlutterAwesomeLogger.getLogs().isEmpty, true);
    });

    test('should respect max log entries with circular buffer disabled', () {
      final config = AwesomeLoggerConfig(
        maxLogEntries: 2,
        enableCircularBuffer: false,
      );
      FlutterAwesomeLogger.configure(config);

      final logger = FlutterAwesomeLogger.loggingUsingLogger;
      logger.i('Message 1');
      logger.i('Message 2');
      logger.i('Message 3'); // Should not be stored

      final logs = FlutterAwesomeLogger.getLogs();
      expect(logs.length, 2); // Only first 2 messages stored
    });

    test('should implement circular buffer when enabled', () {
      final config = AwesomeLoggerConfig(
        maxLogEntries: 2,
        enableCircularBuffer: true,
      );
      FlutterAwesomeLogger.configure(config);

      final logger = FlutterAwesomeLogger.loggingUsingLogger;
      logger.i('Message 1');
      logger.i('Message 2');
      logger.i('Message 3'); // Should replace oldest

      final logs = FlutterAwesomeLogger.getLogs();
      expect(logs.length, 2);
      expect(logs.first.message, 'Message 3'); // Newest first
      expect(logs.last.message, 'Message 2'); // Oldest remaining
    });
  });

  group('LogEntry', () {
    test('should create log entry with required fields', () {
      final entry = LogEntry(
        message: 'Test message',
        filePath: 'test.dart:10:5',
        level: 'INFO',
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
      );

      expect(entry.message, 'Test message');
      expect(entry.filePath, 'test.dart:10:5');
      expect(entry.level, 'INFO');
      expect(entry.timestamp, DateTime(2024, 1, 1, 12, 0, 0));
      expect(entry.stackTrace, null);
    });

    test('should create log entry with stack trace', () {
      final stackTrace = 'Test stack trace';
      final entry = LogEntry(
        message: 'Error message',
        filePath: 'test.dart:10:5',
        level: 'ERROR',
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        stackTrace: stackTrace,
      );

      expect(entry.stackTrace, stackTrace);
    });
  });
}
