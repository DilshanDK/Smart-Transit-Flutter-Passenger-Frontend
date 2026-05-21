import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryGreen = Color(006000 + 0x00E25); // #006E25 (Bus Green)
  static const Color onPrimary = Colors.white;
  
  // Light Mode Colors
  static const Color lightBg = Color(0xFFF9F9FE);
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceVariant = Color(0xFFEDEDF2);
  static const Color lightOnSurface = Color(0xFF1A1C1F);
  static const Color lightSecondary = Color(0xFF5F5E60);
  static const Color lightOutline = Color(0xFF6E7B6B);
  static const Color lightOutlineVariant = Color(0xFFBDCAB9);

  // Dark Mode Colors
  static const Color darkBg = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2E);
  static const Color darkOnSurface = Color(0xFFF0F0F5);
  static const Color darkSecondary = Color(0xFFC8C6C8);
  static const Color darkOutline = Color(0xFF8D9B8A);
  static const Color darkOutlineVariant = Color(0xFF474649);

  // Rounded corners definition
  static const double radiusSm = 4.0;
  static const double radiusDefault = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        onPrimary: onPrimary,
        surface: lightSurface,
        onSurface: lightOnSurface,
        secondary: lightSecondary,
        onSecondary: Colors.white,
        outline: lightOutline,
        outlineVariant: lightOutlineVariant,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: -0.8),
        headlineLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.normal),
        bodyMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.normal),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
        labelSmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.2),
      ),
      cardTheme: const CardThemeData(
        color: lightSurface,
        elevation: 2,
        shadowColor: Color(0x0F000000), // Hex equivalent of black with 6% opacity
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusLg)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusDefault),
          borderSide: const BorderSide(color: lightOutlineVariant, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusDefault),
          borderSide: const BorderSide(color: lightOutlineVariant, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusDefault),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusDefault),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: lightSecondary, fontSize: 14, fontWeight: FontWeight.w500),
        floatingLabelStyle: GoogleFonts.inter(color: primaryGreen, fontSize: 12, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: onPrimary,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusDefault),
          ),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        onPrimary: onPrimary,
        surface: darkSurface,
        onSurface: darkOnSurface,
        secondary: darkSecondary,
        onSecondary: Colors.black,
        outline: darkOutline,
        outlineVariant: darkOutlineVariant,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: -0.8, color: Colors.white),
        headlineLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.normal, color: darkOnSurface),
        bodyMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.normal, color: darkOnSurface),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1, color: Colors.white),
        labelSmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.2, color: darkSecondary),
      ),
      cardTheme: const CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusLg)),
          side: BorderSide(color: darkOutlineVariant, width: 1.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusDefault),
          borderSide: const BorderSide(color: darkOutlineVariant, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusDefault),
          borderSide: const BorderSide(color: darkOutlineVariant, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusDefault),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusDefault),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: darkSecondary, fontSize: 14, fontWeight: FontWeight.w500),
        floatingLabelStyle: GoogleFonts.inter(color: primaryGreen, fontSize: 12, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: onPrimary,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusDefault),
          ),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
