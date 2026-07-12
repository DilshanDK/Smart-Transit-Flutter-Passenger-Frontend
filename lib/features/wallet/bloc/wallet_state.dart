import '../../../../core/models/models.dart';

abstract class WalletState {
  const WalletState();
}

class WalletInitial extends WalletState {
  const WalletInitial();
}

class WalletLoading extends WalletState {
  const WalletLoading();
}

class WalletLoaded extends WalletState {
  final double balance;
  final List<Transaction> transactions;
  const WalletLoaded({required this.balance, required this.transactions});
}

class PaymentIntentSuccess extends WalletState {
  final String clientSecret;
  final double balance;
  final List<Transaction> transactions;
  const PaymentIntentSuccess({
    required this.clientSecret,
    required this.balance,
    required this.transactions,
  });
}

class WalletError extends WalletState {
  final String message;
  const WalletError(this.message);
}
