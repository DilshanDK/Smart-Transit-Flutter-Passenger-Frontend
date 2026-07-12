import '../data/models/bus_location.dart';

class TrackingState {
  final Map<String, BusLocation> buses;
  final bool isConnecting;
  final bool isConnected;
  final String? routeId;
  final String? error;

  const TrackingState({
    this.buses = const {},
    this.isConnecting = false,
    this.isConnected = false,
    this.routeId,
    this.error,
  });

  TrackingState copyWith({
    Map<String, BusLocation>? buses,
    bool? isConnecting,
    bool? isConnected,
    String? routeId,
    String? error,
    bool clearError = false,
    bool clearRouteId = false,
  }) {
    return TrackingState(
      buses: buses ?? this.buses,
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      routeId: clearRouteId ? null : (routeId ?? this.routeId),
      error: clearError ? null : (error ?? this.error),
    );
  }
}
