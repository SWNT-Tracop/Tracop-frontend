import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF2E7D32);
  static const Color surface = Color(0xFFF5F7F4);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: primary,
      scaffoldBackgroundColor: surface,
      appBarTheme: const AppThemeBar(),
    );
  }
}

class AppThemeBar extends AppBarTheme {
  const AppThemeBar()
      : super(
          centerTitle: false,
          elevation: 0,
          foregroundColor: Colors.white,
        );
}
