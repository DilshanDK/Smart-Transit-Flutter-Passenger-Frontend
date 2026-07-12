// ignore_for_file: deprecated_member_use

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../data/repositories/tracking_repository.dart';
import '../bloc/tracking_bloc.dart';
import '../bloc/tracking_event.dart';
import '../bloc/tracking_state.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with TickerProviderStateMixin {
  final TextEditingController _routeController = TextEditingController();
  final MapController _mapController = MapController();
  
  // Stores active animation controllers and animated coordinates for each bus
  final Map<String, _BusAnimationHelper> _busAnimations = {};

  @override
  void dispose() {
    _routeController.dispose();
    _mapController.dispose();
    for (final helper in _busAnimations.values) {
      helper.controller.dispose();
    }
    super.dispose();
  }

  // Handles state changes to drive smooth marker movement
  void _handleBusStateUpdate(List<dynamic> buses) {
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TrackingBloc>(
      create: (context) => TrackingBloc(
        trackingRepository: TrackingRepository(),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D0D0D),
          elevation: 0,
          title: Text(
            'Live Tracking',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
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
                final angleRad = helper.currentHeading * (math.pi / 180.0);
                
                final bus = state.buses[id];
                final busNumber = bus?.busNumber ?? 'Bus';

                return Marker(
                  point: helper.currentLatLng,
                  width: 56,
                  height: 64,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF28A745).withOpacity(0.5), width: 1),
                        ),
                        child: Text(
                          busNumber,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Transform.rotate(
                        angle: angleRad,
                        child: Image.asset(
                          'assets/images/bus_circular.png',
                          width: 32,
                          height: 32,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();

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
                                style: GoogleFonts.inter(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Enter Route ID (e.g. 138)',
                                  hintStyle: GoogleFonts.inter(color: Colors.white38),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.05),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.1),
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
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          child: FlutterMap(
                            mapController: _mapController,
                            options: const MapOptions(
                              initialCenter: LatLng(6.9271, 79.8612), // Colombo Center
                              initialZoom: 13,
                              interactionOptions: InteractionOptions(
                                flags: InteractiveFlag.all,
                              ),
                            ),
                            children: [
                              // CartoDB Dark Matter map layer to blend with the app dark theme
                              TileLayer(
                                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                                subdomains: const ['a', 'b', 'c', 'd'],
                                userAgentPackageName: 'smarttransit_flutter_passenger',
                              ),
                              MarkerLayer(markers: markers),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
                        color: const Color(0xFF0D0D0D),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  state.isConnected ? Icons.cloud_done : Icons.cloud_off,
                                  size: 14,
                                  color: state.isConnected ? const Color(0xFF28A745) : Colors.white24,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  state.isConnected ? 'Monitoring Server' : 'Disconnected',
                                  style: GoogleFonts.inter(
                                    color: state.isConnected ? Colors.white70 : Colors.white24,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${buses.length} active buses',
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Floating action button to center map on the first active bus
                  if (_busAnimations.isNotEmpty)
                    Positioned(
                      bottom: 72,
                      right: 16,
                      child: FloatingActionButton(
                        mini: true,
                        backgroundColor: const Color(0xFF28A745),
                        onPressed: () {
                          final firstAnim = _busAnimations.values.first;
                          _mapController.move(firstAnim.currentLatLng, 15);
                        },
                        child: const Icon(Icons.my_location, color: Colors.white, size: 20),
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
