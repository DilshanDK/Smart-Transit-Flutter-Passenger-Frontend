// ignore_for_file: unused_import, deprecated_member_use

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/network/api_client.dart';
import '../data/repositories/tracking_repository.dart';
import '../bloc/tracking_bloc.dart';
import '../bloc/tracking_event.dart';
import '../bloc/tracking_state.dart';

class _RouteStopData {
  final String name;
  final double distanceFromStart;
  final LatLng latLng;

  const _RouteStopData({
    required this.name,
    required this.distanceFromStart,
    required this.latLng,
  });
}

const List<LatLng> _fallback593Polyline = [
  LatLng(7.2906, 80.6337), // Kandy
  LatLng(7.3248, 80.6225), // Katugastota
  LatLng(7.3686, 80.6186), // Akurana
  LatLng(7.4111, 80.6033), // Alawathugoda
  LatLng(7.4475, 80.6094), // Alwala (Elwala)
  LatLng(7.4675, 80.6234), // Matale
];

const List<_RouteStopData> _fallback593Stops = [
  _RouteStopData(name: 'Kandy', distanceFromStart: 0.0, latLng: LatLng(7.2906, 80.6337)),
  _RouteStopData(name: 'Katugastota', distanceFromStart: 4.0, latLng: LatLng(7.3248, 80.6225)),
  _RouteStopData(name: 'Akurana', distanceFromStart: 10.9, latLng: LatLng(7.3686, 80.6186)),
  _RouteStopData(name: 'Alawathugoda', distanceFromStart: 16.5, latLng: LatLng(7.4111, 80.6033)),
  _RouteStopData(name: 'Alwala (Elwala)', distanceFromStart: 21.7, latLng: LatLng(7.4475, 80.6094)),
  _RouteStopData(name: 'Matale', distanceFromStart: 25.7, latLng: LatLng(7.4675, 80.6234)),
];

