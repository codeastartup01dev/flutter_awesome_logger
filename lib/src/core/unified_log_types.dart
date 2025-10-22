import 'package:flutter/material.dart';

/// Unified log types that encompass both general logs and API logs
enum UnifiedLogType {
  // General log types
  debug,
  info,
  warning,
  error,

  // API log types
  apiSuccess,
  apiRedirect,
  apiClientError,
  apiServerError,
  apiNetworkError,
  apiPending,
}

/// Extension to provide display names and colors for unified log types
extension UnifiedLogTypeExtension on UnifiedLogType {
  /// Get display name for the log type
  String get displayName {
    switch (this) {
      case UnifiedLogType.debug:
        return 'Debug';
      case UnifiedLogType.info:
        return 'Info';
      case UnifiedLogType.warning:
        return 'Warning';
      case UnifiedLogType.error:
        return 'Error';
      case UnifiedLogType.apiSuccess:
        return 'API Success (2xx)';
      case UnifiedLogType.apiRedirect:
        return 'API Redirect (3xx)';
      case UnifiedLogType.apiClientError:
        return 'API Client Error (4xx)';
      case UnifiedLogType.apiServerError:
        return 'API Server Error (5xx)';
      case UnifiedLogType.apiNetworkError:
        return 'API Network Error';
      case UnifiedLogType.apiPending:
        return 'API Pending';
    }
  }

  /// Get color for the log type
  Color get color {
    switch (this) {
      case UnifiedLogType.debug:
        return Colors.grey;
      case UnifiedLogType.info:
        return Colors.blue;
      case UnifiedLogType.warning:
        return Colors.orange;
      case UnifiedLogType.error:
        return Colors.red;
      case UnifiedLogType.apiSuccess:
        return Colors.green;
      case UnifiedLogType.apiRedirect:
        return Colors.blue;
      case UnifiedLogType.apiClientError:
        return Colors.orange;
      case UnifiedLogType.apiServerError:
        return Colors.red;
      case UnifiedLogType.apiNetworkError:
        return Colors.purple;
      case UnifiedLogType.apiPending:
        return Colors.grey;
    }
  }

  /// Get icon for the log type
  IconData get icon {
    switch (this) {
      case UnifiedLogType.debug:
        return Icons.bug_report;
      case UnifiedLogType.info:
        return Icons.info;
      case UnifiedLogType.warning:
        return Icons.warning;
      case UnifiedLogType.error:
        return Icons.error;
      case UnifiedLogType.apiSuccess:
        return Icons.check_circle;
      case UnifiedLogType.apiRedirect:
        return Icons.redo;
      case UnifiedLogType.apiClientError:
        return Icons.warning;
      case UnifiedLogType.apiServerError:
        return Icons.error;
      case UnifiedLogType.apiNetworkError:
        return Icons.cloud_off;
      case UnifiedLogType.apiPending:
        return Icons.hourglass_empty;
    }
  }

  /// Check if this is an API log type
  bool get isApiLog {
    switch (this) {
      case UnifiedLogType.apiSuccess:
      case UnifiedLogType.apiRedirect:
      case UnifiedLogType.apiClientError:
      case UnifiedLogType.apiServerError:
      case UnifiedLogType.apiNetworkError:
      case UnifiedLogType.apiPending:
        return true;
      default:
        return false;
    }
  }

  /// Check if this is a general log type
  bool get isGeneralLog => !isApiLog;

  /// Check if this represents an error state
  bool get isError {
    switch (this) {
      case UnifiedLogType.error:
      case UnifiedLogType.apiClientError:
      case UnifiedLogType.apiServerError:
      case UnifiedLogType.apiNetworkError:
        return true;
      default:
        return false;
    }
  }

  /// Check if this represents a success state
  bool get isSuccess {
    switch (this) {
      case UnifiedLogType.info:
      case UnifiedLogType.apiSuccess:
      case UnifiedLogType.apiRedirect:
        return true;
      default:
        return false;
    }
  }
}

/// Log source to distinguish between general and API logs
enum LogSource {
  general,
  api,
}

/// Extension for LogSource
extension LogSourceExtension on LogSource {
  String get displayName {
    switch (this) {
      case LogSource.general:
        return 'General';
      case LogSource.api:
        return 'API';
    }
  }

  Color get color {
    switch (this) {
      case LogSource.general:
        return Colors.blue;
      case LogSource.api:
        return Colors.green;
    }
  }
}
