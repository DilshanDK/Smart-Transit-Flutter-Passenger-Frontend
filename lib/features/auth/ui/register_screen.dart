// ignore_for_file: unnecessary_underscores

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to the Terms & Conditions.'),
          backgroundColor: Colors.orangeAccent.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        RegisterRequested(
          email: _emailController.text.trim(),
          fullName: _fullNameController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF9F9FE),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // ── DARK: Dot pattern + ambient glows ──
              if (isDark) ...[
                CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _DotPatternPainter(),
                ),
                Positioned(
                  top: -60,
                  right: -20,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF28A745).withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -80,
                  left: -40,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF006E25).withValues(alpha: 0.07),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // ── Main content ──
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Back button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFE2E2E7),
                                ),
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: isDark ? Colors.white70 : const Color(0xFF1A1C1F),
                                size: 18,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Bus illustration
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/bus_isometric.png',
                            height: 160,
                            fit: BoxFit.contain,
                          ),
                        )
                            .animate()
                            .fade(duration: 700.ms)
                            .slideY(begin: -0.15, end: 0, curve: Curves.easeOutCubic),

                        const SizedBox(height: 24),

                        // Title
                        Text(
                          'Register',
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1A1C1F),
                          ),
                        ).animate().fade(delay: 200.ms).slideY(begin: 0.12, end: 0),

                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          'Access your smart transit dashboard',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark ? Colors.white54 : const Color(0xFF6E7B6B),
                            height: 1.5,
                          ),
                        ).animate().fade(delay: 300.ms),

                        const SizedBox(height: 28),

                        // ── FORM CARD ──
                        _buildFormCard(isDark, children: [
                          // Full Name
                          _buildTextField(
                            controller: _fullNameController,
                            hint: 'Full Name',
                            icon: Icons.person_outline_rounded,
                            isDark: isDark,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ).animate().fade(delay: 400.ms).slideX(begin: -0.05, end: 0),

                          const SizedBox(height: 16),

                          // Email
                          _buildTextField(
                            controller: _emailController,
                            hint: 'Email Address',
                            icon: Icons.email_outlined,
                            isDark: isDark,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value.trim())) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ).animate().fade(delay: 500.ms).slideX(begin: 0.05, end: 0),

                          const SizedBox(height: 16),

                          // Password
                          _buildTextField(
                            controller: _passwordController,
                            hint: 'Create Password',
                            icon: Icons.lock_outline,
                            isDark: isDark,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: isDark ? Colors.white38 : const Color(0xFFBDCAB9),
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ).animate().fade(delay: 600.ms).slideX(begin: -0.05, end: 0),

                          const SizedBox(height: 16),

                          // Terms checkbox
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: Checkbox(
                                  value: _agreedToTerms,
                                  onChanged: (v) =>
                                      setState(() => _agreedToTerms = v ?? false),
                                  activeColor: const Color(0xFF28A745),
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.25)
                                        : const Color(0xFFBDCAB9),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    text: 'I agree to the ',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white54
                                          : const Color(0xFF5F5E60),
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Terms & Conditions',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: const Color(0xFF28A745),
                                          decoration: TextDecoration.underline,
                                          decorationColor: const Color(0xFF28A745),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fade(delay: 650.ms),
                        ]),

                        const SizedBox(height: 24),

                        // Create Account button
                        _buildPrimaryButton(
                          label: 'Create Account',
                          isLoading: state is AuthLoading,
                          onPressed: _handleRegister,
                        ).animate().fade(delay: 700.ms).slideY(begin: 0.15, end: 0),

                        const SizedBox(height: 24),

                        // OR divider
                        _buildOrDivider(isDark).animate().fade(delay: 750.ms),

                        const SizedBox(height: 24),

                        // Google button
                        _buildGoogleButton(isDark, label: 'Sign with Google')
                            .animate()
                            .fade(delay: 800.ms),

                        const SizedBox(height: 28),

                        // Already have an account?
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: isDark ? Colors.white54 : const Color(0xFF5F5E60),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text(
                                'Sign in',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF28A745),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ).animate().fade(delay: 850.ms),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),

              // Neon bottom line (dark mode only)
              if (isDark)
                Positioned(
                  bottom: 0,
                  left: 40,
                  right: 40,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFF28A745).withValues(alpha: 0.6),
                          const Color(0xFF00BFFF).withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF28A745).withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── Shared Builders ──

  Widget _buildFormCard(bool isDark, {required List<Widget> children}) {
    final card = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E2E7),
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );

    if (isDark) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: card,
        ),
      ).animate().fade(delay: 350.ms).scale(
            begin: const Offset(0.97, 0.97),
            end: const Offset(1, 1),
            curve: Curves.easeOut,
          );
    }

    return card.animate().fade(delay: 350.ms).scale(
          begin: const Offset(0.97, 0.97),
          end: const Offset(1, 1),
          curve: Curves.easeOut,
        );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.inter(
        color: isDark ? Colors.white : const Color(0xFF1A1C1F),
        fontSize: 14,
      ),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: isDark ? Colors.white30 : const Color(0xFFBDCAB9),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: isDark ? Colors.white30 : const Color(0xFFBDCAB9), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF9F9FE),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E2E7),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E2E7),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF28A745), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: GoogleFonts.inter(fontSize: 11, color: Colors.redAccent),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B8C3A), Color(0xFF28A745)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF28A745).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildOrDivider(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E2E7),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.white38 : const Color(0xFF9E9E9E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E2E7),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton(bool isDark, {required String label}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
        label: Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white70 : const Color(0xFF1A1C1F),
          backgroundColor: isDark ? Colors.transparent : const Color(0xFFF2F2F7),
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E2E7),
            width: 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// Subtle dot grid background painter (dark mode only)
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    const spacing = 24.0;
    const radius = 1.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
