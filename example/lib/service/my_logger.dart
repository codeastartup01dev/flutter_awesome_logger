import 'package:flutter_awesome_logger/flutter_awesome_logger.dart';

/// Global logger instance for use throughout the app.
/// Use this in files where you DON'T use AwesomeLoggerMixin.
final logger = FlutterAwesomeLogger.loggingUsingLogger;

/// Demo class showing AwesomeLoggerMixin usage
/// Note: Using `this.logger` because top-level `logger` in same file shadows mixin getter
class DemoService with AwesomeLoggerMixin {
  void test() {
    print('Logger source: ${this.logger.source}'); // Should print: DemoService
    this.logger.d('This is a debug message');
    this.logger.i('This is an info message');
    this.logger.w('This is a warning message');
  }
}

// Run this to test the mixin
void testMixin() {
  print('--- Testing AwesomeLoggerMixin ---');
  DemoService().test();
  print('--- End Test ---');
}
