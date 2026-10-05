import 'package:flutter/material.dart';

class AppTheme {
  static const _seedColor = Color(0xFF1B4D6E);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(seedColor: _seedColor);

    return ThemeData(
      colorScheme: colorScheme,
      appBarTheme: AppBarThemeData(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
    );
  }
}
