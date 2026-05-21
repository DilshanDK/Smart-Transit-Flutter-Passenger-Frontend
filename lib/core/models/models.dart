// Core data models shared across the app

class PassengerProfile {
  final String id;
  final String fullName;
  final String email;
  final double walletBalance;
  final String? nfcUid;
  final String role;

  const PassengerProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.walletBalance,
    this.nfcUid,
    required this.role,
  });

  factory PassengerProfile.fromJson(Map<String, dynamic> json) {
    return PassengerProfile(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? 'Passenger',
      email: json['email'] ?? '',
      walletBalance: (json['walletBalance'] ?? 0).toDouble(),
      nfcUid: json['nfcUid'],
      role: json['role'] ?? 'passenger',
    );
  }

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : 'P';
  }

  String get firstName {
    return fullName.trim().split(' ').first;
  }
}

class Transaction {
  final String id;
  final String type; // WALLET_TOPUP | JOURNEY_DEDUCTION
  final double amount;
  final DateTime createdAt;
  final String? stripePaymentIntentId;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.createdAt,
    this.stripePaymentIntentId,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['_id'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      stripePaymentIntentId: json['stripePaymentIntentId'],
    );
  }

  bool get isTopUp => type == 'WALLET_TOPUP';
}
