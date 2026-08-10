// ignore_for_file: use_build_context_synchronously, unnecessary_underscores, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../../core/theme/theme_cubit.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String name = 'Passenger';
        String email = '';
        String initials = 'P';
        String? nfcUid = 'Not linked';

        if (state is AuthAuthenticated) {
          final user = state.user;
          name = user['fullName'] ?? 'Passenger';
          email = user['email'] ?? '';
          initials = _getInitials(name);
          nfcUid = user['nfcUid'] as String?;
        }

        final bool isLoader = state is AuthLoading;

        return RefreshIndicator(
          onRefresh: () async {
            final authBloc = context.read<AuthBloc>();
            authBloc.add(ReloadUserRequested());
            try {
              await authBloc.stream.firstWhere(
                (s) => s is AuthAuthenticated || s is AuthError,
              ).timeout(const Duration(seconds: 5));
            } catch (_) {}
          },
          color: const Color(0xFF28A745),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text('Profile', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87))
                  .animate().fade(duration: 500.ms),
              const SizedBox(height: 4),
              Text('Manage your account', style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white54 : Colors.black54))
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
                        initials,
                        style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF28A745)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54),
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
              _SettingsTile(icon: Icons.nfc_rounded, label: 'Linked NFC Card', subtitle: nfcUid ?? 'Not linked', onTap: () {}),
              _SettingsTile(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () {}),

              // ── Theme Toggle Tile ──
              BlocBuilder<ThemeCubit, bool>(
                builder: (context, darkMode) {
                  return GestureDetector(
                    onTap: () => context.read<ThemeCubit>().toggle(),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: darkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: darkMode ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
                      ),
                      child: Row(
                        children: [
                          Icon(darkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                              color: darkMode ? const Color(0xFF28A745) : const Color(0xFFFBC02D), size: 20),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              darkMode ? 'Dark Mode' : 'Light Mode',
                              style: GoogleFonts.inter(color: darkMode ? Colors.white : Colors.black87, fontSize: 14),
                            ),
                          ),
                          Switch.adaptive(
                            value: darkMode,
                            onChanged: (val) => context.read<ThemeCubit>().setDark(val),
                            activeColor: const Color(0xFF28A745),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              _SettingsTile(icon: Icons.lock_outline_rounded, label: 'Change Password', onTap: () => _showChangePasswordDialog(context)),
              _SettingsTile(icon: Icons.help_outline_rounded, label: 'Help & Support', onTap: () {}),
              _SettingsTile(icon: Icons.info_outline_rounded, label: 'About Smart Transit', onTap: () {}),

              const SizedBox(height: 16),
              Divider(color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.07)),
              const SizedBox(height: 8),

              // ── Logout ──
              _SettingsTile(
                icon: Icons.logout_rounded,
                label: 'Log Out',
                labelColor: Colors.redAccent,
                iconColor: Colors.redAccent,
                onTap: isLoader ? () {} : () => _confirmLogout(context),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Change Password',
                style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: currentPasswordController,
                        obscureText: true,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF28A745)),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: true,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF28A745)),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF28A745)),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v != newPasswordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.pop(ctx),
                  child: Text('Cancel', style: GoogleFonts.inter(color: isDark ? Colors.white54 : Colors.black54)),
                ),
                TextButton(
                  onPressed: loading
                      ? null
                      : () async {
                          if (formKey.currentState?.validate() ?? false) {
                            setState(() {
                              loading = true;
                            });

                            try {
                              final authRepository = context.read<AuthBloc>().authRepository;
                              await authRepository.changePassword(
                                currentPasswordController.text,
                                newPasswordController.text,
                              );
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password updated successfully!'),
                                  backgroundColor: Color(0xFF28A745),
                                ),
                              );
                            } catch (e) {
                              setState(() {
                                loading = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString().replaceAll('Exception: ', '')),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                  child: loading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF28A745)),
                          ),
                        )
                      : Text(
                          'Update',
                          style: GoogleFonts.inter(color: const Color(0xFF28A745), fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out', style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to log out?', style: GoogleFonts.inter(color: isDark ? Colors.white70 : Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: isDark ? Colors.white54 : Colors.black54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const LogoutRequested());
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? (isDark ? Colors.white54 : Colors.black54), size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(color: labelColor ?? (isDark ? Colors.white : Colors.black87), fontSize: 14)),
                  if (subtitle != null)
                    Text(subtitle!, style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : Colors.black26, size: 20),
          ],
        ),
      ),
    );
  }
}
