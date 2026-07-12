import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/models/models.dart';

class WalletRepository {
  final ApiClient _apiClient = ApiClient();

  Future<double> getBalance() async {
    try {
      final response = await _apiClient.dio.get('/auth/me');
      if (response.statusCode == 200) {
        final userJson = response.data['user'] ?? response.data;
        return (userJson['walletBalance'] ?? 0).toDouble();
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
