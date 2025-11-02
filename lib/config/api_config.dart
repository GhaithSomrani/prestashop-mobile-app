import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'app_config.dart';

class APIConfig {
  static final Dio _dio = Dio();

  static Dio get dio {
    _dio.options = BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: Duration(milliseconds: AppConfig.apiTimeout),
      receiveTimeout: Duration(milliseconds: AppConfig.apiTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Basic ${_getEncodedCredentials()}',
      },
    );

    // Add logging interceptor for debug mode
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: true,
        error: true,
      ));
    }

    // Add error handling interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        final errorMessage = _getErrorMessage(error);
        throw ApiException(errorMessage, error.response?.statusCode);
      },
    ));

    return _dio;
  }

  static String _getEncodedCredentials() {
    final credentials = '${AppConfig.apiKey}:';
    return Uri.encodeComponent(credentials);
  }

  static String _getErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network settings.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        switch (statusCode) {
          case 401:
            return 'Authentication failed. Please check your API credentials.';
          case 404:
            return 'Requested resource not found.';
          case 500:
            return 'Server error. Please try again later.';
          default:
            return error.response?.data?['message'] ?? 'An error occurred.';
        }
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}