import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tenant_config.dart';
import 'theme.dart';

class DynamicTheme {
  /// Builds a theme from the tenant config, falling back to the default theme.
  static ThemeData fromConfig(TenantConfig? config) {
    final base = ParadiseTheme.theme;
    if (config == null) return base;

    final primary = _parseColor(config.primaryColor, const Color(0xFF2E7D32));
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      primaryColor: primary,
      scaffoldBackgroundColor: base.scaffoldBackgroundColor,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: base.elevatedButtonTheme.style?.copyWith(
              backgroundColor: WidgetStatePropertyAll(primary),
            ) ??
            ElevatedButton.styleFrom(backgroundColor: primary),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: base.outlinedButtonTheme.style?.copyWith(
              foregroundColor: WidgetStatePropertyAll(primary),
              side: WidgetStatePropertyAll(BorderSide(color: primary)),
            ) ??
            OutlinedButton.styleFrom(foregroundColor: primary),
      ),
      textButtonTheme: TextButtonThemeData(
        style: base.textButtonTheme.style?.copyWith(
              foregroundColor: WidgetStatePropertyAll(primary),
            ) ??
            TextButton.styleFrom(foregroundColor: primary),
      ),
      floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
        backgroundColor: primary,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        prefixIconColor: primary,
        floatingLabelStyle: TextStyle(color: primary),
      ),
    );
  }

  static Color primaryColor(TenantConfig? config) {
    return _parseColor(
      config?.primaryColor,
      const Color(0xFF2E7D32),
    );
  }

  static Color _parseColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      final buffer = StringBuffer();
      if (hex.length == 7) buffer.write('FF');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return fallback;
    }
  }
}
