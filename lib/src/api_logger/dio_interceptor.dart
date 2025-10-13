import 'package:dio/dio.dart';

import 'api_logger_service.dart';

/// Dio interceptor that logs API requests, responses, and errors using ApiLoggerService
class FlutterAwesomeLoggerDioInterceptor extends Interceptor {
  /// Instance of ApiLoggerService for logging
  final ApiLoggerService _apiLogger = ApiLoggerService();

  /// Map to store request IDs for tracking across request/response/error
  final Map<String, String> _requestIds = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    try {
      // Log the request using ApiLoggerService and store the ID for later use
      final requestId = _apiLogger.logRequest(options);
      _requestIds[options.hashCode.toString()] = requestId;

      // Continue with the request
      handler.next(options);
    } catch (e) {
      // Don't break the request flow if logging fails
      handler.next(options);
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    try {
      // Get the request ID from the map
      final requestId =
          _requestIds[response.requestOptions.hashCode.toString()];

      if (requestId != null) {
        // Log the response using the stored request ID
        _apiLogger.logResponse(requestId, response);

        // Clean up the request ID from memory
        _requestIds.remove(response.requestOptions.hashCode.toString());
      } else {
        // Fallback: log without request ID if not found
        final fallbackId = _apiLogger.logRequest(response.requestOptions);
        _apiLogger.logResponse(fallbackId, response);
      }

      // Continue with the response
      handler.next(response);
    } catch (e) {
      // Don't break the response flow if logging fails
      handler.next(response);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    try {
      // Get the request ID from the map
      final requestId = _requestIds[err.requestOptions.hashCode.toString()];

      if (requestId != null) {
        // Log the error using the stored request ID
        _apiLogger.logError(requestId, err);

        // Clean up the request ID from memory
        _requestIds.remove(err.requestOptions.hashCode.toString());
      } else {
        // Fallback: log without request ID if not found
        final fallbackId = _apiLogger.logRequest(err.requestOptions);
        _apiLogger.logError(fallbackId, err);
      }

      // Continue with the error
      handler.next(err);
    } catch (e) {
      // Don't break the error flow if logging fails
      handler.next(err);
    }
  }

  /// Clear all stored request IDs (useful for cleanup)
  void clearRequestIds() {
    _requestIds.clear();
  }

  /// Get the current number of tracked requests
  int get trackedRequestsCount => _requestIds.length;
}
