abstract class WalletEvent {
  const WalletEvent();
}

class LoadWalletRequested extends WalletEvent {
  const LoadWalletRequested();
}

class CreatePaymentIntentRequested extends WalletEvent {
  final double amount;
  const CreatePaymentIntentRequested(this.amount);
}

class RefreshBalanceRequested extends WalletEvent {
  const RefreshBalanceRequested();
}
