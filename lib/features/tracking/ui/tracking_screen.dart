// ignore_for_file: unused_import, deprecated_member_use

import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;
import '../data/repositories/tracking_repository.dart';
import '../bloc/tracking_bloc.dart';
import '../bloc/tracking_event.dart';
import '../bloc/tracking_state.dart';

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
  fm.MapController? _osmMapController;
  BitmapDescriptor? _busIcon;
  LatLng? _userLatLng;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _useOpenStreetMap = false;
  bool _isMapLockedToUser = true;
  late final TrackingBloc _trackingBloc;

  // Stores active animation controllers and animated coordinates for each bus
  final Map<String, _BusAnimationHelper> _busAnimations = {};

  @override
  void initState() {
    super.initState();
    _osmMapController = fm.MapController();
    _trackingBloc = TrackingBloc(
      trackingRepository: TrackingRepository(),
    );
    _loadMarkerIcon();
    _requestLocationPermission();
  }

  void _centerMapOnUser() {
    if (_userLatLng == null) return;
    if (_useOpenStreetMap) {
      _osmMapController?.move(
        ll.LatLng(_userLatLng!.latitude, _userLatLng!.longitude),
        15,
      );
    } else {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_userLatLng!, 15),
      );
    }
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

  Future<void> _loadMarkerIcon() async {
    try {
      // Larger icon (72×72) for premium Uber-style visibility
      final icon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(72, 72)),
        'assets/images/bus_circular.png',
      );
      setState(() {
        _busIcon = icon;
      });
    } catch (e) {
      debugPrint('⚠️ Error loading custom bus icon: $e');
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
              final markers = _busAnimations.entries.map((entry) {
                final id = entry.key;
                final helper = entry.value;
                
                final bus = state.buses[id];
                final busNumber = bus?.busNumber ?? 'Bus';

                return Marker(
                  markerId: MarkerId(id),
                  position: helper.currentLatLng,
                  rotation: helper.currentHeading,
                  icon: _busIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                  anchor: const Offset(0.5, 0.5),
                  zIndex: 2,
                  infoWindow: InfoWindow(
                    title: '🚌 $busNumber',
                    snippet: 'Route ${bus?.routeId ?? state.routeId} • ${(bus?.speed ?? 0).toStringAsFixed(0)} km/h',
                  ),
                );
              }).toSet();

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
                                      context.read<TrackingBloc>().add(
                                            StartTrackingRequested(_routeController.text),
                                          );
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _useOpenStreetMap ? '🗺️ OpenStreetMap Active' : '📍 Google Maps Active',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _useOpenStreetMap = !_useOpenStreetMap;
                                });
                              },
                              icon: Icon(
                                _useOpenStreetMap ? Icons.map : Icons.public,
                                size: 14,
                                color: const Color(0xFF28A745),
                              ),
                              label: Text(
                                _useOpenStreetMap ? 'Use Google Maps' : 'Switch to OpenStreetMap',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF28A745),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: widget.isActive
                            ? (_useOpenStreetMap
                                ? fm.FlutterMap(
                                    mapController: _osmMapController,
                                    options: fm.MapOptions(
                                      initialCenter: _userLatLng != null
                                          ? ll.LatLng(_userLatLng!.latitude, _userLatLng!.longitude)
                                          : const ll.LatLng(6.9271, 79.8612), // Colombo Center
                                      initialZoom: 13,
                                      onPositionChanged: (position, hasGesture) {
                                        if (hasGesture && _isMapLockedToUser) {
                                          setState(() {
                                            _isMapLockedToUser = false;
                                          });
                                        }
                                      },
                                    ),
                                    children: [
                                      fm.TileLayer(
                                        urlTemplate: isDark
                                            ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                                            : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                                        userAgentPackageName: 'com.smarttransit.passenger',
                                      ),
                                      fm.CircleLayer(
                                        circles: [
                                          if (_userLatLng != null)
                                            fm.CircleMarker(
                                              point: ll.LatLng(_userLatLng!.latitude, _userLatLng!.longitude),
                                              radius: 300,
                                              useRadiusInMeter: true,
                                              color: const Color(0x22007AFF),
                                              borderColor: const Color(0x88007AFF),
                                              borderStrokeWidth: 2,
                                            ),
                                        ],
                                      ),
                                      fm.MarkerLayer(
                                        markers: [
                                          if (_userLatLng != null)
                                            fm.Marker(
                                              point: ll.LatLng(_userLatLng!.latitude, _userLatLng!.longitude),
                                              width: 60,
                                              height: 60,
                                              child: const _PulsingUserLocationDot(),
                                            ),
                                          ..._busAnimations.entries.map((entry) {
                                            final helper = entry.value;
                                            return fm.Marker(
                                              point: ll.LatLng(helper.currentLatLng.latitude, helper.currentLatLng.longitude),
                                              width: 80,
                                              height: 80,
                                              child: _AnimatedBusMarker(
                                                heading: helper.currentHeading,
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ],
                                  )
                                : Stack(
                                    children: [
                                      IgnorePointer(
                                        ignoring: _mapController == null,
                                        child: GoogleMap(
                                          onMapCreated: _onMapCreated,
                                          initialCameraPosition: CameraPosition(
                                            target: _userLatLng ?? const LatLng(6.9271, 79.8612), // Colombo Center
                                            zoom: 15,
                                          ),
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
                                          onCameraMoveStarted: () {
                                            if (_isMapLockedToUser) {
                                              setState(() {
                                                _isMapLockedToUser = false;
                                              });
                                            }
                                          },
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
                                  ))
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
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Floating action buttons for centering on user and active buses
                  Positioned(
                    bottom: 80,
                    right: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_userLatLng != null) ...[
                          FloatingActionButton(
                            heroTag: 'btn_center_user',
                            mini: true,
                            backgroundColor: _isMapLockedToUser ? const Color(0xFF007AFF) : (isDark ? const Color(0xFF333333) : Colors.white),
                            onPressed: _centerMapOnUser,
                            child: Icon(
                              _isMapLockedToUser ? Icons.gps_fixed : Icons.gps_not_fixed,
                              color: _isMapLockedToUser ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (_busAnimations.isNotEmpty)
                          FloatingActionButton(
                            heroTag: 'btn_center_bus',
                            mini: true,
                            backgroundColor: const Color(0xFF28A745),
                            onPressed: () {
                              final firstAnim = _busAnimations.values.first;
                              if (_useOpenStreetMap) {
                                _osmMapController?.move(
                                  ll.LatLng(firstAnim.currentLatLng.latitude, firstAnim.currentLatLng.longitude),
                                  15,
                                );
                              } else {
                                _mapController?.animateCamera(
                                  CameraUpdate.newLatLngZoom(firstAnim.currentLatLng, 15),
                                );
                              }
                            },
                            child: const Icon(Icons.directions_bus, color: Colors.white, size: 20),
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

// ── Animated Uber-style Bus Marker for OpenStreetMap layer ──────────────────
class _AnimatedBusMarker extends StatefulWidget {
  final double heading;
  const _AnimatedBusMarker({required this.heading});

  @override
  State<_AnimatedBusMarker> createState() => _AnimatedBusMarkerState();
}

class _AnimatedBusMarkerState extends State<_AnimatedBusMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _pulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer pulsing ring — always upright
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, child) => Container(
            width: 80 * _pulse.value,
            height: 80 * _pulse.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF22C55E).withOpacity(0.22 * (1 - _pulse.value)),
            ),
          ),
        ),
        // Inner steady glow — always upright
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF22C55E).withOpacity(0.18),
          ),
        ),
        // Bus capsule — UPRIGHT, never rotated
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x9922C55E),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_bus_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        // Directional heading arrow — ONLY this rotates
        Positioned(
          top: 0,
          child: Transform.rotate(
            angle: widget.heading * (math.pi / 180),
            alignment: Alignment.bottomCenter,
            child: CustomPaint(
              size: const Size(10, 12),
              painter: _HeadingArrowPainter(),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Heading direction arrow painter ─────────────────────────────────────────
class _HeadingArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width / 2, 0)        // tip (top)
      ..lineTo(size.width, size.height)   // bottom-right
      ..lineTo(size.width / 2, size.height * 0.72) // inner notch
      ..lineTo(0, size.height)            // bottom-left
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Pulsing Blue User Location Dot ───────────────────────────────────────────
class _PulsingUserLocationDot extends StatefulWidget {
  const _PulsingUserLocationDot();

  @override
  State<_PulsingUserLocationDot> createState() => _PulsingUserLocationDotState();
}

class _PulsingUserLocationDotState extends State<_PulsingUserLocationDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              width: 48 * _animation.value,
              height: 48 * _animation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF007AFF).withOpacity(1 - _animation.value),
              ),
            );
          },
        ),
        Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 11,
              height: 11,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF007AFF),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
