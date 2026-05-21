import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/models.dart';

class WalletViewModel extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  bool _isTopUpLoading = false;
  double _balance = 0.0;
  List<Transaction> _transactions = [];
  String? _error;
  String? _clientSecret; // From Stripe PaymentIntent

  bool get isLoading => _isLoading;
  bool get isTopUpLoading => _isTopUpLoading;
  double get balance => _balance;
  List<Transaction> get transactions => _transactions;
  String? get error => _error;
  String? get clientSecret => _clientSecret;

  Future<void> loadWallet() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load profile for balance
      final profileRes = await _apiClient.dio.get('/auth/me');
      if (profileRes.statusCode == 200) {
        final userJson = profileRes.data['user'] ?? profileRes.data;
        _balance = (userJson['walletBalance'] ?? 0).toDouble();
      }

      // Load transaction history
      final txRes = await _apiClient.dio.get('/payment/transactions');
      if (txRes.statusCode == 200) {
        final list = txRes.data as List;
        _transactions = list.map((j) => Transaction.fromJson(j as Map<String, dynamic>)).toList();
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to load wallet';
    } catch (_) {
      _error = 'An unexpected error occurred';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> createPaymentIntent(double amount) async {
    _isTopUpLoading = true;
    _clientSecret = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        '/payment/intent',
        data: {'amount': amount},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        _clientSecret = response.data['clientSecret'];
        _isTopUpLoading = false;
        notifyListeners();
        return _clientSecret;
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to create payment';
    } catch (_) {
      _error = 'Payment initialization failed';
    }

    _isTopUpLoading = false;
    notifyListeners();
    return null;
  }

  // Called after a successful Stripe payment to refresh balance
  Future<void> refreshBalance() async {
    try {
      final res = await _apiClient.dio.get('/auth/me');
      if (res.statusCode == 200) {
        final userJson = res.data['user'] ?? res.data;
        _balance = (userJson['walletBalance'] ?? 0).toDouble();
        notifyListeners();
      }
    } catch (_) {}
  }
}
