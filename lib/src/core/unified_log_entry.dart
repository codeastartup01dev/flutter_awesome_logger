import '../api_logger/api_log_entry.dart';
import 'log_entry.dart';
import 'unified_log_types.dart';

/// Unified log entry that can represent both general logs and API logs
class UnifiedLogEntry {
  /// Unique identifier for this log entry
  final String id;

  /// The log message or title
  final String message;

  /// When this log entry was created
  final DateTime timestamp;

  /// Type of log entry
  final UnifiedLogType type;

  /// Source of the log (general or API)
  final LogSource source;

  /// Optional file path for general logs
  final String? filePath;

  /// Optional stack trace for error logs
  final String? stackTrace;

  /// Optional API-specific data
  final ApiLogEntry? apiLogEntry;

  /// Optional general log entry
  final LogEntry? generalLogEntry;

  /// Optional duration for API calls
  final int? duration;

  /// Optional HTTP method for API calls
  final String? httpMethod;

  /// Optional URL for API calls
  final String? url;

  /// Optional status code for API calls
  final int? statusCode;

  const UnifiedLogEntry({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.type,
    required this.source,
    this.filePath,
    this.stackTrace,
    this.apiLogEntry,
    this.generalLogEntry,
    this.duration,
    this.httpMethod,
    this.url,
    this.statusCode,
  });

  /// Create unified log entry from general log entry
  factory UnifiedLogEntry.fromGeneralLog(LogEntry generalLog) {
    final unifiedType = _mapGeneralLogLevel(generalLog.level);
    return UnifiedLogEntry(
      id: '${generalLog.timestamp.millisecondsSinceEpoch}_general',
      message: generalLog.message,
      timestamp: generalLog.timestamp,
      type: unifiedType,
      source: LogSource.general,
      filePath: generalLog.filePath,
      stackTrace: generalLog.stackTrace,
      generalLogEntry: generalLog,
    );
  }

  /// Create unified log entry from API log entry
  factory UnifiedLogEntry.fromApiLog(ApiLogEntry apiLog) {
    final unifiedType = _mapApiLogType(apiLog.type);
    return UnifiedLogEntry(
      id: apiLog.id,
      message: apiLog.displayTitle,
      timestamp: apiLog.timestamp,
      type: unifiedType,
      source: LogSource.api,
      apiLogEntry: apiLog,
      duration: apiLog.duration,
      httpMethod: apiLog.method,
      url: apiLog.url,
      statusCode: apiLog.statusCode,
    );
  }

  /// Map general log level to unified log type
  static UnifiedLogType _mapGeneralLogLevel(String level) {
    switch (level.toUpperCase()) {
      case 'DEBUG':
        return UnifiedLogType.debug;
      case 'INFO':
        return UnifiedLogType.info;
      case 'WARNING':
        return UnifiedLogType.warning;
      case 'ERROR':
        return UnifiedLogType.error;
      default:
        return UnifiedLogType.info;
    }
  }

  /// Map API log type to unified log type
  static UnifiedLogType _mapApiLogType(ApiLogType apiType) {
    switch (apiType) {
      case ApiLogType.success:
        return UnifiedLogType.apiSuccess;
      case ApiLogType.redirect:
        return UnifiedLogType.apiRedirect;
      case ApiLogType.clientError:
        return UnifiedLogType.apiClientError;
      case ApiLogType.serverError:
        return UnifiedLogType.apiServerError;
      case ApiLogType.networkError:
        return UnifiedLogType.apiNetworkError;
      case ApiLogType.pending:
        return UnifiedLogType.apiPending;
    }
  }

  /// Get subtitle text for display
  String get subtitle {
    final timeText = timestamp.toIso8601String().substring(11, 19);

    if (source == LogSource.api) {
      final durationText = duration != null ? ' in ${duration}ms' : '';
      return '$httpMethod at $timeText$durationText';
    } else {
      return '$timeText${filePath != null ? ' • ${filePath!.split('/').last}' : ''}';
    }
  }

  /// Get detailed description for display
  String get detailedDescription {
    if (source == LogSource.api && apiLogEntry != null) {
      return apiLogEntry!.shortDescription;
    } else if (source == LogSource.general) {
      return message;
    }
    return message;
  }

  /// Get formatted content for copying
  String get formattedContent {
    if (source == LogSource.api && apiLogEntry != null) {
      return apiLogEntry!.formattedFull;
    } else if (source == LogSource.general && generalLogEntry != null) {
      final buffer = StringBuffer();
      buffer.writeln('=== GENERAL LOG ===');
      buffer.writeln('Level: ${generalLogEntry!.level}');
      buffer.writeln('Time: ${generalLogEntry!.timestamp}');
      buffer.writeln('File: ${generalLogEntry!.filePath}');
      buffer.writeln('Message: ${generalLogEntry!.message}');
      if (generalLogEntry!.stackTrace != null) {
        buffer.writeln('Stack Trace:');
        buffer.writeln(generalLogEntry!.stackTrace);
      }
      return buffer.toString();
    }
    return message;
  }

  /// Check if this log matches a search query
  bool matchesSearch(String query) {
    if (query.isEmpty) return true;

    final lowerQuery = query.toLowerCase();

    // Check message
    if (message.toLowerCase().contains(lowerQuery)) return true;

    // Check file path for general logs
    if (filePath?.toLowerCase().contains(lowerQuery) == true) return true;

    // Check stack trace for general logs
    if (stackTrace?.toLowerCase().contains(lowerQuery) == true) return true;

    // Check API-specific fields
    if (source == LogSource.api && apiLogEntry != null) {
      if (apiLogEntry!.url.toLowerCase().contains(lowerQuery)) return true;
      if (apiLogEntry!.method.toLowerCase().contains(lowerQuery)) return true;
      if (apiLogEntry!.error?.toLowerCase().contains(lowerQuery) == true) {
        return true;
      }
      if (apiLogEntry!.curl.toLowerCase().contains(lowerQuery)) return true;
    }

    return false;
  }

  /// Get class name for general logs (for filtering)
  String? get className {
    if (source == LogSource.general && filePath != null) {
      return filePath!.split('/').last.split('.').first;
    }
    return null;
  }

  /// Get endpoint for API logs (for filtering)
  String? get endpoint {
    if (source == LogSource.api && apiLogEntry != null) {
      final uri = Uri.parse(apiLogEntry!.url);
      return '${apiLogEntry!.method} ${uri.path}';
    }
    return null;
  }

  @override
  String toString() {
    return 'UnifiedLogEntry(id: $id, type: $type, source: $source, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnifiedLogEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
