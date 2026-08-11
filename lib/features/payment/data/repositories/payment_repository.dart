// ignore_for_file: avoid_print
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class PaymentRepository {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));

  /// Creates a Stripe Payment Intent on the backend and returns the client secret.
  ///
  /// [amount] is the amount in the smallest currency unit (e.g., cents for USD).
  /// [currency] defaults to 'usd'.
  /// [metadata] optional map of additional metadata.
  Future<String> createPaymentIntent({required int amount, String currency = 'usd', Map<String, dynamic>? metadata}) async {
    final response = await _dio.post('/payments/create-intent', data: {
      'amount': amount,
      'currency': currency,
      'metadata': metadata ?? {},
    });
    return response.data['clientSecret'] as String;
  }
}
