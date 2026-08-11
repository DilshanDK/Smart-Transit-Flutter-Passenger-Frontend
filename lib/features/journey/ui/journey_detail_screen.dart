// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class JourneyDetailScreen extends StatelessWidget {
  final Map<String, dynamic> journey;

  const JourneyDetailScreen({super.key, required this.journey});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final status = journey['status'] as String? ?? 'COMPLETED';
    final routeId = journey['routeId'] as String? ?? 'N/A';
    final fare = _parseFare(journey['fareCalculated']);
    final startTs = _parseDate(journey['startTimestamp']);
    final endTs = _parseDate(journey['endTimestamp']);
    final distanceKm = (journey['distanceKm'] as num?)?.toDouble() ?? 0.0;
    final startCoords = _parseCoords(journey['startLocation']);
    final endCoords = _parseCoords(journey['endLocation']);
    final calcMethod = journey['calculationMethod'] as String? ?? 'N/A';

    final duration = (startTs != null && endTs != null)
        ? endTs.difference(startTs)
        : null;

    final surfaceColor = isDark ? const Color(0xFF1A1F26) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFE5E7EB);
    final subtleColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1418) : const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          'Journey Details',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            // ── Status Hero Card ─────────────────────────────────────────
            _buildStatusCard(status, routeId, fare, isDark, surfaceColor, borderColor, subtleColor)
                .animate()
                .fade(duration: 350.ms)
                .slideY(begin: 0.1, end: 0, duration: 350.ms, curve: Curves.easeOut),

            const SizedBox(height: 16),

            // ── Timeline Section ──────────────────────────────────────────
            _buildSectionCard(
              title: 'Journey Timeline',
              icon: Icons.route_rounded,
              isDark: isDark,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              child: _buildTimeline(startTs, endTs, duration, subtleColor),
            ).animate().fade(delay: 80.ms, duration: 350.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 12),

            // ── Fare Breakdown ────────────────────────────────────────────
            _buildSectionCard(
              title: 'Fare Breakdown',
              icon: Icons.receipt_long_rounded,
              isDark: isDark,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              child: _buildFareBreakdown(fare, distanceKm, calcMethod, subtleColor),
            ).animate().fade(delay: 140.ms, duration: 350.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 12),

            // ── Location Coordinates ──────────────────────────────────────
            _buildSectionCard(
              title: 'Location Data',
              icon: Icons.location_on_rounded,
              isDark: isDark,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              child: _buildLocationData(startCoords, endCoords, subtleColor),
            ).animate().fade(delay: 200.ms, duration: 350.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Status Hero Card ──────────────────────────────────────────────────────
  Widget _buildStatusCard(
    String status, String routeId, double fare,
    bool isDark, Color surfaceColor, Color borderColor, Color subtleColor,
  ) {
    final isCompleted = status == 'COMPLETED';
    final isInProgress = status == 'IN_TRANSIT' || status == 'IN_PROGRESS';

    Color statusColor = isCompleted
        ? const Color(0xFF28A745)
        : isInProgress
            ? const Color(0xFF3B82F6)
            : const Color(0xFFEF4444);

    IconData statusIcon = isCompleted
        ? Icons.check_circle_rounded
        : isInProgress
            ? Icons.directions_bus_rounded
            : Icons.cancel_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withOpacity(0.05),
            surfaceColor,
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            isCompleted ? 'Trip Completed' : isInProgress ? 'In Transit' : 'Failed',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF28A745).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Route $routeId',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF28A745),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: borderColor),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'LKR ${fare.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Total Fare Charged',
            style: GoogleFonts.inter(fontSize: 11, color: subtleColor),
          ),
        ],
      ),
    );
  }

  // ── Timeline Widget ───────────────────────────────────────────────────────
  Widget _buildTimeline(
    DateTime? startTs, DateTime? endTs, Duration? duration, Color subtleColor,
  ) {
    return Column(
      children: [
        _timelineRow(
          icon: Icons.play_circle_fill_rounded,
          iconColor: const Color(0xFF28A745),
          label: 'Tap-On Time',
          value: startTs != null ? _formatDateTime(startTs) : 'N/A',
          subtleColor: subtleColor,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Container(
            width: 2,
            height: 28,
            color: const Color(0xFF28A745).withOpacity(0.2),
          ),
        ),
        _timelineRow(
          icon: Icons.stop_circle_rounded,
          iconColor: const Color(0xFFEF4444),
          label: 'Tap-Off Time',
          value: endTs != null ? _formatDateTime(endTs) : 'Still in transit',
          subtleColor: subtleColor,
        ),
        if (duration != null) ...[
          const SizedBox(height: 12),
          _infoRow(
            icon: Icons.timer_rounded,
            label: 'Duration',
            value: _formatDuration(duration),
            subtleColor: subtleColor,
          ),
        ],
      ],
    );
  }

  Widget _timelineRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color subtleColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: subtleColor)),
            Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  // ── Fare Breakdown Widget ─────────────────────────────────────────────────
  Widget _buildFareBreakdown(
    double fare, double distanceKm, String calcMethod, Color subtleColor,
  ) {
    const baseFare = 30.0;
    final distanceFare = fare - baseFare;

    return Column(
      children: [
        _infoRow(icon: Icons.attach_money_rounded, label: 'Base Fare', value: 'LKR ${baseFare.toStringAsFixed(2)}', subtleColor: subtleColor),
        _divider(),
        _infoRow(icon: Icons.straighten_rounded, label: 'Distance Travelled', value: '${distanceKm.toStringAsFixed(2)} km', subtleColor: subtleColor),
        _divider(),
        _infoRow(icon: Icons.calculate_rounded, label: 'Distance Charge', value: 'LKR ${distanceFare.toStringAsFixed(2)}', subtleColor: subtleColor),
        _divider(),
        _infoRow(icon: Icons.settings_rounded, label: 'Calculation Method', value: calcMethod, subtleColor: subtleColor),
        _divider(),
        _infoRow(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Total Charged',
          value: 'LKR ${fare.toStringAsFixed(2)}',
          subtleColor: subtleColor,
          valueColor: const Color(0xFF28A745),
          bold: true,
        ),
      ],
    );
  }

  // ── Location Data Widget ──────────────────────────────────────────────────
  Widget _buildLocationData(
    List<double>? startCoords, List<double>? endCoords, Color subtleColor,
  ) {
    return Column(
      children: [
        _infoRow(
          icon: Icons.trip_origin_rounded,
          iconColor: const Color(0xFF28A745),
          label: 'Boarding Location',
          value: startCoords != null
              ? '${startCoords[1].toStringAsFixed(5)}, ${startCoords[0].toStringAsFixed(5)}'
              : 'N/A',
          subtleColor: subtleColor,
        ),
        _divider(),
        _infoRow(
          icon: Icons.location_on_rounded,
          iconColor: const Color(0xFFEF4444),
          label: 'Exit Location',
          value: endCoords != null
              ? '${endCoords[1].toStringAsFixed(5)}, ${endCoords[0].toStringAsFixed(5)}'
              : 'N/A',
          subtleColor: subtleColor,
        ),
      ],
    );
  }

  // ── Shared Widgets ────────────────────────────────────────────────────────
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF28A745)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color subtleColor,
    Color? iconColor,
    Color? valueColor,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor ?? subtleColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: subtleColor)),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, thickness: 0.5, color: Colors.grey.withOpacity(0.15));

  // ── Helpers ───────────────────────────────────────────────────────────────
  double _parseFare(dynamic raw) {
    if (raw == null) return 0.0;
    if (raw is num) return raw.toDouble();
    if (raw is Map && raw['\$numberDecimal'] != null) {
      return double.tryParse(raw['\$numberDecimal'].toString()) ?? 0.0;
    }
    return double.tryParse(raw.toString()) ?? 0.0;
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  List<double>? _parseCoords(dynamic raw) {
    if (raw == null) return null;
    final coords = raw['coordinates'];
    if (coords is List && coords.length >= 2) {
      return [_toDouble(coords[0]), _toDouble(coords[1])];
    }
    return null;
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year}  ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
  }
}
