// ignore_for_file: deprecated_member_use
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_tab.dart';
import 'wallet_tab.dart';
import 'profile_tab.dart';

class PassengerDashboardScreen extends StatefulWidget {
  const PassengerDashboardScreen({super.key});

  @override
  State<PassengerDashboardScreen> createState() => _PassengerDashboardScreenState();
}

class _PassengerDashboardScreenState extends State<PassengerDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // Ambient green glow top-right
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF28A745).withOpacity(0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Ambient glow bottom-left
          Positioned(
            bottom: -80,
            left: -40,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF006E25).withOpacity(0.07),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: IndexedStack(
                key: ValueKey(_currentIndex),
                index: _currentIndex,
                children: [
                  HomeTab(onWalletTap: () => setState(() => _currentIndex = 1)),
                  const WalletTab(),
                  const ProfileTab(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: const Color(0xFF28A745),
            unselectedItemColor: Colors.white38,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    ).animate().fade(delay: 400.ms).slideY(begin: 0.5, end: 0, curve: Curves.easeOut);
  }
}
