import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/models/models.dart';
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/storage/secure_storage.dart';

class WalletRepository {
  final ApiClient _apiClient = ApiClient();
  io.Socket? _socket;
  final _balanceUpdateController = StreamController<double>.broadcast();

  Stream<double> get balanceUpdates => _balanceUpdateController.stream;

  Future<void> connectNotifications() async {
    final token = await SecureStorage.getAccessToken();
    if (token == null) return;

    _socket?.disconnect();
    _socket?.dispose();

    _socket = io.io(
      '${ApiClient.baseUrl}/notifications',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .build(),
    );

    _socket?.on('wallet_updated', (data) {
      if (data != null && data['balance'] != null) {
        final rawBalance = data['balance'];
        double? newBalance;
        if (rawBalance is num) {
          newBalance = rawBalance.toDouble();
        } else if (rawBalance is String) {
          newBalance = double.tryParse(rawBalance);
        } else if (rawBalance is Map && rawBalance.containsKey(r'$numberDecimal')) {
          newBalance = double.tryParse(rawBalance[r'$numberDecimal'].toString());
        }
        if (newBalance != null) {
          _balanceUpdateController.add(newBalance);
        }
      }
    });
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _balanceUpdateController.close();
  }

  Future<double> getBalance() async {
    try {
      final response = await _apiClient.dio.get('/auth/me');
      if (response.statusCode == 200) {
        final userJson = response.data['user'] ?? response.data;
        final rawBalance = userJson['walletBalance'];
        
        if (rawBalance == null) return 0.0;
        if (rawBalance is num) return rawBalance.toDouble();
        if (rawBalance is String) return double.tryParse(rawBalance) ?? 0.0;
        if (rawBalance is Map && rawBalance.containsKey(r'$numberDecimal')) {
          return double.tryParse(rawBalance[r'$numberDecimal'].toString()) ?? 0.0;
        }
        return 0.0;
      }
      throw Exception('Failed to get balance');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to get balance');
    } catch (e) {
      throw Exception('An unexpected error occurred while fetching balance.');
    }
  }

  Future<List<Transaction>> getTransactions() async {
    try {
      final response = await _apiClient.dio.get('/payment/transactions');
      if (response.statusCode == 200) {
        final list = response.data as List;
        return list.map((j) => Transaction.fromJson(j as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to load transaction history');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to load transaction history');
    } catch (e) {
      throw Exception('An unexpected error occurred while fetching transactions.');
    }
  }

  Future<String> createPaymentIntent(double amount) async {
    try {
      final response = await _apiClient.dio.post(
        '/payment/intent',
        data: {'amount': amount},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['clientSecret'] as String;
      }
      throw Exception('Failed to create payment intent');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to create payment intent');
    } catch (e) {
      throw Exception('Payment initialization failed');
    }
  }
}
