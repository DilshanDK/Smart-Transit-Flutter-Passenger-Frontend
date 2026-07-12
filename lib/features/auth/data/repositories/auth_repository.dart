import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/push_notification_service.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/passenger/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        await SecureStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        await PushNotificationService.instance.registerDeviceToken();
        return data['user'] as Map<String, dynamic>;
      } else {
        throw Exception(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Invalid email or password.');
    } catch (e) {
      throw Exception('An unexpected error occurred during login.');
    }
  }

  Future<Map<String, dynamic>> register(String email, String fullName, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/passenger/register',
        data: {
          'email': email,
          'fullName': fullName,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        await SecureStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        await PushNotificationService.instance.registerDeviceToken();
        return data['user'] as Map<String, dynamic>;
      } else {
        throw Exception(response.data['message'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Registration failed. Please try again.');
    } catch (e) {
      throw Exception('An unexpected error occurred during registration.');
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/auth/logout');
    } catch (_) {
      // Gracefully continue clearing local tokens
    } finally {
      await SecureStorage.clearTokens();
    }
  }

  Future<Map<String, dynamic>?> checkSession() async {
    final token = await SecureStorage.getAccessToken();
    if (token == null) return null;

    try {
      final response = await _apiClient.dio.get('/auth/me');
      if (response.statusCode == 200) {
        await PushNotificationService.instance.registerDeviceToken();
        return response.data['user'] as Map<String, dynamic>;
      }
    } catch (_) {
      await SecureStorage.clearTokens();
    }
    return null;
  }
}
