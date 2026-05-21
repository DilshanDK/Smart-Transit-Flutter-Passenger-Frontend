import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class TicketViewModel extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  String? _qrToken;
  bool _isLoading = false;
  String? _error;
  
  // Timer & Countdown
  Timer? _refreshTimer;
  Timer? _countdownTimer;
  int _secondsRemaining = 30;

  // Active Journey Info
  Map<String, dynamic>? _activeJourney;

  String? get qrToken => _qrToken;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get secondsRemaining => _secondsRemaining;
  Map<String, dynamic>? get activeJourney => _activeJourney;

  void startTokenLoop() {
    fetchQrToken();
    checkActiveJourney();
    
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      fetchQrToken();
    });

    _countdownTimer?.cancel();
    _secondsRemaining = 30;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        _secondsRemaining = 30;
        notifyListeners();
      }
    });
  }

  void stopTokenLoop() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
  }

  Future<void> fetchQrToken() async {
    if (_qrToken == null) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final response = await _apiClient.dio.get('/journey/qr-token');
      if (response.statusCode == 200) {
        _qrToken = response.data['token'];
        _secondsRemaining = 30;
        _error = null;
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to get ticket token';
    } catch (_) {
      _error = 'Error loading ticket';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkActiveJourney() async {
    try {
      final response = await _apiClient.dio.get('/journey/active');
      if (response.statusCode == 200) {
        _activeJourney = response.data;
      } else {
        _activeJourney = null;
      }
    } catch (_) {
      _activeJourney = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    stopTokenLoop();
    super.dispose();
  }
}
