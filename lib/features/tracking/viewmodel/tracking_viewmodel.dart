import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';

class BusLocation {
  final String driverId;
  final String routeId;
  final String? busNumber;
  final double latitude;
  final double longitude;
  final double heading;
  final double speed;
  final DateTime updatedAt;

  const BusLocation({
    required this.driverId,
    required this.routeId,
    this.busNumber,
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.speed,
    required this.updatedAt,
  });
}

class TrackingViewModel extends ChangeNotifier {
  io.Socket? _socket;
  final Map<String, BusLocation> _buses = {};
  bool _isConnecting = false;
  String? _routeId;
  String? _error;

  bool get isConnecting => _isConnecting;
  bool get isConnected => _socket?.connected ?? false;
  String? get error => _error;
  String? get routeId => _routeId;
  UnmodifiableListView<BusLocation> get buses => UnmodifiableListView(_buses.values);

  Future<void> startTracking(String routeId) async {
    if (routeId.trim().isEmpty) {
      _error = 'Route ID is required';
      notifyListeners();
      return;
    }

    final token = await SecureStorage.getAccessToken();
    if (token == null) {
      _error = 'Missing access token';
      notifyListeners();
      return;
    }

    _routeId = routeId.trim();
    _error = null;
    _isConnecting = true;
    notifyListeners();

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
      _socket?.emit('join_route', {'routeId': _routeId});
      _isConnecting = false;
      notifyListeners();
    });

    _socket?.on('bus_moved', _handleBusMoved);

    _socket?.onDisconnect((_) {
      _isConnecting = false;
      notifyListeners();
    });

    _socket?.on('connect_error', (_) {
      _error = 'Socket connection failed';
      _isConnecting = false;
      notifyListeners();
    });

    _socket?.connect();
  }

  void stopTracking() {
    _socket?.off('bus_moved', _handleBusMoved);
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _buses.clear();
    _routeId = null;
    _isConnecting = false;
    notifyListeners();
  }

  void _handleBusMoved(dynamic data) {
    if (data is! Map) {
      return;
    }

    final payload = Map<String, dynamic>.from(data);
    final driverId = payload['driverId']?.toString() ?? '';
    final routeId = payload['routeId']?.toString() ?? '';
    if (driverId.isEmpty || routeId.isEmpty) {
      return;
    }

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

    _buses[driverId] = bus;
    notifyListeners();
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }

  double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}
