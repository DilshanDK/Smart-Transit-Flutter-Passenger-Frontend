import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'network/api_client.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();
  static bool _isRegistering = false;
  static bool _listenerAttached = false;

  final ApiClient _apiClient = ApiClient();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> registerDeviceToken() async {
    if (_isRegistering) {
      return;
    }

    _isRegistering = true;
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await _messaging.getToken();
      if (token != null) {
        await _apiClient.dio.post('/auth/fcm-token', data: {'token': token});
      }

      if (!_listenerAttached) {
        _listenerAttached = true;
        _messaging.onTokenRefresh.listen((newToken) async {
          try {
            await _apiClient.dio.post('/auth/fcm-token', data: {'token': newToken});
          } catch (error) {
            debugPrint('Failed to refresh FCM token: $error');
          }
        });
      }
    } catch (error) {
      debugPrint('Failed to register FCM token: $error');
    } finally {
      _isRegistering = false;
    }
  }
}
