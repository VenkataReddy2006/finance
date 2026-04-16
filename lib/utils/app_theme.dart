import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Classic "Neat UI" Palette
  static const Color primaryNavy = Color(0xFF0F172A);      // Deep Blue/Navy
  static const Color primaryEmerald = Color(0xFF10B981);   // Emerald Green
  static const Color primaryBlack = Color(0xFF0A0A0B);     // Sophisticated Black
  static const Color primaryGray = Color(0xFF334155);      // Slate Gray
  
  static const Color accentTeal = Color(0xFF14B8A6);       // Innovation Teal
  static const Color accentRed = Color(0xFFEF4444);        // Alert Red
  static const Color accentGold = Color(0xFFF59E0B);       // Wealth Gold
  
  static const Color lightBg = Color(0xFFFFFFFF);          // Clean White
  static const Color lightSurface = Color(0xFFF8FAFC);     // Light Slate Gray

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        surface: Colors.white,
        onSurface: primaryNavy,
        primary: primaryNavy,
        secondary: primaryEmerald,
        tertiary: accentTeal,
        error: accentRed,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryNavy),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: primaryNavy.withOpacity(0.4),
          letterSpacing: 2,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: primaryNavy.withOpacity(0.05), width: 1),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryNavy,
        unselectedItemColor: primaryNavy.withOpacity(0.3),
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryBlack,
      colorScheme: const ColorScheme.dark(
        surface: primaryNavy,
        onSurface: Colors.white,
        primary: primaryEmerald,
        secondary: accentTeal,
        tertiary: accentGold,
        error: accentRed,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: Colors.white.withOpacity(0.3),
          letterSpacing: 2,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B), // Slate 800
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0F172A), // Navy Bottom Bar
        selectedItemColor: primaryEmerald,
        unselectedItemColor: Colors.white24,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.02),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryEmerald, width: 2),
        ),
      ),
    );
  }

  // Common Gradients
  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [primaryNavy, Color(0xFF1E3A8A)], // Navy to Blue 900
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get secondaryGradient => const LinearGradient(
        colors: [primaryEmerald, Color(0xFF059669)], // Emerald 500 to 600
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  
  static LinearGradient get goldGradient => const LinearGradient(
        colors: [accentGold, Color(0xFFD97706)], // Gold to Darker Gold
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
