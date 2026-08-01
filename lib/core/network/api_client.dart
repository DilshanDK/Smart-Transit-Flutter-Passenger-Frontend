// ignore_for_file: unused_import

import 'package:dio/dio.dart';
import 'dart:io';
import '../storage/secure_storage.dart';

class ApiClient {
  late final Dio dio;
  
  // Default to local IP so physical devices on the same WiFi can connect
  static final String baseUrl = 'http://10.140.137.164:4000';

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    // Request & Response Interceptors
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final accessToken = await SecureStorage.getAccessToken();
        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        // Handle connection errors globally
        if (error.type == DioExceptionType.connectionTimeout || 
            error.type == DioExceptionType.connectionError || 
            error.type == DioExceptionType.receiveTimeout) {
          final customError = error.copyWith(
            response: Response(
              requestOptions: error.requestOptions,
              data: {'message': 'Backend connection failed. Please ensure your device is on the same WiFi and the server IP is correct.'},
              statusCode: 503,
            ),
          );
          return handler.next(customError);
        }

        // If error is 401 Unauthorized, try to refresh tokens
        if (error.response?.statusCode == 401) {
          final refreshToken = await SecureStorage.getRefreshToken();
          if (refreshToken != null) {
            try {
              // Create a clean Dio instance to avoid circular interceptor calls
              final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
              final response = await refreshDio.post(
                '/auth/passenger/refresh',
                data: {'refreshToken': refreshToken},
                options: Options(headers: {
                  'Authorization': 'Bearer ${await SecureStorage.getAccessToken()}',
                }),
              );

              if (response.statusCode == 200 || response.statusCode == 201) {
                final newAccess = response.data['accessToken'] as String;
                final newRefresh = response.data['refreshToken'] as String;
                await SecureStorage.saveTokens(accessToken: newAccess, refreshToken: newRefresh);

                // Update original request headers and retry
                error.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
                final retryResponse = await dio.fetch(error.requestOptions);
                return handler.resolve(retryResponse);
              }
            } catch (e) {
              // If refresh token call fails, log out completely
              await SecureStorage.clearTokens();
            }
          }
        }
        return handler.next(error);
      },
    ));
  }
}
