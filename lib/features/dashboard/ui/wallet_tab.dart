// ignore_for_file: deprecated_member_use
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../wallet/bloc/wallet_bloc.dart';
import '../../wallet/bloc/wallet_event.dart';
import '../../wallet/bloc/wallet_state.dart';
import '../../../core/models/models.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class WalletTab extends StatelessWidget {
  const WalletTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state is PaymentIntentSuccess) {
          _presentStripeSheet(context, state.clientSecret);
        } else if (state is WalletError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          double balance = 0.0;
          var transactions = const <Transaction>[];
          final bool isLoader = state is WalletLoading;

          if (state is WalletLoaded) {
            balance = state.balance;
            transactions = state.transactions;
          } else if (state is PaymentIntentSuccess) {
            balance = state.balance;
            transactions = state.transactions;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text('My Wallet', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white))
                    .animate().fade(duration: 500.ms),
                const SizedBox(height: 4),
                Text('Manage your balance & transactions', style: GoogleFonts.inter(fontSize: 14, color: Colors.white54))
                    .animate().fade(delay: 100.ms),
                const SizedBox(height: 24),

                // ── Balance Card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B8C3A), Color(0xFF0A3D1E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF28A745).withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Smart Transit Wallet', style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                            child: Text('Active', style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isLoader ? 'Loading...' : 'LKR ${balance.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text('Available Balance', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 20),
                      // Decorative dots
                      Row(children: List.generate(4, (i) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Row(children: List.generate(4, (_) => Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle))),
                        ),
                      ))),
                    ],
                  ),
                ).animate(delay: 150.ms).fade().slideY(begin: 0.1, end: 0),

                const SizedBox(height: 20),

                // ── Top Up Button ──
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1B8C3A), Color(0xFF28A745)]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: const Color(0xFF28A745).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: isLoader ? null : () => _showTopUpSheet(context),
                      icon: isLoader
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.add_rounded, color: Colors.white),
                      label: Text('Top Up Balance', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ).animate(delay: 200.ms).fade(),

                const SizedBox(height: 28),

                // ── Transaction History ──
                Text('Transaction History', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600))
                    .animate(delay: 250.ms).fade(),
                const SizedBox(height: 14),

                if (isLoader && transactions.isEmpty)
                  const Center(child: CircularProgressIndicator(color: Color(0xFF28A745)))
                else if (transactions.isEmpty)
                  _emptyTransactions()
                else
                  ...transactions.asMap().entries.map((e) =>
                      _TransactionCard(tx: e.value).animate(delay: Duration(milliseconds: 300 + e.key * 60)).fade().slideX(begin: 0.05, end: 0)
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _emptyTransactions() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined, color: Colors.white24, size: 40),
          const SizedBox(height: 12),
          Text('No transactions yet', style: GoogleFonts.inter(color: Colors.white38, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Top up your wallet to get started', style: GoogleFonts.inter(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }

  void _showTopUpSheet(BuildContext context) {
    final amounts = [500.0, 1000.0, 2000.0, 5000.0];
    double selected = 500.0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocalState) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Text('Top Up Wallet', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Select an amount to add to your wallet', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: amounts.map((a) => GestureDetector(
                      onTap: () => setLocalState(() => selected = a),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected == a ? const Color(0xFF28A745).withOpacity(0.15) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selected == a ? const Color(0xFF28A745) : Colors.white.withOpacity(0.1)),
                        ),
                        child: Text('LKR ${a.toInt()}', style: GoogleFonts.inter(
                          color: selected == a ? const Color(0xFF28A745) : Colors.white70,
                          fontWeight: selected == a ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        )),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<WalletBloc>().add(CreatePaymentIntentRequested(selected));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF28A745),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Pay LKR ${selected.toInt()}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _presentStripeSheet(BuildContext context, String clientSecret) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Smart Transit',
          style: ThemeMode.dark,
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      
      // Payment Successful
      if (context.mounted) {
         context.read<WalletBloc>().add(const RefreshBalanceRequested());
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Payment Successful! Wallet updated.'), backgroundColor: Colors.green)
         );
      }
    } catch (e) {
      if (context.mounted) {
        if (e is StripeException) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment Canceled: ${e.error.localizedMessage}'), backgroundColor: Colors.orange)
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment Error: $e'), backgroundColor: Colors.red)
          );
        }
      }
    }
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction tx;
  const _TransactionCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isTopUp = tx.isTopUp;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: (isTopUp ? const Color(0xFF28A745) : Colors.redAccent).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isTopUp ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
              color: isTopUp ? const Color(0xFF28A745) : Colors.redAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isTopUp ? 'Wallet Top Up' : 'Journey Deduction',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(
                  '${tx.createdAt.day}/${tx.createdAt.month}/${tx.createdAt.year}',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '${isTopUp ? '+' : '-'} LKR ${tx.amount.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              color: isTopUp ? const Color(0xFF28A745) : Colors.redAccent,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