class TrackingScreen extends StatefulWidget {
  final bool showBackButton;
  final bool isActive;
  const TrackingScreen({
    super.key,
    this.showBackButton = true,
    this.isActive = true,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with TickerProviderStateMixin {
  final TextEditingController _routeController = TextEditingController(text: '593');
  GoogleMapController? _mapController;
  BitmapDescriptor? _busBadgeIcon;
  BitmapDescriptor? _busArrowIcon;
  BitmapDescriptor? _stopIcon;
  List<LatLng> _routePolyline = [];
  List<_RouteStopData> _routeStops = [];
  LatLng? _userLatLng;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isMapLockedToUser = false;
  bool _isMapLockedToBus = true; // Auto-focus bus by default
  bool _hasInitialBusFocusDone = false;
  int _lastCameraFollowMs = 0;
  late final TrackingBloc _trackingBloc;

  // Stores active animation controllers and animated coordinates for each bus
  final Map<String, _BusAnimationHelper> _busAnimations = {};

  @override
  void initState() {
    super.initState();
    _trackingBloc = TrackingBloc(
      trackingRepository: TrackingRepository(),
    );
    _loadMarkerIcons();
    _requestLocationPermission();
    _fetchRouteData(_routeController.text);
    // Auto-connect telemetry for Route 593
    _trackingBloc.add(StartTrackingRequested(_routeController.text));
  }

  void _centerMapOnUser() {
    if (_userLatLng == null) return;
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_userLatLng!, 15),
    );
  }

  Future<void> _requestLocationPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // Listen to active position stream updates
        _positionStreamSubscription?.cancel();
        _positionStreamSubscription = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          if (mounted) {
            setState(() {
              _userLatLng = LatLng(position.latitude, position.longitude);
              if (_isMapLockedToUser) {
                _centerMapOnUser();
              }
            });
          }
        });

        // Fetch initial location
        final pos = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _userLatLng = LatLng(pos.latitude, pos.longitude);
            if (_isMapLockedToUser) {
              _centerMapOnUser();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ Location permission error: $e');
    }
  }

  /// Fetches route corridor path & stops from backend API
  Future<void> _fetchRouteData(String routeId) async {
    final cleanId = routeId.trim().toUpperCase();
    try {
      final response = await ApiClient().dio.get('/routes/$cleanId');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final List<LatLng> polyline = [];
        final List<_RouteStopData> stops = [];

        // Parse polyline path coordinates [[lng, lat], ...]
        if (data['path'] != null && data['path']['coordinates'] is List) {
          final coords = data['path']['coordinates'] as List;
          for (final c in coords) {
            if (c is List && c.length >= 2) {
              final lng = (c[0] as num).toDouble();
              final lat = (c[1] as num).toDouble();
              polyline.add(LatLng(lat, lng));
            }
          }
        }

        // Parse transit stops
        if (data['stops'] is List) {
          final rawStops = data['stops'] as List;
          for (final s in rawStops) {
            if (s is Map && s['location'] != null && s['location']['coordinates'] is List) {
              final coords = s['location']['coordinates'] as List;
              final lng = (coords[0] as num).toDouble();
              final lat = (coords[1] as num).toDouble();
              final name = s['name']?.toString() ?? 'Stop';
              final dist = (s['distanceFromStart'] as num?)?.toDouble() ?? 0.0;
              stops.add(_RouteStopData(
                name: name,
                distanceFromStart: dist,
                latLng: LatLng(lat, lng),
              ));
            }
          }
        }

        if (mounted) {
          setState(() {
            _routePolyline = polyline.isNotEmpty ? polyline : (cleanId == '593' ? _fallback593Polyline : []);
            _routeStops = stops.isNotEmpty ? stops : (cleanId == '593' ? _fallback593Stops : []);
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching route corridor: $e');
    }

    if (mounted && cleanId == '593' && _routePolyline.isEmpty) {
      setState(() {
        _routePolyline = _fallback593Polyline;
        _routeStops = _fallback593Stops;
      });
    }
  }

  /// Focuses map camera on the leading bus
  void _focusOnBus({bool forceZoom = true}) {
    if (_busAnimations.isEmpty) return;
    final first = _busAnimations.values.first;
    final target = first.currentLatLng;

    setState(() {
      _isMapLockedToBus = true;
      _isMapLockedToUser = false;
    });

    _mapController?.animateCamera(
      forceZoom
          ? CameraUpdate.newLatLngZoom(target, 15.0)
          : CameraUpdate.newLatLng(target),
    );
  }

  /// Generates red stop pin icon
  Future<BitmapDescriptor> _createStopIcon() async {
    const double size = 48.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

    final shadowPaint = Paint()
      ..color = const Color(0x55000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(const Offset(size / 2, size / 2 + 2), 12, shadowPaint);

    final fillPaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawCircle(const Offset(size / 2, size / 2), 12, fillPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(const Offset(size / 2, size / 2), 12, borderPaint);

    final innerDot = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(size / 2, size / 2), 4, innerDot);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(bytes, size: const Size(24, 24));
  }

  /// Loads custom marker bitmaps:
  /// 1. `_busBadgeIcon`: Upright circular emerald badge with bus icon (NEVER ROTATES)
  /// 2. `_busArrowIcon`: Directional arrow header that rotates with bus heading
  /// 3. `_stopIcon`: Transit stop pin
  Future<void> _loadMarkerIcons() async {
    try {
      const double size = 110.0;
      const double cx = size / 2; // 55.0
      const double cy = size / 2; // 55.0
      const double badgeRadius = 26.0;

      // ── 1. Bus Badge Icon (ALWAYS UPRIGHT, NEVER ROTATED) ──
      {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

        // Subtle glow drop shadow
        final shadowPaint = Paint()
          ..color = const Color(0x6610B981)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(const Offset(cx, cy + 3), badgeRadius + 2, shadowPaint);

        // Emerald radial gradient (#10B981 -> #059669)
        final gradient = ui.Gradient.radial(
          const Offset(cx - 6, cy - 6),
          badgeRadius * 1.5,
          [const Color(0xFF10B981), const Color(0xFF059669)],
        );
        canvas.drawCircle(const Offset(cx, cy), badgeRadius, Paint()..shader = gradient);

        // White border
        canvas.drawCircle(
          const Offset(cx, cy),
          badgeRadius,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );

        // White bus icon centered
        final iconPainter = TextPainter(textDirection: ui.TextDirection.ltr)
          ..text = TextSpan(
            text: String.fromCharCode(Icons.directions_bus_rounded.codePoint),
            style: TextStyle(
              fontSize: 28,
              fontFamily: Icons.directions_bus_rounded.fontFamily,
              color: Colors.white,
            ),
          )
          ..layout();
        iconPainter.paint(
          canvas,
          Offset(cx - iconPainter.width / 2, cy - iconPainter.height / 2),
        );

        final picture = recorder.endRecording();
        final image = await picture.toImage(size.toInt(), size.toInt());
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          _busBadgeIcon = BitmapDescriptor.fromBytes(
            byteData.buffer.asUint8List(),
            size: const Size(55, 55),
          );
        }
      }

      // ── 2. Heading Arrow Icon (ROTATES VIA GOOGLE MAPS rotation:) ──
      {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

        // Arrow pointing North (heading 0°). Center of rotation is (cx, cy) = (55, 55).
        final arrowPath = Path()
          ..moveTo(cx, 13)                  // tip
          ..lineTo(cx + 6.5, 27)             // bottom-right
          ..lineTo(cx, 22.5)                 // inner notch
          ..lineTo(cx - 6.5, 27)             // bottom-left
          ..close();

        final arrowFill = Paint()..color = const Color(0xFF22C55E);
        final arrowStroke = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round;

        canvas.drawPath(arrowPath, arrowFill);
        canvas.drawPath(arrowPath, arrowStroke);

        final picture = recorder.endRecording();
        final image = await picture.toImage(size.toInt(), size.toInt());
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          _busArrowIcon = BitmapDescriptor.fromBytes(
            byteData.buffer.asUint8List(),
            size: const Size(55, 55),
          );
        }
      }

      // ── 3. Stop Pin Icon ──
      _stopIcon = await _createStopIcon();

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('⚠️ Error generating marker icons: $e');
    }
  }

  @override
  void dispose() {
    _routeController.dispose();
    _mapController?.dispose();
    _positionStreamSubscription?.cancel();
    _trackingBloc.close();
    for (final helper in _busAnimations.values) {
      helper.controller.dispose();
    }
    super.dispose();
  }

  // Handles state changes to drive smooth marker movement
  void _handleBusStateUpdate(List<dynamic> buses) {
    if (!widget.isActive) return;
    // 1. Remove animations for buses that have disconnected
    final activeIds = buses.map((b) => b.driverId as String).toSet();
    final expiredIds = _busAnimations.keys.where((id) => !activeIds.contains(id)).toList();
    for (final id in expiredIds) {
      _busAnimations[id]?.controller.dispose();
      _busAnimations.remove(id);
    }

    if (buses.isEmpty) {
      setState(() {});
      return;
    }

    // 2. Setup or update animations
    for (final bus in buses) {
      final id = bus.driverId as String;
      final targetLatLng = LatLng(bus.latitude, bus.longitude);
      final targetHeading = bus.heading.toDouble();

      if (!_busAnimations.containsKey(id)) {
        // Create new animation helper for new bus
        final controller = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 4), // matches the 4s socket interval
        );
        
        final helper = _BusAnimationHelper(
          controller: controller,
          previousLatLng: targetLatLng,
          targetLatLng: targetLatLng,
          previousHeading: targetHeading,
          targetHeading: targetHeading,
        );

        controller.addListener(() {
          final t = controller.value;
          setState(() {
            // Interpolate coordinate
            helper.currentLatLng = LatLng(
              helper.previousLatLng.latitude + (helper.targetLatLng.latitude - helper.previousLatLng.latitude) * t,
              helper.previousLatLng.longitude + (helper.targetLatLng.longitude - helper.previousLatLng.longitude) * t,
            );
            // Interpolate heading
            helper.currentHeading = helper.previousHeading + (helper.targetHeading - helper.previousHeading) * t;
          });

          // Auto-lock camera to bus when in bus-follow mode (throttled to 1s to prevent frame skips)
          if (_isMapLockedToBus && _busAnimations.isNotEmpty) {
            final now = DateTime.now().millisecondsSinceEpoch;
            if (now - _lastCameraFollowMs > 1000) {
              _lastCameraFollowMs = now;
              _focusOnBus(forceZoom: false);
            }
          }
        });

        _busAnimations[id] = helper;
      } else {
        // Update existing helper with new endpoint coordinates
        final helper = _busAnimations[id]!;
        if (helper.targetLatLng != targetLatLng || helper.targetHeading != targetHeading) {
          helper.previousLatLng = helper.currentLatLng;
          helper.targetLatLng = targetLatLng;
          helper.previousHeading = helper.currentHeading;
          helper.targetHeading = targetHeading;
          helper.controller.forward(from: 0.0);
        }
      }
    }

    // Initial zoom-in to bus location on first telemetry arrival
    if (_isMapLockedToBus && buses.isNotEmpty && !_hasInitialBusFocusDone) {
      _hasInitialBusFocusDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusOnBus(forceZoom: true);
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _mapController = controller;
    });
    if (Theme.of(context).brightness == Brightness.dark) {
      _mapController?.setMapStyle(_darkMapStyle);
    }
    if (_userLatLng != null && _isMapLockedToUser) {
      _centerMapOnUser();
    }
  }

  @override
  void didUpdateWidget(covariant TrackingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActive && oldWidget.isActive) {
      // Map widget is being disposed, null out controller reference immediately
      _mapController = null;
    }
    if (widget.isActive && !oldWidget.isActive) {
      // User switched back to the tracking tab - force coordinate refresh and focus lock!
      setState(() {
        _isMapLockedToUser = true;
      });
      _requestLocationPermission();

      if (_mapController != null && Theme.of(context).brightness == Brightness.dark) {
        _mapController?.setMapStyle(_darkMapStyle);
      }
      try {
        final bloc = context.read<TrackingBloc>();
        _handleBusStateUpdate(bloc.state.buses.values.toList());
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider<TrackingBloc>.value(
      value: _trackingBloc,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF9F9FE),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF9F9FE),
          elevation: 0,
          title: Text(
            'Live Tracking',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
          ),
          leading: widget.showBackButton
              ? IconButton(
                  icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
        ),
        body: BlocListener<TrackingBloc, TrackingState>(
          listener: (context, state) {
            _handleBusStateUpdate(state.buses.values.toList());
          },
          child: BlocBuilder<TrackingBloc, TrackingState>(
            builder: (context, state) {
              final buses = state.buses.values.toList();

              // Map animators to active Marker instances
              final markers = <Marker>{};

              // 1. Live Bus Markers (Upright Badge + Rotating Arrow Header)
              for (final entry in _busAnimations.entries) {
                final id = entry.key;
                final helper = entry.value;
                final bus = state.buses[id];
                final busNumber = bus?.busNumber ?? 'WP-GA-9021';

                // Upright Bus Badge (NEVER ROTATED, stays straight up)
                markers.add(
                  Marker(
                    markerId: MarkerId('${id}_badge'),
                    position: helper.currentLatLng,
                    rotation: 0.0, // Stays upright at all times
                    flat: false,
                    anchor: const Offset(0.5, 0.5),
                    icon: _busBadgeIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                    zIndex: 4,
                    consumeTapEvents: true,
                    infoWindow: InfoWindow(
                      title: '🚌 $busNumber • ${(bus?.speed ?? 0).toStringAsFixed(0)} km/h',
                      snippet: 'Route ${bus?.routeId ?? state.routeId} — tap to lock camera',
                      onTap: () {
                        _focusOnBus(forceZoom: true);
                      },
                    ),
                  ),
                );

                // Rotating Heading Arrow (Only this arrow rotates to follow vehicle heading)
                if (_busArrowIcon != null) {
                  markers.add(
                    Marker(
                      markerId: MarkerId('${id}_arrow'),
                      position: helper.currentLatLng,
                      rotation: helper.currentHeading, // Only the arrow rotates!
                      flat: true,
                      anchor: const Offset(0.5, 0.5),
                      icon: _busArrowIcon!,
                      zIndex: 5,
                    ),
                  );
                }
              }

              // 2. Transit Stop Markers
              for (final stop in _routeStops) {
                markers.add(
                  Marker(
                    markerId: MarkerId('stop_${stop.name}'),
                    position: stop.latLng,
                    icon: _stopIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    anchor: const Offset(0.5, 0.5),
                    zIndex: 2,
                    infoWindow: InfoWindow(
                      title: '🚏 ${stop.name}',
                      snippet: '${stop.distanceFromStart.toStringAsFixed(1)} km from start',
                    ),
                  ),
                );
              }

              // Pulsing green ring circles for each live bus (Uber-style glow)
              final busCircles = _busAnimations.entries.expand((entry) {
                final helper = entry.value;
                return [
                  Circle(
                    circleId: CircleId('bus_ring_outer_${entry.key}'),
                    center: helper.currentLatLng,
                    radius: 120,
                    fillColor: const Color(0x1A22C55E),
                    strokeColor: const Color(0x5522C55E),
                    strokeWidth: 2,
                    zIndex: 1,
                  ),
                  Circle(
                    circleId: CircleId('bus_ring_inner_${entry.key}'),
                    center: helper.currentLatLng,
                    radius: 60,
                    fillColor: const Color(0x3322C55E),
                    strokeColor: const Color(0x8822C55E),
                    strokeWidth: 1,
                    zIndex: 1,
                  ),
                ];
              }).toSet();

              // User location is natively rendered as a pulsing blue dot using myLocationEnabled: true

              return Stack(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _routeController,
                                style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87),
                                decoration: InputDecoration(
                                  hintText: 'Enter Route ID (e.g. 593)',
                                  hintStyle: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38),
                                  filled: true,
                                  fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.06),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.06),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: state.isConnecting
                                  ? null
                                  : () {
                                      final routeId = _routeController.text.trim();
                                      context.read<TrackingBloc>().add(
                                            StartTrackingRequested(routeId),
                                          );
                                      _fetchRouteData(routeId);
                                      setState(() {
                                        _hasInitialBusFocusDone = false;
                                        _isMapLockedToBus = true;
                                        _isMapLockedToUser = false;
                                      });
                                      _focusOnBus(forceZoom: true);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF28A745),
                                minimumSize: const Size(80, 48), // Overrides the global infinite width theme
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                state.isConnecting ? '...' : 'Track',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Text(
                            state.error!,
                            style: GoogleFonts.inter(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: widget.isActive
                            ? Stack(
                                children: [
                                  IgnorePointer(
                                    ignoring: _mapController == null,
                                    child: Listener(
                                      onPointerDown: (_) {
                                        // Release map lock on manual user drag
                                        if (_isMapLockedToUser || _isMapLockedToBus) {
                                          setState(() {
                                            _isMapLockedToUser = false;
                                            _isMapLockedToBus = false;
                                          });
                                        }
                                      },
                                      child: GoogleMap(
                                        onMapCreated: _onMapCreated,
                                        initialCameraPosition: CameraPosition(
                                          target: _userLatLng ?? const LatLng(7.4675, 80.6234), // Route 593 Corridor Center
                                          zoom: 14,
                                        ),
                                        polylines: {
                                          if (_routePolyline.isNotEmpty)
                                            Polyline(
                                              polylineId: const PolylineId('route_corridor_polyline'),
                                              points: _routePolyline,
                                              color: const Color(0xFF3B82F6),
                                              width: 5,
                                              geodesic: true,
                                              jointType: JointType.round,
                                              startCap: Cap.roundCap,
                                              endCap: Cap.roundCap,
                                            ),
                                        },
                                        markers: markers,
                                        circles: {
                                          if (_userLatLng != null)
                                            Circle(
                                              circleId: const CircleId('user_radius'),
                                              center: _userLatLng!,
                                              radius: 300,
                                              fillColor: const Color(0x22007AFF),
                                              strokeColor: const Color(0x88007AFF),
                                              strokeWidth: 2,
                                            ),
                                          ...busCircles,
                                        },
                                        myLocationEnabled: _userLatLng != null,
                                        myLocationButtonEnabled: false,
                                        zoomControlsEnabled: false,
                                      ),
                                    ),
                                  ),
                                  if (_mapController == null)
                                    Container(
                                      color: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF9F9FE),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const CircularProgressIndicator(
                                              color: Color(0xFF28A745),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Initializing Live Map...',
                                              style: GoogleFonts.inter(
                                                color: isDark ? Colors.white70 : Colors.black87,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              )
                            : Container(
                                color: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF9F9FE),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF28A745),
                                  ),
                                ),
                              ),
                      ),

                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
                        color: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF9F9FE),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  state.isConnected ? Icons.cloud_done : Icons.cloud_off,
                                  size: 14,
                                  color: state.isConnected ? const Color(0xFF28A745) : (isDark ? Colors.white24 : Colors.black26),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  state.isConnected ? 'Monitoring Server' : 'Disconnected',
                                  style: GoogleFonts.inter(
                                    color: state.isConnected ? (isDark ? Colors.white70 : Colors.black87) : (isDark ? Colors.white24 : Colors.black26),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${buses.length} active buses',
                              style: GoogleFonts.inter(
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Floating action buttons
                  Positioned(
                    bottom: 80,
                    right: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── User GPS lock ──
                        if (_userLatLng != null) ...[
                          FloatingActionButton(
                            heroTag: 'btn_center_user',
                            mini: true,
                            backgroundColor: _isMapLockedToUser
                                ? const Color(0xFF007AFF)
                                : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
                            elevation: 4,
                            onPressed: () {
                              setState(() {
                                _isMapLockedToUser = true;
                                _isMapLockedToBus = false;
                              });
                              _centerMapOnUser();
                            },
                            child: Icon(
                              _isMapLockedToUser ? Icons.gps_fixed : Icons.gps_not_fixed,
                              color: _isMapLockedToUser ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        // ── Bus lock toggle — green when locked, dark when unlocked ──
                        if (_busAnimations.isNotEmpty)
                          FloatingActionButton(
                            heroTag: 'btn_center_bus',
                            mini: true,
                            backgroundColor: _isMapLockedToBus
                                ? const Color(0xFF28A745)
                                : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
                            elevation: 4,
                            onPressed: () {
                              final wasLocked = _isMapLockedToBus;
                              if (wasLocked) {
                                setState(() {
                                  _isMapLockedToBus = false;
                                });
                              } else {
                                _focusOnBus(forceZoom: true);
                              }
                            },
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Icon(
                                _isMapLockedToBus ? Icons.directions_bus : Icons.directions_bus_filled,
                                key: ValueKey(_isMapLockedToBus),
                                color: _isMapLockedToBus ? Colors.white : (isDark ? Colors.white60 : Colors.black45),
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// Animation configuration object for interpolating bus updates
class _BusAnimationHelper {
  final AnimationController controller;
  LatLng previousLatLng;
  LatLng targetLatLng;
  double previousHeading;
  double targetHeading;
  LatLng currentLatLng;
  double currentHeading;

  _BusAnimationHelper({
    required this.controller,
    required this.previousLatLng,
    required this.targetLatLng,
    required this.previousHeading,
    required this.targetHeading,
  })  : currentLatLng = previousLatLng,
        currentHeading = previousHeading;
}

// Custom dark map theme JSON
const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#212121"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#212121"
      }
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "administrative.country",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#bdbdbd"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#181818"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#1b1b1b"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [
      {
        "color": "#2c2c2c"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#8a8a8a"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry.fill",
    "stylers": [
      {
        "color": "#373737"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.fill",
    "stylers": [
      {
        "color": "#3c3c3c"
      }
    ]
  },
  {
    "featureType": "road.highway.controlled_access",
    "elementType": "geometry.fill",
    "stylers": [
      {
        "color": "#4e4e4e"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "featureType": "transit",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#000000"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#3d3d3d"
      }
    ]
  }
]
''';
