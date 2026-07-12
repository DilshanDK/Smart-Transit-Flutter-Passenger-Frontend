import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class TicketRepository {
  final ApiClient _apiClient = ApiClient();

  Future<String> fetchQrToken() async {
    try {
      final response = await _apiClient.dio.get('/journey/qr-token');
      if (response.statusCode == 200) {
        return response.data['token'] as String;
      }
      throw Exception('Failed to get ticket token');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to get ticket token');
    } catch (_) {
      throw Exception('Error loading ticket');
    }
  }

  Future<Map<String, dynamic>?> getActiveJourney() async {
    try {
      final response = await _apiClient.dio.get('/journey/active');
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
