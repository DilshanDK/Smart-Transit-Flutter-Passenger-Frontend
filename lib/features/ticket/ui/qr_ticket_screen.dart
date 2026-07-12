// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../data/repositories/ticket_repository.dart';
import '../bloc/ticket_bloc.dart';
import '../bloc/ticket_event.dart';
import '../bloc/ticket_state.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../payment/data/repositories/payment_repository.dart';



// Inside the QR Ticket screen, add a Buy Ticket button
// Place this button after the QR code container (line ~152)
// The button will trigger Stripe Payment Sheet



class QrTicketScreen extends StatelessWidget {
  const QrTicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider<TicketBloc>(
      create: (context) => TicketBloc(
        ticketRepository: TicketRepository(),
      )..add(const StartTicketLoop()),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F1418) : const Color(0xFFF9F9FE),
        appBar: AppBar(
          title: Text(
            'Digital QR Ticket',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: BlocBuilder<TicketBloc, TicketState>(
          builder: (context, state) {
            if (state.isLoading && state.qrToken == null) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF28A745)));
            }

            if (state.error != null && state.qrToken == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load ticket',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.error!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: Colors.white54),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.read<TicketBloc>().add(const StartTicketLoop()),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final progress = state.secondsRemaining / 30.0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Glassmorphic Ticket Container
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E2E7),
                      ),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header / Logo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.directions_bus, color: Color(0xFF28A745)),
                                const SizedBox(width: 8),
                                Text(
                                  'Smart Transit',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF28A745).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Active Fare',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF28A745),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // QR Code Container
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: QrImageView(
                            data: state.qrToken ?? '',
                            version: QrVersions.auto,
                            size: 200.0,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.black,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black,
                            ),
                          ),
                        ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack),

                        // Buy Ticket Button
ElevatedButton(
  onPressed: () async {
    if (context.read<TicketBloc>().state.isLoading) return;
    final repo = RepositoryProvider.of<PaymentRepository>(context);
    try {
      // Example amount: 500 cents = $5
      final clientSecret = await repo.createPaymentIntent(amount: 500);
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Smart Transit',
          style: Theme.of(context).brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful!')),
      );
    } on StripeException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${e.error.localizedMessage}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF28A745),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  child: const Text('Buy Ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
),
const SizedBox(height: 32),

                        // Refresh Countdown Progress Ring
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  height: 36,
                                  width: 36,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 3.5,
                                    backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E2E7),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF28A745)),
                                  ),
                                ),
                                Text(
                                  '${state.secondsRemaining}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Text(
                              'Ticket refreshes automatically',
                              style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Active Journey Status Banner
                  if (state.activeJourney != null)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF28A745).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF28A745).withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.airport_shuttle_rounded, color: Color(0xFF28A745)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Currently Checked In',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Route: ${state.activeJourney!['routeId'] ?? 'In Transit'}',
                                  style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.read<TicketBloc>().add(const CheckActiveJourneyRequested()),
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    ).animate().fade().slideY(begin: 0.1, end: 0)
                  else
                    Text(
                      'Present this code to the bus console scanner to board the transit vehicle.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
                    ).animate().fade(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
