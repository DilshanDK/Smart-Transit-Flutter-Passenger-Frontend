import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/push_notification_service.dart';

class AuthViewModel extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Map<String, dynamic>? _passengerData;
  Map<String, dynamic>? get passengerData => _passengerData;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> registerPassenger({
    required String email,
    required String fullName,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);

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
        _passengerData = data['user'];
        _setLoading(false);
        return true;
      }
    } on DioException catch (e) {
      _setError(e.response?.data['message'] ?? 'Registration failed. Please try again.');
    } catch (e) {
      _setError('An unexpected error occurred.');
    }

    _setLoading(false);
    return false;
  }

  Future<bool> loginPassenger({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);

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
        _passengerData = data['user'];
        _setLoading(false);
        return true;
      }
    } on DioException catch (e) {
      _setError(e.response?.data['message'] ?? 'Invalid email or password.');
    } catch (e) {
      _setError('An unexpected error occurred.');
    }

    _setLoading(false);
    return false;
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _apiClient.dio.post('/auth/logout');
    } catch (_) {
      // Gracefully continue clearing local tokens
    } finally {
      await SecureStorage.clearTokens();
      _passengerData = null;
      _setLoading(false);
    }
  }

  Future<bool> checkInitialAuth() async {
    final token = await SecureStorage.getAccessToken();
    if (token == null) return false;

    try {
      final response = await _apiClient.dio.get('/auth/me');
      if (response.statusCode == 200) {
        _passengerData = response.data['user'];
        await PushNotificationService.instance.registerDeviceToken();
        notifyListeners();
        return true;
      }
    } catch (_) {
      await SecureStorage.clearTokens();
    }
    return false;
  }
}
