import 'dart:convert';

import 'package:dio/dio.dart';

/// API log entry model for storing detailed HTTP request/response information
class ApiLogEntry {
  /// Unique identifier for this API call
  final String id;

  /// HTTP method (GET, POST, PUT, DELETE, etc.)
  final String method;

  /// Complete URL including query parameters
  final String url;

  /// Request headers
  final Map<String, dynamic> requestHeaders;

  /// Request body/data
  final dynamic requestData;

  /// Response status code (null if request failed before response)
  final int? statusCode;

  /// Response headers (null if request failed before response)
  final Map<String, dynamic>? responseHeaders;

  /// Response body/data (null if request failed before response)
  final dynamic responseData;

  /// Error information if request failed
  final String? error;

  /// Request timestamp
  final DateTime timestamp;

  /// Response duration in milliseconds (null if still pending or failed)
  final int? duration;

  /// Type of log entry (request, response, error)
  final ApiLogType type;

  /// cURL command representation of the request
  final String curl;

  const ApiLogEntry({
    required this.id,
    required this.method,
    required this.url,
    required this.requestHeaders,
    this.requestData,
    this.statusCode,
    this.responseHeaders,
    this.responseData,
    this.error,
    required this.timestamp,
    this.duration,
    required this.type,
    required this.curl,
  });

  /// Create API log entry from Dio RequestOptions (initially pending)
  factory ApiLogEntry.fromRequest({
    required String id,
    required RequestOptions options,
  }) {
    return ApiLogEntry(
      id: id,
      method: options.method,
      url: options.uri.toString(),
      requestHeaders: Map<String, dynamic>.from(options.headers),
      requestData: options.data,
      timestamp: DateTime.now(),
      type: ApiLogType.pending,
      curl: generateCurl(options),
    );
  }

  /// Create API log entry from Dio Response
  factory ApiLogEntry.fromResponse({
    required String id,
    required Response response,
    required int duration,
    required String curl,
  }) {
    return ApiLogEntry(
      id: id,
      method: response.requestOptions.method,
      url: response.requestOptions.uri.toString(),
      requestHeaders: Map<String, dynamic>.from(
        response.requestOptions.headers,
      ),
      requestData: response.requestOptions.data,
      statusCode: response.statusCode,
      responseHeaders: response.headers.map.map(
        (key, value) => MapEntry(key, value.join(', ')),
      ),
      responseData: response.data,
      timestamp: DateTime.now(),
      duration: duration,
      type: _getLogTypeFromStatusCode(response.statusCode),
      curl: curl,
    );
  }

  /// Create API log entry from Dio Error
  factory ApiLogEntry.fromError({
    required String id,
    required DioException error,
    required int duration,
    required String curl,
  }) {
    return ApiLogEntry(
      id: id,
      method: error.requestOptions.method,
      url: error.requestOptions.uri.toString(),
      requestHeaders: Map<String, dynamic>.from(error.requestOptions.headers),
      requestData: error.requestOptions.data,
      statusCode: error.response?.statusCode,
      responseHeaders: error.response?.headers.map.map(
        (key, value) => MapEntry(key, value.join(', ')),
      ),
      responseData: error.response?.data,
      error: '${error.type}: ${error.message}',
      timestamp: DateTime.now(),
      duration: duration,
      type: _getLogTypeFromError(error),
      curl: curl,
    );
  }

  /// Determine log type from HTTP status code
  static ApiLogType _getLogTypeFromStatusCode(int? statusCode) {
    if (statusCode == null) return ApiLogType.pending;

    if (statusCode >= 200 && statusCode < 300) {
      return ApiLogType.success;
    } else if (statusCode >= 300 && statusCode < 400) {
      return ApiLogType.redirect;
    } else if (statusCode >= 400 && statusCode < 500) {
      return ApiLogType.clientError;
    } else if (statusCode >= 500) {
      return ApiLogType.serverError;
    }

    return ApiLogType.pending;
  }

