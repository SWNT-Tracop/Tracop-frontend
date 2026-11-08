import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF2E7D32);
  static const Color forest = Color(0xFF1B5E20);
  static const Color mint = Color(0xFFE8F5E9);
  static const Color earth = Color(0xFF8D6E63);
  static const Color background = Color(0xFFF7F7F2);
  static const Color ink = Color(0xFF1F2937);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color outline = Color(0xFFE5E7EB);
  static const Color white = Colors.white;
  static const double radiusSurface = 24;
  static const double radiusControl = 12;
  static const StadiumBorder pillShape = StadiumBorder();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      onPrimary: white,
      secondary: earth,
      onSecondary: white,
      surface: white,
      onSurface: ink,
      error: const Color(0xFFC62828),
      onError: white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter',
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: mint,
        circularTrackColor: mint,
        linearMinHeight: 3,
        refreshBackgroundColor: white,
      ),
      hoverColor: mint,
      focusColor: mint,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: forest,
          fontSize: 30,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          color: forest,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
        titleLarge: TextStyle(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          color: ink,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
        bodyLarge: TextStyle(
          color: mutedText,
          fontSize: 18,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: mutedText,
          fontSize: 16,
          height: 1.45,
        ),
        labelLarge: TextStyle(
          color: primary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: ink,
        backgroundColor: background,
        titleTextStyle: TextStyle(
          color: forest,
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSurface),
          side: const BorderSide(color: outline),
        ),
      ),
      dividerTheme: const DividerThemeData(color: outline, thickness: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 56),
          backgroundColor: primary,
          foregroundColor: white,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: pillShape,
        ).copyWith(
          side: WidgetStateProperty.resolveWith<BorderSide?>((states) =>
              states.contains(WidgetState.focused)
                  ? const BorderSide(color: forest, width: 2)
                  : BorderSide.none),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 2),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: pillShape,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: white,
        indicatorColor: mint,
        indicatorShape: pillShape,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              color: states.contains(WidgetState.selected) ? forest : mutedText,
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w600
                  : FontWeight.w500,
            )),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: white,
        selectedIconTheme: IconThemeData(color: forest),
        unselectedIconTheme: IconThemeData(color: mutedText),
        selectedLabelTextStyle: TextStyle(
          color: forest,
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: mutedText,
          fontFamily: 'Inter',
          fontSize: 14,
        ),
        indicatorColor: mint,
        indicatorShape: pillShape,
      ),
    );
  }
}
