import '../data/models/bus_location.dart';

abstract class TrackingEvent {
  const TrackingEvent();
}

class StartTrackingRequested extends TrackingEvent {
  final String routeId;
  const StartTrackingRequested(this.routeId);
}

class StopTrackingRequested extends TrackingEvent {
  const StopTrackingRequested();
}

class ConnectionStatusChanged extends TrackingEvent {
  final bool isConnected;
  const ConnectionStatusChanged(this.isConnected);
}

class TrackingErrorReceived extends TrackingEvent {
  final String error;
  const TrackingErrorReceived(this.error);
}

class BusLocationReceived extends TrackingEvent {
  final BusLocation busLocation;
  const BusLocationReceived(this.busLocation);
}
