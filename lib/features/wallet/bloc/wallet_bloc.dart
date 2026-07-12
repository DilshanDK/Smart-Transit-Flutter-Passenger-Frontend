import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smarttransit_flutter_passenger/core/models/models.dart';
import '../data/repositories/wallet_repository.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletRepository walletRepository;

  WalletBloc({required this.walletRepository}) : super(const WalletInitial()) {
    on<LoadWalletRequested>(_onLoadWalletRequested);
    on<CreatePaymentIntentRequested>(_onCreatePaymentIntentRequested);
    on<RefreshBalanceRequested>(_onRefreshBalanceRequested);
  }

  Future<void> _onLoadWalletRequested(LoadWalletRequested event, Emitter<WalletState> emit) async {
    emit(const WalletLoading());
    try {
      final balance = await walletRepository.getBalance();
      final transactions = await walletRepository.getTransactions();
      emit(WalletLoaded(balance: balance, transactions: transactions));
    } catch (e) {
      emit(WalletError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreatePaymentIntentRequested(
    CreatePaymentIntentRequested event,
    Emitter<WalletState> emit,
  ) async {
    final currentState = state;
    double balance = 0.0;
    var transactions = const <Transaction>[];

    if (currentState is WalletLoaded) {
      balance = currentState.balance;
      transactions = currentState.transactions;
    } else if (currentState is PaymentIntentSuccess) {
      balance = currentState.balance;
      transactions = currentState.transactions;
    }

    emit(const WalletLoading());
    try {
      final clientSecret = await walletRepository.createPaymentIntent(event.amount);
      emit(PaymentIntentSuccess(
        clientSecret: clientSecret,
        balance: balance,
        transactions: List.from(transactions),
      ));
    } catch (e) {
      emit(WalletError(e.toString().replaceAll('Exception: ', '')));
      emit(WalletLoaded(balance: balance, transactions: List.from(transactions)));
    }
  }

  Future<void> _onRefreshBalanceRequested(
    RefreshBalanceRequested event,
    Emitter<WalletState> emit,
  ) async {
    final currentState = state;
    double currentBalance = 0.0;
    var currentTransactions = const <Transaction>[];

    if (currentState is WalletLoaded) {
      currentBalance = currentState.balance;
      currentTransactions = currentState.transactions;
    } else if (currentState is PaymentIntentSuccess) {
      currentBalance = currentState.balance;
      currentTransactions = currentState.transactions;
    }

    try {
      final balance = await walletRepository.getBalance();
      emit(WalletLoaded(balance: balance, transactions: List.from(currentTransactions)));
    } catch (_) {
      emit(WalletLoaded(balance: currentBalance, transactions: List.from(currentTransactions)));
    }
  }
}
