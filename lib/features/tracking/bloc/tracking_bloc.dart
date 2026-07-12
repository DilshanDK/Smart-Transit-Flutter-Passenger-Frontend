import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/bus_location.dart';
import '../data/repositories/tracking_repository.dart';
import 'tracking_event.dart';
import 'tracking_state.dart';

class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  final TrackingRepository trackingRepository;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _errorSubscription;

  TrackingBloc({required this.trackingRepository}) : super(const TrackingState()) {
    on<StartTrackingRequested>(_onStartTrackingRequested);
    on<StopTrackingRequested>(_onStopTrackingRequested);
    on<ConnectionStatusChanged>(_onConnectionStatusChanged);
    on<TrackingErrorReceived>(_onTrackingErrorReceived);
    on<BusLocationReceived>(_onBusLocationReceived);
  }

  Future<void> _onStartTrackingRequested(
    StartTrackingRequested event,
    Emitter<TrackingState> emit,
  ) async {
    if (event.routeId.trim().isEmpty) {
      emit(state.copyWith(error: 'Route ID is required'));
      return;
    }

    emit(state.copyWith(
      routeId: event.routeId.trim(),
      isConnecting: true,
      clearError: true,
    ));

    // Cancel existing subscriptions
    _locationSubscription?.cancel();
    _connectionSubscription?.cancel();
    _errorSubscription?.cancel();

    // Listen to repository streams
    _locationSubscription = trackingRepository.busLocationStream.listen((bus) {
      add(BusLocationReceived(bus));
    });

    _connectionSubscription = trackingRepository.connectionStream.listen((connected) {
      add(ConnectionStatusChanged(connected));
    });

    _errorSubscription = trackingRepository.errorStream.listen((err) {
      if (err != null) {
        add(TrackingErrorReceived(err));
      }
    });

    await trackingRepository.connectAndJoin(event.routeId);
  }

  void _onStopTrackingRequested(StopTrackingRequested event, Emitter<TrackingState> emit) {
    _locationSubscription?.cancel();
    _connectionSubscription?.cancel();
    _errorSubscription?.cancel();
    trackingRepository.disconnect();
    emit(const TrackingState());
  }

  void _onConnectionStatusChanged(ConnectionStatusChanged event, Emitter<TrackingState> emit) {
    emit(state.copyWith(
      isConnected: event.isConnected,
      isConnecting: false,
    ));
  }

  void _onTrackingErrorReceived(TrackingErrorReceived event, Emitter<TrackingState> emit) {
    emit(state.copyWith(
      error: event.error,
      isConnecting: false,
    ));
  }

  void _onBusLocationReceived(BusLocationReceived event, Emitter<TrackingState> emit) {
    final updatedBuses = Map<String, BusLocation>.from(state.buses);
    updatedBuses[event.busLocation.driverId] = event.busLocation;
    emit(state.copyWith(buses: updatedBuses));
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    _connectionSubscription?.cancel();
    _errorSubscription?.cancel();
    trackingRepository.disconnect();
    return super.close();
  }
}
