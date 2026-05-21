// ignore_for_file: unnecessary_underscores, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../home/viewmodel/home_viewmodel.dart';
import '../../../core/storage/secure_storage.dart';
import '../../auth/ui/auth_wrapper.dart';

class ProfileTab extends StatelessWidget {
  final HomeViewModel homeVM;
  const ProfileTab({super.key, required this.homeVM});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: homeVM,
      builder: (context, _) {
        final profile = homeVM.profile;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white))
                  .animate().fade(duration: 500.ms),
              const SizedBox(height: 4),
              Text('Manage your account', style: GoogleFonts.inter(fontSize: 14, color: Colors.white54))
                  .animate().fade(delay: 100.ms),
              const SizedBox(height: 28),

              // ── Avatar + Name ──
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: const Color(0xFF28A745).withOpacity(0.15),
                      child: Text(
                        homeVM.isLoading ? '..' : (profile?.initials ?? 'P'),
                        style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF28A745)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      homeVM.isLoading ? 'Loading...' : (profile?.fullName ?? 'Passenger'),
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      homeVM.isLoading ? '' : (profile?.email ?? ''),
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF28A745).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF28A745).withOpacity(0.3)),
                      ),
                      child: Text('Passenger', style: GoogleFonts.inter(color: const Color(0xFF28A745), fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ).animate(delay: 150.ms).fade().scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),

              const SizedBox(height: 32),

              // ── Settings Tiles ──
              _SettingsTile(icon: Icons.person_outline_rounded, label: 'Edit Profile', onTap: () {}),
              _SettingsTile(icon: Icons.nfc_rounded, label: 'Linked NFC Card', subtitle: profile?.nfcUid ?? 'Not linked', onTap: () {}),
              _SettingsTile(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () {}),
              _SettingsTile(icon: Icons.lock_outline_rounded, label: 'Change Password', onTap: () {}),
              _SettingsTile(icon: Icons.help_outline_rounded, label: 'Help & Support', onTap: () {}),
              _SettingsTile(icon: Icons.info_outline_rounded, label: 'About Smart Transit', onTap: () {}),

              const SizedBox(height: 16),
              Divider(color: Colors.white.withOpacity(0.07)),
              const SizedBox(height: 8),

              // ── Logout ──
              _SettingsTile(
                icon: Icons.logout_rounded,
                label: 'Log Out',
                labelColor: Colors.redAccent,
                iconColor: Colors.redAccent,
                onTap: () => _confirmLogout(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to log out?', style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SecureStorage.clearTokens();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const AuthWrapper(),
                    transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                  (route) => false,
                );
              }
            },
            child: Text('Log Out', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? labelColor;
  final Color? iconColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.labelColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? Colors.white54, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(color: labelColor ?? Colors.white, fontSize: 14)),
                  if (subtitle != null)
                    Text(subtitle!, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}
