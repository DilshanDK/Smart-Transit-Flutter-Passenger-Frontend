// ignore_for_file: deprecated_member_use
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../wallet/bloc/wallet_bloc.dart';
import '../../wallet/bloc/wallet_state.dart';
import '../../ticket/ui/qr_ticket_screen.dart';
import '../../tracking/ui/tracking_screen.dart';

class HomeTab extends StatelessWidget {
  final VoidCallback onWalletTap;

  const HomeTab({
    super.key,
    required this.onWalletTap,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'P';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String name = 'Passenger';
        String initials = 'P';
        final greeting = _getGreeting();

        if (authState is AuthAuthenticated) {
          final user = authState.user;
          final fullName = user['fullName'] ?? 'Passenger';
          name = fullName.split(' ')[0];
          initials = _getInitials(fullName);
        }

        return BlocBuilder<WalletBloc, WalletState>(
          builder: (context, walletState) {
            double balance = 0.0;
            final bool isWalletLoading = walletState is WalletLoading;

            if (walletState is WalletLoaded) {
              balance = walletState.balance;
            } else if (walletState is PaymentIntentSuccess) {
              balance = walletState.balance;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
                          ),
                          Text(
                            name,
                            style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFF28A745).withOpacity(0.15),
                        child: Text(
                          initials,
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF28A745)),
                        ),
                      ),
                    ],
                  ).animate().fade(duration: 500.ms).slideX(begin: -0.05, end: 0),

                  const SizedBox(height: 24),

                  // ── Wallet Balance Strip ──
                  GestureDetector(
                    onTap: onWalletTap,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1B8C3A), Color(0xFF0D5C22)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF28A745).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Wallet Balance', style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
                                  const SizedBox(height: 6),
                                  Text(
                                    isWalletLoading ? '...' : 'LKR ${balance.toStringAsFixed(2)}',
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 26),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate(delay: 100.ms).fade().slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),

                  // ── Quick Actions ──
                  Text('Quick Actions', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600))
                      .animate(delay: 150.ms).fade(),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _QuickAction(
                        icon: Icons.qr_code_rounded,
                        label: 'Board Bus',
                        color: const Color(0xFF28A745),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const QrTicketScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _QuickAction(icon: Icons.add_card_rounded, label: 'Top Up', color: const Color(0xFF2196F3), onTap: onWalletTap),
                      const SizedBox(width: 12),
                      _QuickAction(icon: Icons.history_rounded, label: 'History', color: const Color(0xFF9C27B0), onTap: onWalletTap),
                      const SizedBox(width: 12),
                      _QuickAction(
                        icon: Icons.map_outlined,
                        label: 'Track',
                        color: const Color(0xFFFF9800),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TrackingScreen()),
                          );
                        },
                      ),
                    ],
                  ).animate(delay: 200.ms).fade(),

                  const SizedBox(height: 28),

                  // ── Recent Journeys Section ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Journeys', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('See All', style: GoogleFonts.inter(color: const Color(0xFF28A745), fontSize: 13)),
                    ],
                  ).animate(delay: 250.ms).fade(),
                  const SizedBox(height: 14),

                  // Journey Cards (placeholder until Phase 3)
                  ...[
                    const _JourneyCard(from: 'Colombo Fort', to: 'Nugegoda', fare: 'LKR 45.00', date: 'Today, 8:20 AM', status: 'Completed'),
                    const _JourneyCard(from: 'Maharagama', to: 'Colombo Fort', fare: 'LKR 60.00', date: 'Yesterday, 6:45 PM', status: 'Completed'),
                    const _JourneyCard(from: 'Pettah', to: 'Kaduwela', fare: 'LKR 35.00', date: 'May 19, 9:10 AM', status: 'Completed'),
                  ].asMap().entries.map((e) => e.value.animate(delay: Duration(milliseconds: 300 + e.key * 80)).fade().slideY(begin: 0.1, end: 0)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  final String from;
  final String to;
  final String fare;
  final String date;
  final String status;

  const _JourneyCard({required this.from, required this.to, required this.fare, required this.date, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF28A745).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.directions_bus_rounded, color: Color(0xFF28A745), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(from, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward_rounded, color: Colors.white38, size: 14),
                    ),
                    Text(to, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(date, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(fare, style: GoogleFonts.inter(color: const Color(0xFF28A745), fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(status, style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
