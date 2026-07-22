import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: kBgBase,
      colorScheme: const ColorScheme.dark(
        primary: kBrandPrimary,
        secondary: kBrandSecondary,
        surface: kBgCard,
        error: kError,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: kTextPrimary,
        onError: Colors.white,
        outline: kBorder,
      ),

      // Typography — Inter font matching the popup CSS
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
              color: kTextPrimary, fontWeight: FontWeight.w700, fontSize: 28),
          displayMedium: TextStyle(
              color: kTextPrimary, fontWeight: FontWeight.w700, fontSize: 24),
          headlineLarge: TextStyle(
              color: kTextPrimary, fontWeight: FontWeight.w700, fontSize: 20),
          headlineMedium: TextStyle(
              color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 17),
          headlineSmall: TextStyle(
              color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 15),
          titleLarge: TextStyle(
              color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 16),
          titleMedium: TextStyle(
              color: kTextPrimary, fontWeight: FontWeight.w500, fontSize: 14),
          titleSmall: TextStyle(
              color: kTextSecondary, fontWeight: FontWeight.w500, fontSize: 12),
          bodyLarge: TextStyle(
              color: kTextPrimary, fontWeight: FontWeight.w400, fontSize: 14),
          bodyMedium: TextStyle(
              color: kTextSecondary, fontWeight: FontWeight.w400, fontSize: 13),
          bodySmall: TextStyle(
              color: kTextMuted, fontWeight: FontWeight.w400, fontSize: 11),
          labelLarge: TextStyle(
              color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 13),
          labelMedium: TextStyle(
              color: kTextSecondary, fontWeight: FontWeight.w500, fontSize: 11),
          labelSmall: TextStyle(
              color: kTextMuted, fontWeight: FontWeight.w500, fontSize: 10),
        ),
      ),

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: kBgBase,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          color: kTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: kTextSecondary),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: kBgCard,
        selectedItemColor: kBrandPrimary,
        unselectedItemColor: kTextMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Card
      cardTheme: CardThemeData(
        color: kBgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusMd),
          side: const BorderSide(color: kBorder, width: 1),
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kBrandSecondary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: kSpaceLg, vertical: kSpaceMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusSm),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kTextSecondary,
          side: const BorderSide(color: kBorder),
          padding: const EdgeInsets.symmetric(horizontal: kSpaceLg, vertical: kSpaceMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusSm),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kBgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusSm),
          borderSide: const BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusSm),
          borderSide: const BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusSm),
          borderSide: const BorderSide(color: kBorderAccent, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: kTextMuted, fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: kSpaceMd, vertical: kSpaceMd),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: kBorder,
        thickness: 1,
        space: 0,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? kBrandPrimary : kTextMuted),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? kBrandGlow
                : const Color(0xFF2A2A38)),
      ),

      // Slider
      sliderTheme: const SliderThemeData(
        activeTrackColor: kBrandSecondary,
        inactiveTrackColor: kBorder,
        thumbColor: kBrandPrimary,
        overlayColor: kBrandGlow,
      ),
    );
  }
}
