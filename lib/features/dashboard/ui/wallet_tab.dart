// ignore_for_file: deprecated_member_use
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../wallet/viewmodel/wallet_viewmodel.dart';
import '../../../core/models/models.dart';

class WalletTab extends StatefulWidget {
  final WalletViewModel viewModel;
  const WalletTab({super.key, required this.viewModel});

  @override
  State<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<WalletTab> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
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
                      vm.isLoading ? 'Loading...' : 'LKR ${vm.balance.toStringAsFixed(2)}',
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
                    onPressed: vm.isTopUpLoading ? null : () => _showTopUpSheet(context),
                    icon: vm.isTopUpLoading
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

              if (vm.isLoading)
                const Center(child: CircularProgressIndicator(color: Color(0xFF28A745)))
              else if (vm.transactions.isEmpty)
                _emptyTransactions()
              else
                ...vm.transactions.asMap().entries.map((e) =>
                    _TransactionCard(tx: e.value).animate(delay: Duration(milliseconds: 300 + e.key * 60)).fade().slideX(begin: 0.05, end: 0)
                ),
            ],
          ),
        );
      },
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
    final amounts = [100.0, 250.0, 500.0, 1000.0];
    double selected = 250.0;
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
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final secret = await widget.viewModel.createPaymentIntent(selected);
                        if (secret != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Payment Intent created! (Stripe Sheet: Phase 2 wiring)'), backgroundColor: const Color(0xFF28A745)),
                          );
                        }
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
