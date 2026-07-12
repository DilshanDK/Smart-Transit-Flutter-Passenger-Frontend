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
