import 'package:dio/dio.dart';
import '../config/api_config.dart';

class APIClient {
  late final Dio _dio;

  APIClient() {
    _dio = APIConfig.dio;
  }

  // Generic GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Generic POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Generic PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Generic DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // File upload
  Future<Response<T>> upload<T>(
    String path,
    FormData formData, {
    ProgressCallback? onSendProgress,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: options,
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Download file
  Future<Response> download(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.download(
        urlPath,
        savePath,
        queryParameters: queryParameters,
        options: options,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Handle Dio errors and convert to ApiException
  ApiException _handleDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    final message = _getErrorMessage(error);
    return ApiException(message, statusCode);
  }

  String _getErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network settings.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        switch (statusCode) {
          case 400:
            return 'Bad request. Please check your input.';
          case 401:
            return 'Authentication failed. Please log in again.';
          case 403:
            return 'Access denied. You don\'t have permission to access this resource.';
          case 404:
            return 'Requested resource not found.';
          case 422:
            return 'Validation error. Please check your input.';
          case 429:
            return 'Too many requests. Please try again later.';
          case 500:
            return 'Server error. Please try again later.';
          case 502:
            return 'Server temporarily unavailable. Please try again later.';
          case 503:
            return 'Service temporarily unavailable. Please try again later.';
          default:
            return error.response?.data?['message'] ?? 'An error occurred.';
        }
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.unknown:
        if (error.error?.toString().contains('SocketException') == true) {
          return 'No internet connection. Please check your network settings.';
        }
        return 'An unexpected error occurred. Please try again.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  // Custom headers for specific requests
  Options getCustomHeaders({
    String? contentType,
    Map<String, String>? additionalHeaders,
  }) {
    final headers = <String, String>{
      if (contentType != null) 'Content-Type': contentType,
      ...?additionalHeaders,
    };

    return Options(headers: headers);
  }

  // Add request interceptor
  void addRequestInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  // Remove request interceptor
  void removeRequestInterceptor(Interceptor interceptor) {
    _dio.interceptors.remove(interceptor);
  }

  // Cancel all requests
  void cancelRequests({String? reason}) {
    _dio.close(force: true);
  }

  // Get current Dio instance for advanced usage
  Dio get dio => _dio;
}

// Singleton instance
final apiClient = APIClient();