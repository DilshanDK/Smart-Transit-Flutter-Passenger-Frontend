import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/models.dart';

class HomeViewModel extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = true;
  PassengerProfile? _profile;
  String? _error;

  bool get isLoading => _isLoading;
  PassengerProfile? get profile => _profile;
  String? get error => _error;

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/auth/me');
      if (response.statusCode == 200) {
        final data = response.data;
        // Backend may return {user: {...}} or just the user directly
        final userJson = data['user'] ?? data;
        _profile = PassengerProfile.fromJson(userJson as Map<String, dynamic>);
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to load profile';
    } catch (_) {
      _error = 'An unexpected error occurred';
    }

    _isLoading = false;
    notifyListeners();
  }
}
