import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Burgundy palette
  static const Color burgundy = Color(0xFF800020);
  static const Color burgundyLight = Color(0xFFA3324D);
  static const Color burgundyDark = Color(0xFF5C0015);

  // Neutral palette
  static const Color surfaceLight = Color(0xFFF8F4F4);
  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF16213E);

  // Accent
  static const Color accentGold = Color(0xFFD4AF37);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: burgundy,
        onPrimary: Colors.white,
        secondary: burgundyLight,
        onSecondary: Colors.white,
        surface: surfaceLight,
        onSurface: const Color(0xFF2D2D2D),
        tertiary: accentGold,
      ),
      scaffoldBackgroundColor: surfaceLight,
      appBarTheme: AppBarTheme(
        backgroundColor: burgundy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: burgundy,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: const Color(0xFF2D2D2D),
        displayColor: const Color(0xFF2D2D2D),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: burgundy.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: burgundy, width: 2),
        ),
        prefixIconColor: burgundy,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: burgundyLight,
        onPrimary: Colors.white,
        secondary: burgundy,
        onSecondary: Colors.white,
        surface: surfaceDark,
        onSurface: const Color(0xFFE8E8E8),
        tertiary: accentGold,
      ),
      scaffoldBackgroundColor: surfaceDark,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0F3460),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: burgundyLight,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: const Color(0xFFE8E8E8),
        displayColor: const Color(0xFFE8E8E8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: burgundyLight.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: burgundyLight, width: 2),
        ),
        prefixIconColor: burgundyLight,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
