// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import 'login_screen.dart';
import '../../dashboard/ui/passenger_dashboard_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final Widget _loginScreen = const LoginScreen();
  bool _isFirstCheck = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is! AuthInitial && state is! AuthLoading) {
          setState(() {
            _isFirstCheck = false;
          });
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.message,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFDC3545),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return const PassengerDashboardScreen();
        }

        if (_isFirstCheck) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D0D0D),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF28A745),
              ),
            ),
          );
        }

        // Return the persistent LoginScreen so typed inputs are preserved on AuthError
        return _loginScreen;
      },
    );
  }
}

