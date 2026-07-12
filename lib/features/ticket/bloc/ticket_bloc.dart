import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/ticket_repository.dart';
import 'ticket_event.dart';
import 'ticket_state.dart';

class TicketBloc extends Bloc<TicketEvent, TicketState> {
  final TicketRepository ticketRepository;
  Timer? _refreshTimer;
  Timer? _countdownTimer;

  TicketBloc({required this.ticketRepository}) : super(const TicketState()) {
    on<StartTicketLoop>(_onStartTicketLoop);
    on<StopTicketLoop>(_onStopTicketLoop);
    on<TickTimer>(_onTickTimer);
    on<FetchTokenRequested>(_onFetchTokenRequested);
    on<CheckActiveJourneyRequested>(_onCheckActiveJourneyRequested);
  }

  Future<void> _onStartTicketLoop(StartTicketLoop event, Emitter<TicketState> emit) async {
    add(const FetchTokenRequested());
    add(const CheckActiveJourneyRequested());

    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      add(const FetchTokenRequested());
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const TickTimer());
    });
  }

  Future<void> _onStopTicketLoop(StopTicketLoop event, Emitter<TicketState> emit) async {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
  }

  Future<void> _onTickTimer(TickTimer event, Emitter<TicketState> emit) async {
    if (state.secondsRemaining > 1) {
      emit(state.copyWith(secondsRemaining: state.secondsRemaining - 1));
    } else {
      emit(state.copyWith(secondsRemaining: 30));
    }
  }

  Future<void> _onFetchTokenRequested(FetchTokenRequested event, Emitter<TicketState> emit) async {
    if (state.qrToken == null) {
      emit(state.copyWith(isLoading: true));
    }

    try {
      final token = await ticketRepository.fetchQrToken();
      emit(state.copyWith(
        qrToken: token,
        secondsRemaining: 30,
        isLoading: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
        isLoading: false,
      ));
    }
  }

  Future<void> _onCheckActiveJourneyRequested(
    CheckActiveJourneyRequested event,
    Emitter<TicketState> emit,
  ) async {
    final active = await ticketRepository.getActiveJourney();
    emit(state.copyWith(activeJourney: active, clearActiveJourney: active == null));
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    return super.close();
  }
}