  /// Determine log type from Dio error
  static ApiLogType _getLogTypeFromError(DioException error) {
    // If we have a response, use the status code
    if (error.response?.statusCode != null) {
      return _getLogTypeFromStatusCode(error.response!.statusCode);
    }

    // For network errors without response
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return ApiLogType.networkError;
      case DioExceptionType.badCertificate:
        return ApiLogType.clientError;
      case DioExceptionType.cancel:
        return ApiLogType.networkError;
      case DioExceptionType.badResponse:
        // This should have a response, but fallback to server error
        return ApiLogType.serverError;
    }
  }

  /// Generate cURL command from RequestOptions
  static String generateCurl(RequestOptions options) {
    final buffer = StringBuffer();
    buffer.write('curl -X ${options.method}');

    // Add headers
    options.headers.forEach((key, value) {
      buffer.write(' -H "$key: $value"');
    });

    // Add data if present
    if (options.data != null) {
      String dataString;
      if (options.data is FormData) {
        dataString =
            'FormData(${(options.data as FormData).fields.length} fields)';
      } else if (options.data is Map) {
        dataString = jsonEncode(options.data);
      } else {
        dataString = options.data.toString();
      }
      buffer.write(' -d \'$dataString\'');
    }

    // Add URL
    buffer.write(' "${options.uri}"');

    return buffer.toString();
  }

  /// Get formatted request details as string
  String get formattedRequest {
    final buffer = StringBuffer();
    buffer.writeln('=== REQUEST ===');
    buffer.writeln('Method: $method');
    buffer.writeln('URL: $url');
    buffer.writeln('Headers:');
    requestHeaders.forEach((key, value) {
      buffer.writeln('  $key: $value');
    });
    if (requestData != null) {
      buffer.writeln('Body:');
      buffer.writeln('  ${_formatData(requestData)}');
    }
    return buffer.toString();
  }

  /// Get formatted response details as string
  String get formattedResponse {
    if (type == ApiLogType.pending) return '';

    final buffer = StringBuffer();
    buffer.writeln('=== RESPONSE ===');
    if (statusCode != null) {
      buffer.writeln('Status: $statusCode');
    }
    if (duration != null) {
      buffer.writeln('Duration: ${duration}ms');
    }
    if (responseHeaders != null) {
      buffer.writeln('Headers:');
      responseHeaders!.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }
    if (responseData != null) {
      buffer.writeln('Body:');
      buffer.writeln('  ${_formatData(responseData)}');
    }
    if (error != null) {
      buffer.writeln('Error: $error');
    }
    return buffer.toString();
  }

  /// Get formatted request body only (for primary display)
  String get formattedRequestBody {
    if (requestData == null) return '';
    return _formatData(requestData);
  }

  /// Get formatted response body only (for primary display)
  String get formattedResponseBody {
    if (type == ApiLogType.pending || responseData == null) return '';
    return _formatData(responseData);
  }

  /// Get formatted request headers and metadata (for secondary display)
  String get formattedRequestHeaders {
    final buffer = StringBuffer();
    buffer.writeln('Method: $method');
    buffer.writeln('URL: $url');
    if (requestHeaders.isNotEmpty) {
      buffer.writeln('Headers:');
      requestHeaders.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }
    return buffer.toString();
  }

  /// Get formatted response headers and metadata (for secondary display)
  String get formattedResponseHeaders {
    if (type == ApiLogType.pending) return '';

    final buffer = StringBuffer();
    if (statusCode != null) {
      buffer.writeln('Status: $statusCode');
    }
    if (duration != null) {
      buffer.writeln('Duration: ${duration}ms');
    }
    if (responseHeaders != null && responseHeaders!.isNotEmpty) {
      buffer.writeln('Headers:');
      responseHeaders!.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }
    if (error != null) {
      buffer.writeln('Error: $error');
    }
    return buffer.toString();
  }

  /// Get full formatted log including request and response
  String get formattedFull {
    final buffer = StringBuffer();
    buffer.writeln('=== API LOG ===');
    buffer.writeln('ID: $id');
    buffer.writeln('Timestamp: $timestamp');
    buffer.writeln('Type: ${type.name.toUpperCase()}');
    buffer.writeln();
    buffer.write(formattedRequest);
    buffer.writeln();
    buffer.write(formattedResponse);
    buffer.writeln();
    buffer.writeln('=== CURL ===');
    buffer.writeln(curl);
    return buffer.toString();
  }

  /// Format data for display (JSON pretty print or string)
  String _formatData(dynamic data) {
    if (data == null) return 'null';

    try {
      if (data is Map || data is List) {
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(data);
      }
      return data.toString();
    } catch (e) {
      return data.toString();
    }
  }

  /// Get display title for UI
  String get displayTitle {
    final uri = Uri.parse(url);

    // Get path without leading "/"
    String path = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;

    return path.isNotEmpty ? path : url;
  }

  /// Get short description for UI subtitle
  String get shortDescription {
    final timeText = timestamp.toIso8601String().substring(11, 19);
    final durationText = duration != null ? ' in ${duration}ms' : '';

    switch (type) {
      case ApiLogType.success:
        return 'Success at $timeText$durationText';
      case ApiLogType.redirect:
        return 'Redirect at $timeText$durationText';
      case ApiLogType.clientError:
        return 'Client Error at $timeText$durationText';
      case ApiLogType.serverError:
        return 'Server Error at $timeText$durationText';
      case ApiLogType.networkError:
        return 'Network Error at $timeText - ${error ?? 'Connection failed'}';
      case ApiLogType.pending:
        return 'Pending since $timeText';
    }
  }

  /// Convert to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method': method,
      'url': url,
      'requestHeaders': requestHeaders,
      'requestData': requestData,
      'statusCode': statusCode,
      'responseHeaders': responseHeaders,
      'responseData': responseData,
      'error': error,
      'timestamp': timestamp.toIso8601String(),
      'duration': duration,
      'type': type.name,
      'curl': curl,
    };
  }

  /// Create from JSON representation
  factory ApiLogEntry.fromJson(Map<String, dynamic> json) {
    return ApiLogEntry(
      id: json['id'] as String,
      method: json['method'] as String,
      url: json['url'] as String,
      requestHeaders: Map<String, dynamic>.from(json['requestHeaders'] as Map),
      requestData: json['requestData'],
      statusCode: json['statusCode'] as int?,
      responseHeaders: json['responseHeaders'] != null
          ? Map<String, dynamic>.from(json['responseHeaders'] as Map)
          : null,
      responseData: json['responseData'],
      error: json['error'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      duration: json['duration'] as int?,
      type: ApiLogType.values.firstWhere((e) => e.name == json['type']),
      curl: json['curl'] as String,
    );
  }

  @override
  String toString() {
    return 'ApiLogEntry(id: $id, method: $method, url: $url, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApiLogEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Type of API log entry based on status code outcome
enum ApiLogType {
  /// 2xx - Successful responses
  success,

  /// 5xx - Server error responses
  serverError,

  /// 4xx - Client error responses
  clientError,

  /// Network/connection errors (no response received)
  networkError,

  /// Request still pending (no response yet)
  pending,

  /// 3xx - Redirection responses
  redirect,
}
