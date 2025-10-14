import 'dart:collection';

import 'package:dio/dio.dart';

import '../core/logging_using_logger.dart';
import 'api_log_entry.dart';

/// Service for logging API requests, responses, and errors with detailed information
class ApiLoggerService {
  static final Queue<ApiLogEntry> _apiLogs = Queue<ApiLogEntry>();
  static const int _maxApiLogEntries = 500; // Limit for API logs specifically
  static bool _enabled = true; // Can be disabled for production

  /// Map to track request start times for duration calculation
  final Map<String, DateTime> _requestStartTimes = {};

  /// Enable or disable API logging
  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Check if API logging is enabled
  static bool get isEnabled => _enabled;

  /// Add API log entry to the queue
  void _addApiLogEntry(ApiLogEntry entry) {
    if (!_enabled || LoggingUsingLogger.isPaused) return;

    _apiLogs.addFirst(entry);
    if (_apiLogs.length > _maxApiLogEntries) {
      _apiLogs.removeLast();
    }
  }

  /// Generate unique ID for API call tracking
  String _generateApiId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_apiLogs.length}';
  }

  /// Log API request
  String logRequest(RequestOptions options) {
    if (!_enabled || LoggingUsingLogger.isPaused) return '';

    final apiId = _generateApiId();
    _requestStartTimes[apiId] = DateTime.now();

    final entry = ApiLogEntry.fromRequest(id: apiId, options: options);

    _addApiLogEntry(entry);
    return apiId;
  }

  /// Log API response - updates the existing pending log entry
  void logResponse(String apiId, Response response) {
    if (!_enabled || apiId.isEmpty || LoggingUsingLogger.isPaused) return;

    final startTime = _requestStartTimes[apiId];
    final duration = startTime != null
        ? DateTime.now().difference(startTime).inMilliseconds
        : 0;

    // Find and update the existing pending log entry
    final pendingLogIndex = _apiLogs.toList().indexWhere(
      (log) => log.id == apiId && log.type == ApiLogType.pending,
    );

    if (pendingLogIndex != -1) {
      // Remove the old pending entry
      final pendingLog = _apiLogs.elementAt(pendingLogIndex);
      _apiLogs.remove(pendingLog);

      // Create updated entry with response data
      final updatedEntry = ApiLogEntry.fromResponse(
        id: apiId,
        response: response,
        duration: duration,
        curl: pendingLog.curl,
      );

      _addApiLogEntry(updatedEntry);
    } else {
      // Fallback: create new entry if pending not found
      final entry = ApiLogEntry.fromResponse(
        id: apiId,
        response: response,
        duration: duration,
        curl: ApiLogEntry.generateCurl(response.requestOptions),
      );
      _addApiLogEntry(entry);
    }

    // Cleanup request start time
    _requestStartTimes.remove(apiId);
  }

  /// Log API error - updates the existing pending log entry
  void logError(String apiId, DioException error) {
    if (!_enabled || apiId.isEmpty || LoggingUsingLogger.isPaused) return;

    final startTime = _requestStartTimes[apiId];
    final duration = startTime != null
        ? DateTime.now().difference(startTime).inMilliseconds
        : 0;

    // Find and update the existing pending log entry
    final pendingLogIndex = _apiLogs.toList().indexWhere(
      (log) => log.id == apiId && log.type == ApiLogType.pending,
    );

    if (pendingLogIndex != -1) {
      // Remove the old pending entry
      final pendingLog = _apiLogs.elementAt(pendingLogIndex);
      _apiLogs.remove(pendingLog);

      // Create updated entry with error data
      final updatedEntry = ApiLogEntry.fromError(
        id: apiId,
        error: error,
        duration: duration,
        curl: pendingLog.curl,
      );

      _addApiLogEntry(updatedEntry);
    } else {
      // Fallback: create new entry if pending not found
      final entry = ApiLogEntry.fromError(
        id: apiId,
        error: error,
        duration: duration,
        curl: ApiLogEntry.generateCurl(error.requestOptions),
      );
      _addApiLogEntry(entry);
    }

    // Cleanup request start time
    _requestStartTimes.remove(apiId);
  }

  /// Get all API logs
  static List<ApiLogEntry> getApiLogs() {
    return List.from(_apiLogs);
  }

  /// Get API logs filtered by type
  static List<ApiLogEntry> getApiLogsByType(ApiLogType type) {
    return _apiLogs.where((log) => log.type == type).toList();
  }

  /// Get API logs for specific request ID
  static List<ApiLogEntry> getApiLogsById(String id) {
    return _apiLogs.where((log) => log.id == id).toList();
  }

  /// Get recent API logs within specified duration
  static List<ApiLogEntry> getRecentApiLogs({
    Duration duration = const Duration(minutes: 5),
  }) {
    final cutoff = DateTime.now().subtract(duration);
    return _apiLogs.where((log) => log.timestamp.isAfter(cutoff)).toList();
  }

  /// Get API logs filtered by HTTP method
  static List<ApiLogEntry> getApiLogsByMethod(String method) {
    return _apiLogs
        .where((log) => log.method.toUpperCase() == method.toUpperCase())
        .toList();
  }

  /// Get API logs filtered by status code range
  static List<ApiLogEntry> getApiLogsByStatusCode({
    int? minStatus,
    int? maxStatus,
  }) {
    return _apiLogs.where((log) {
      if (log.statusCode == null) return false;
      if (minStatus != null && log.statusCode! < minStatus) return false;
      if (maxStatus != null && log.statusCode! > maxStatus) return false;
      return true;
    }).toList();
  }

  /// Get API logs containing specific URL pattern
  static List<ApiLogEntry> getApiLogsByUrl(String urlPattern) {
    return _apiLogs
        .where(
          (log) => log.url.toLowerCase().contains(urlPattern.toLowerCase()),
        )
        .toList();
  }

  /// Get API log statistics
  static Map<String, dynamic> getApiLogStats() {
    final stats = <String, dynamic>{
      'total': _apiLogs.length,
      'requests': 0,
      'responses': 0,
      'errors': 0,
      'methods': <String, int>{},
      'statusCodes': <int, int>{},
      'avgDuration': 0.0,
    };

    var totalDuration = 0;
    var durationCount = 0;

    for (final log in _apiLogs) {
      // Count by type
      switch (log.type) {
        case ApiLogType.success:
        case ApiLogType.redirect:
          stats['responses']++;
          break;
        case ApiLogType.clientError:
        case ApiLogType.serverError:
        case ApiLogType.networkError:
          stats['errors']++;
          break;
        case ApiLogType.pending:
          // Don't count pending requests in stats
          break;
      }

      // Count by method
      stats['methods'][log.method] = (stats['methods'][log.method] ?? 0) + 1;

      // Count by status code
      if (log.statusCode != null) {
        stats['statusCodes'][log.statusCode!] =
            (stats['statusCodes'][log.statusCode!] ?? 0) + 1;
      }

      // Calculate average duration
      if (log.duration != null) {
        totalDuration += log.duration!;
        durationCount++;
      }
    }

    if (durationCount > 0) {
      stats['avgDuration'] = totalDuration / durationCount;
    }

    return stats;
  }

  /// Clear all API logs
  static void clearApiLogs() {
    _apiLogs.clear();
  }

  /// Get unique endpoints from logs
  static List<String> getUniqueEndpoints() {
    return _apiLogs
        .map((log) {
          final uri = Uri.parse(log.url);
          return '${log.method} ${uri.path}';
        })
        .toSet()
        .toList();
  }

  /// Get logs grouped by endpoint
  static Map<String, List<ApiLogEntry>> getLogsGroupedByEndpoint() {
    final grouped = <String, List<ApiLogEntry>>{};

    for (final log in _apiLogs) {
      final uri = Uri.parse(log.url);
      final endpoint = '${log.method} ${uri.path}';

      if (!grouped.containsKey(endpoint)) {
        grouped[endpoint] = [];
      }
      grouped[endpoint]!.add(log);
    }

    return grouped;
  }

  /// Export API logs as formatted text
  static String exportApiLogs({List<ApiLogEntry>? logs}) {
    final logsToExport = logs ?? getApiLogs();

    if (logsToExport.isEmpty) {
      return 'No API logs to export';
    }

    final buffer = StringBuffer();
    buffer.writeln('=== API LOGS EXPORT ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total Logs: ${logsToExport.length}');
    buffer.writeln();

    for (final log in logsToExport) {
      buffer.writeln(log.formattedFull);
      buffer.writeln('=' * 50);
      buffer.writeln();
    }

    return buffer.toString();
  }
}
