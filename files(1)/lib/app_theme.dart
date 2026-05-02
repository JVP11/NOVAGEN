import 'package:flutter/material.dart';

// ============================================================
// NovaGen SafeInk Scanner — brand theme (exact hex from spec)
// ============================================================

/// Main background surfaces
const Color kNavy = Color(0xFF0F172A);

/// Card / elevated surfaces
const Color kDarkBlue = Color(0xFF1E3A8A);

/// Primary actions + "safe" result tone (blue from brand palette)
const Color kBlue = Color(0xFF3B82F6);

/// Accent + scan CTAs
const Color kOrange = Color(0xFFF97316);

/// Muted panels / borders
const Color kSlate = Color(0xFF334155);

// ── Result colors (match product marketing) ─────────────────
const Color kSafe = Color(0xFF3B82F6);
const Color kModerate = Color(0xFFF97316);
const Color kUnsafe = Color(0xFFEF4444);

ThemeData novagenDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kNavy,
    colorScheme: const ColorScheme.dark(
      surface: kNavy,
      primary: kBlue,
      secondary: kOrange,
      outline: kSlate,
      error: kUnsafe,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
    ),
    dividerColor: kSlate,
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kDarkBlue.withAlpha(180),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kSlate),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kSlate),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBlue, width: 1.4),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kOrange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kBlue,
        side: const BorderSide(color: kBlue),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
