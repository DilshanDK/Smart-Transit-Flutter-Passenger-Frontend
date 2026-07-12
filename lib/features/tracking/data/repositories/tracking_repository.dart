import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/bus_location.dart';

class TrackingRepository {
  io.Socket? _socket;
  final StreamController<BusLocation> _locationController = StreamController<BusLocation>.broadcast();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  final StreamController<String?> _errorController = StreamController<String?>.broadcast();

  Stream<BusLocation> get busLocationStream => _locationController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<String?> get errorStream => _errorController.stream;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connectAndJoin(String routeId) async {
    final token = await SecureStorage.getAccessToken();
    if (token == null) {
      _errorController.add('Missing access token');
      return;
    }

    _socket?.disconnect();
    _socket?.dispose();

    _socket = io.io(
      '${ApiClient.baseUrl}/tracking',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket?.onConnect((_) {
      _connectionController.add(true);
      _socket?.emit('join_route', {'routeId': routeId.trim()});
    });

    _socket?.on('bus_moved', _handleBusMoved);

    _socket?.onDisconnect((_) {
      _connectionController.add(false);
    });

    _socket?.on('connect_error', (_) {
      _errorController.add('Socket connection failed');
      _connectionController.add(false);
    });

    _socket?.connect();
  }

  void disconnect() {
    _socket?.off('bus_moved');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void _handleBusMoved(dynamic data) {
    if (data is! Map) return;

    try {
      final payload = Map<String, dynamic>.from(data);
      final driverId = payload['driverId']?.toString() ?? '';
      final routeId = payload['routeId']?.toString() ?? '';
      if (driverId.isEmpty || routeId.isEmpty) return;

      final bus = BusLocation(
        driverId: driverId,
        routeId: routeId,
        busNumber: payload['busNumber']?.toString(),
        latitude: _asDouble(payload['latitude']),
        longitude: _asDouble(payload['longitude']),
        heading: _asDouble(payload['heading']),
        speed: _asDouble(payload['speed']),
        updatedAt: DateTime.tryParse(payload['updatedAt'] ?? '') ?? DateTime.now(),
      );

      _locationController.add(bus);
    } catch (_) {}
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
