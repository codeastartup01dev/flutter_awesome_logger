/// Represents a single log entry with metadata
class LogEntry {
  /// The log message content
  final String message;

  /// File path where the log was generated from (for terminal navigation)
  final String filePath;

  /// Optional explicit source name (e.g., class name passed via source parameter)
  final String? source;

  /// Log level (DEBUG, INFO, WARNING, ERROR)
  final String level;

  /// When this log entry was created
  final DateTime timestamp;

  /// Optional stack trace for error logs
  final String? stackTrace;

  const LogEntry({
    required this.message,
    required this.filePath,
    this.source,
    required this.level,
    required this.timestamp,
    this.stackTrace,
  });

  /// Create a copy with updated fields
  LogEntry copyWith({
    String? message,
    String? filePath,
    String? source,
    String? level,
    DateTime? timestamp,
    String? stackTrace,
  }) {
    return LogEntry(
      message: message ?? this.message,
      filePath: filePath ?? this.filePath,
      source: source ?? this.source,
      level: level ?? this.level,
      timestamp: timestamp ?? this.timestamp,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }

  /// Convert to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'filePath': filePath,
      'source': source,
      'level': level,
      'timestamp': timestamp.toIso8601String(),
      'stackTrace': stackTrace,
    };
  }

  /// Create from JSON representation
  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      message: json['message'] as String,
      filePath: json['filePath'] as String,
      source: json['source'] as String?,
      level: json['level'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      stackTrace: json['stackTrace'] as String?,
    );
  }

  @override
  String toString() {
    return 'LogEntry(level: $level, message: $message, filePath: $filePath, source: $source, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LogEntry &&
        other.message == message &&
        other.filePath == filePath &&
        other.source == source &&
        other.level == level &&
        other.timestamp == timestamp &&
        other.stackTrace == stackTrace;
  }

  @override
  int get hashCode {
    return Object.hash(message, filePath, source, level, timestamp, stackTrace);
  }
}
