import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrewTheme {
  static const espresso = Color(0xFF14110F);
  static const roast = Color(0xFF2A211C);
  static const foam = Color(0xFFE7E1D5);
  static const chartreuse = Color(0xFFC6DE57);
  static const cherry = Color(0xFFB24A3C);
  static const mute = Color(0xFF8A8076);

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: espresso,
      colorScheme: const ColorScheme.dark(
        primary: chartreuse,
        secondary: cherry,
        surface: roast,
        onPrimary: espresso,
        onSecondary: foam,
        onSurface: foam,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.figtreeTextTheme(base.textTheme).apply(
        bodyColor: foam,
        displayColor: foam,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: foam,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: chartreuse,
        foregroundColor: espresso,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: roast,
        selectedColor: chartreuse.withValues(alpha: 0.25),
        labelStyle: const TextStyle(color: foam),
        side: const BorderSide(color: Color(0xFF3D342E)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: roast,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3D342E)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3D342E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: chartreuse, width: 1.4),
        ),
        labelStyle: const TextStyle(color: mute),
      ),
    );
  }
}
