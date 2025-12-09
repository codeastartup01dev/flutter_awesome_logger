import 'package:flutter/material.dart';

import '../../api_logger/api_logger_service.dart';
import '../../core/logging_using_logger.dart';
import '../../core/unified_log_entry.dart';
import '../../core/unified_log_types.dart';
import '../widgets/common/logger_statistics.dart';

/// Service for handling log data operations and statistics
class LogDataService {
  /// Get all logs unified from different sources
  static List<UnifiedLogEntry> getUnifiedLogs() {
    final unifiedLogs = <UnifiedLogEntry>[];

    // Add general logs
    final generalLogs = LoggingUsingLogger.getLogs();
    for (final log in generalLogs) {
      unifiedLogs.add(UnifiedLogEntry.fromGeneralLog(log));
    }

    // Add API logs
    final apiLogs = ApiLoggerService.getApiLogs();
    for (final log in apiLogs) {
      unifiedLogs.add(UnifiedLogEntry.fromApiLog(log));
    }

    return unifiedLogs;
  }

  /// Get statistics for the logs
  static List<StatisticItem> getStatistics(
    List<UnifiedLogEntry> logs, {
    Set<LogSource>? selectedSources,
  }) {
    // Filter logs based on selected main filters
    List<UnifiedLogEntry> relevantLogs = logs;
    if (selectedSources != null && selectedSources.isNotEmpty) {
      relevantLogs =
          logs.where((l) => selectedSources.contains(l.source)).toList();
    }

    final successCount = relevantLogs.where((l) => l.type.isSuccess).length;
    final errorCount = relevantLogs.where((l) => l.type.isError).length;

    return [
      StatisticItem(
        label: 'Total',
        value: '${relevantLogs.length}',
        color: Colors.blue,
        filterKey: 'total',
      ),
      StatisticItem(
        label: 'Success',
        value: '$successCount',
        color: Colors.green,
        filterKey: 'success',
      ),
      StatisticItem(
        label: 'Errors',
        value: '$errorCount',
        color: Colors.red,
        filterKey: 'errors',
      ),
    ];
  }

  /// Get type counts for filter chips
  static Map<UnifiedLogType, int> getTypeCounts(
    List<UnifiedLogEntry> logs, {
    Set<LogSource>? selectedSources,
  }) {
    // Filter logs based on selected main filters for accurate sub-filter counts
    List<UnifiedLogEntry> relevantLogs = logs;
    if (selectedSources != null && selectedSources.isNotEmpty) {
      relevantLogs =
          logs.where((l) => selectedSources.contains(l.source)).toList();
    }

    final counts = <UnifiedLogType, int>{};
    for (final log in relevantLogs) {
      counts[log.type] = (counts[log.type] ?? 0) + 1;
    }
    return counts;
  }

  /// Get count of general logs
  static int getGeneralLogCount(List<UnifiedLogEntry> logs) {
    return logs.where((l) => l.source == LogSource.general).length;
  }

  /// Get count of API logs
  static int getApiLogCount(List<UnifiedLogEntry> logs) {
    return logs.where((l) => l.source == LogSource.api).length;
  }

  /// Get available HTTP methods from API logs
  static List<String> getAvailableMethods(
    List<UnifiedLogEntry> logs, {
    Set<LogSource>? selectedSources,
  }) {
    // Filter logs based on selected main filters
    List<UnifiedLogEntry> relevantLogs = logs;
    if (selectedSources != null && selectedSources.isNotEmpty) {
      relevantLogs =
          logs.where((l) => selectedSources.contains(l.source)).toList();
    }

    return relevantLogs
        .where((l) => l.source == LogSource.api && l.httpMethod != null)
        .map((l) => l.httpMethod!)
        .toSet()
        .toList()
      ..sort();
  }

  /// Get count for specific HTTP method
  static int getMethodCount(
    List<UnifiedLogEntry> logs,
    String method, {
    Set<LogSource>? selectedSources,
  }) {
    // Filter logs based on selected main filters
    List<UnifiedLogEntry> relevantLogs = logs;
    if (selectedSources != null && selectedSources.isNotEmpty) {
      relevantLogs =
          logs.where((l) => selectedSources.contains(l.source)).toList();
    }

    return relevantLogs.where((l) => l.httpMethod == method).length;
  }

  /// Check if a log has an explicit source name (passed via source: parameter)
  static bool hasExplicitSource(UnifiedLogEntry log) {
    return log.sourceName != null && log.sourceName!.isNotEmpty;
  }

  /// Check if a log has a valid file path (auto-detected from stack trace)
  static bool hasFilePath(UnifiedLogEntry log) {
    return log.filePath != null &&
        log.filePath!.isNotEmpty &&
        log.filePath!.contains('/') &&
        log.filePath != 'unknown';
  }

  /// Legacy helper - check if a string looks like an explicit source (not a file path)
  /// Used for backward compatibility
  static bool isExplicitSource(String? value) {
    if (value == null || value.isEmpty) return false;
    return !value.contains('/') && value != 'unknown';
  }

