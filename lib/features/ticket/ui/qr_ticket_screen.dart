// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../viewmodel/ticket_viewmodel.dart';

class QrTicketScreen extends StatefulWidget {
  const QrTicketScreen({super.key});

  @override
  State<QrTicketScreen> createState() => _QrTicketScreenState();
}

class _QrTicketScreenState extends State<QrTicketScreen> {
  final TicketViewModel _viewModel = TicketViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.startTokenLoop();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.qrToken == null) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF28A745)));
          }

          if (_viewModel.error != null && _viewModel.qrToken == null) {
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
                      _viewModel.error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.white54),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _viewModel.startTokenLoop(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final progress = _viewModel.secondsRemaining / 30.0;

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
                          data: _viewModel.qrToken ?? '',
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
                                '${_viewModel.secondsRemaining}',
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
                if (_viewModel.activeJourney != null)
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
                                'Route: ${_viewModel.activeJourney!['routeId'] ?? 'In Transit'}',
                                style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _viewModel.checkActiveJourney(),
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
    );
  }
}