  /// Legacy helper - check if a string looks like a file path
  /// Used for backward compatibility
  static bool isFilePath(String? value) {
    if (value == null || value.isEmpty) return false;
    return value.contains('/');
  }

  /// Get available explicit sources (where source parameter was passed) with their counts
  static Map<String, int> getAvailableSources(
    List<UnifiedLogEntry> logs, {
    Set<LogSource>? selectedSources,
  }) {
    List<UnifiedLogEntry> relevantLogs = logs;
    if (selectedSources != null && selectedSources.isNotEmpty) {
      relevantLogs =
          logs.where((l) => selectedSources.contains(l.source)).toList();
    }

    final sourceCounts = <String, int>{};
    for (final log in relevantLogs) {
      if (log.source == LogSource.general && hasExplicitSource(log)) {
        sourceCounts[log.sourceName!] =
            (sourceCounts[log.sourceName!] ?? 0) + 1;
      }
    }
    return sourceCounts;
  }

  /// Get available class names from general logs with their counts (legacy - for "All" mode)
  static Map<String, int> getAvailableClasses(
    List<UnifiedLogEntry> logs, {
    Set<LogSource>? selectedSources,
  }) {
    // Filter logs based on selected main filters
    List<UnifiedLogEntry> relevantLogs = logs;
    if (selectedSources != null && selectedSources.isNotEmpty) {
      relevantLogs =
          logs.where((l) => selectedSources.contains(l.source)).toList();
    }

    final classCounts = <String, int>{};
    for (final log in relevantLogs) {
      if (log.source == LogSource.general && log.className != null) {
        classCounts[log.className!] = (classCounts[log.className!] ?? 0) + 1;
      }
    }
    return classCounts;
  }

  /// Get count for a specific class
  static int getClassCount(
    List<UnifiedLogEntry> logs,
    String className, {
    Set<LogSource>? selectedSources,
  }) {
    // Filter logs based on selected main filters
    List<UnifiedLogEntry> relevantLogs = logs;
    if (selectedSources != null && selectedSources.isNotEmpty) {
      relevantLogs =
          logs.where((l) => selectedSources.contains(l.source)).toList();
    }

    return relevantLogs
        .where((l) => l.source == LogSource.general && l.className == className)
        .length;
  }

  /// Get available file paths (actual file paths, not explicit sources) with their counts
  static Map<String, int> getAvailableFilePaths(
    List<UnifiedLogEntry> logs, {
    Set<LogSource>? selectedSources,
  }) {
    // Filter logs based on selected main filters
    List<UnifiedLogEntry> relevantLogs = logs;
    if (selectedSources != null && selectedSources.isNotEmpty) {
      relevantLogs =
          logs.where((l) => selectedSources.contains(l.source)).toList();
    }

    final filePathCounts = <String, int>{};
    for (final log in relevantLogs) {
      if (log.source == LogSource.general && hasFilePath(log)) {
        filePathCounts[log.filePath!] =
            (filePathCounts[log.filePath!] ?? 0) + 1;
      }
    }
    return filePathCounts;
  }

  /// Get count for a specific file path
  static int getFilePathCount(
    List<UnifiedLogEntry> logs,
    String filePath, {
    Set<LogSource>? selectedSources,
  }) {
    // Filter logs based on selected main filters
    List<UnifiedLogEntry> relevantLogs = logs;
    if (selectedSources != null && selectedSources.isNotEmpty) {
      relevantLogs =
          logs.where((l) => selectedSources.contains(l.source)).toList();
    }

    return relevantLogs
        .where((l) => l.source == LogSource.general && l.filePath == filePath)
        .length;
  }

  /// Get count for a specific explicit source
  static int getSourceCount(
    List<UnifiedLogEntry> logs,
    String sourceName, {
    Set<LogSource>? selectedSources,
  }) {
    List<UnifiedLogEntry> relevantLogs = logs;
    if (selectedSources != null && selectedSources.isNotEmpty) {
      relevantLogs =
          logs.where((l) => selectedSources.contains(l.source)).toList();
    }

    return relevantLogs
        .where(
            (l) => l.source == LogSource.general && l.sourceName == sourceName)
        .length;
  }

  /// Clear all logs from all sources
  static void clearAllLogs() {
    LoggingUsingLogger.clearLogs();
    ApiLoggerService.clearApiLogs();
  }

  /// Export all logs to a formatted string
  static String exportLogsToString(List<UnifiedLogEntry> logs) {
    final buffer = StringBuffer();
    buffer.writeln('=== AWESOME FLUTTER LOGGER - UNIFIED EXPORT ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total logs: ${logs.length}');
    buffer.writeln();

    for (final log in logs) {
      buffer.writeln('--- ${log.source.displayName.toUpperCase()} LOG ---');
      buffer.writeln(log.formattedContent);
      buffer.writeln();
    }

    return buffer.toString();
  }
}
