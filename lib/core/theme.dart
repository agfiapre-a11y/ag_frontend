import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
        primaryContainer: Color(0xFFCCF0EC),
        onPrimaryContainer: AppColors.primaryDark,
        secondaryContainer: Color(0xFFFFF3CD),
        onSecondaryContainer: Color(0xFF7A4D00),
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.poppinsTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.primaryDark.withValues(alpha: 0.3),
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 50),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCCE8E5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBBDEDA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIconColor: AppColors.primaryLight,
        floatingLabelStyle: const TextStyle(color: AppColors.primary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFCCF0EC),
        labelStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.primary),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0F2EF),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : Colors.grey.shade400,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primary,
      ),
      popupMenuTheme: PopupMenuThemeData(
        elevation: 4,
        shadowColor: AppColors.primaryDark.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
      ),
    );
  }
}

/// ===============================================================
/// PARADISE AG APP THEME
/// Inspired by the cinematic blue & sunrise banner
/// ===============================================================

class ParadiseTheme {
  //==========================
  // MAIN BACKGROUND GRADIENT
  //==========================

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.background,
      AppColors.backgroundLight,
      AppColors.primary,
      AppColors.primaryLight,
    ],
    stops: [
      0.0,
      0.3,
      0.7,
      1.0,
    ],
  );

  //==========================
  // SPLASH SCREEN
  //==========================

  static const RadialGradient splashGradient = RadialGradient(
    center: Alignment(0.9, -0.8),
    radius: 1.6,
    colors: [
      AppColors.secondary,
      AppColors.accent,
      AppColors.primaryLight,
      AppColors.background,
    ],
  );

  //==========================
  // GLASS CARD DECORATION
  //==========================

  static BoxDecoration glassCard = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.12),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );

  //==========================
  // APP THEME
  //==========================

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.paradiseBackground,
      primaryColor: AppColors.secondary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.secondary,
        secondary: AppColors.accent,
        surface: AppColors.paradiseBackground,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.paradiseCardColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.background,
          elevation: 6,
          padding: const EdgeInsets.symmetric(
            horizontal: 25,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight.withValues(alpha: 0.4),
        hintStyle: const TextStyle(
          color: AppColors.textTertiary,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.cardBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primaryLight,
            width: 2,
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  //==========================
  // BACKGROUND DECORATION
  //==========================

  static const BoxDecoration pageBackground = BoxDecoration(
    gradient: backgroundGradient,
  );

  //==========================
  // SPLASH DECORATION
  //==========================

  static const BoxDecoration splashBackground = BoxDecoration(
    gradient: splashGradient,
  );
}

/// ===============================================================
/// EMERALD & IVORY THEME - Enterprise Design
/// Modern, clean, professional church management system
/// ===============================================================

class EmeraldTheme {
  //==========================
  // THEME DATA
  //==========================

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.ivorySoft,
      primaryColor: AppColors.goldWarm,
      colorScheme: const ColorScheme.light(
        primary: AppColors.goldWarm,
        secondary: AppColors.emeraldDeep,
        surface: AppColors.cardWhite,
        error: AppColors.errorRed,
        onPrimary: AppColors.emeraldTextPrimary,
        onSecondary: AppColors.cardWhite,
        onSurface: AppColors.emeraldTextPrimary,
        onError: AppColors.cardWhite,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.cardWhite,
        foregroundColor: AppColors.emeraldTextPrimary,
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.emeraldTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.emeraldTextPrimary),
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 80,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radius16),
          side: const BorderSide(color: AppColors.emeraldCardBorder, width: 1),
        ),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.06),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.goldWarm,
          foregroundColor: AppColors.emeraldTextPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24, vertical: AppColors.spacing16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radius16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.emeraldTextPrimary,
          side: const BorderSide(color: AppColors.borderDefault, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radius16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.goldWarm,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardWhite,
        hintStyle: const TextStyle(color: AppColors.emeraldTextMuted),
        labelStyle: const TextStyle(color: AppColors.emeraldTextSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radius16),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radius16),
          borderSide: const BorderSide(color: AppColors.goldWarm, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppColors.spacing16, vertical: AppColors.spacing16),
        prefixIconColor: AppColors.emeraldTextSecondary,
        floatingLabelStyle: const TextStyle(color: AppColors.goldWarm),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          color: AppColors.emeraldTextPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        displayMedium: GoogleFonts.poppins(
          color: AppColors.emeraldTextPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 28,
        ),
        displaySmall: GoogleFonts.poppins(
          color: AppColors.emeraldTextPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        headlineLarge: GoogleFonts.poppins(
          color: AppColors.emeraldTextPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        headlineMedium: GoogleFonts.poppins(
          color: AppColors.emeraldTextPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        headlineSmall: GoogleFonts.poppins(
          color: AppColors.emeraldTextPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleLarge: GoogleFonts.poppins(
          color: AppColors.emeraldTextPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        titleMedium: GoogleFonts.poppins(
          color: AppColors.emeraldTextPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        titleSmall: GoogleFonts.poppins(
          color: AppColors.emeraldTextPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        bodyLarge: GoogleFonts.poppins(
          color: AppColors.emeraldTextPrimary,
          fontSize: 15,
        ),
        bodyMedium: GoogleFonts.poppins(
          color: AppColors.emeraldTextSecondary,
          fontSize: 14,
        ),
        bodySmall: GoogleFonts.poppins(
          color: AppColors.emeraldTextMuted,
          fontSize: 13,
        ),
        labelLarge: GoogleFonts.poppins(
          color: AppColors.emeraldTextPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        labelMedium: GoogleFonts.poppins(
          color: AppColors.emeraldTextSecondary,
          fontSize: 13,
        ),
        labelSmall: GoogleFonts.poppins(
          color: AppColors.emeraldTextMuted,
          fontSize: 12,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.emeraldDeep,
        surfaceTintColor: Colors.transparent,
        width: 280,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDefault,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.emeraldTextSecondary,
        textColor: AppColors.emeraldTextPrimary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.ivoryLight,
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: AppColors.emeraldTextPrimary,
        ),
        side: const BorderSide(color: AppColors.borderDefault),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radius16),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.goldWarm,
        foregroundColor: AppColors.emeraldTextPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radius16),
        ),
        backgroundColor: AppColors.cardWhite,
        contentTextStyle: GoogleFonts.poppins(
          color: AppColors.emeraldTextPrimary,
          fontSize: 13,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.goldWarm
              : AppColors.emeraldTextSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.goldWarm.withValues(alpha: 0.3)
              : AppColors.borderDefault,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radius16),
        ),
        color: AppColors.cardWhite,
        textStyle: GoogleFonts.poppins(color: AppColors.emeraldTextPrimary),
      ),
    );
  }

  //==========================
  // CARD DECORATION
  //==========================

  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.cardWhite,
    borderRadius: BorderRadius.circular(AppColors.radius16),
    border: Border.all(color: AppColors.emeraldCardBorder, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );

  //==========================
  // SIDEBAR DECORATION
  //==========================

  static BoxDecoration sidebarDecoration = const BoxDecoration(
    color: AppColors.emeraldDeep,
  );

  //==========================
  // ACTIVE NAVIGATION ITEM
  //==========================

  static BoxDecoration activeNavDecoration = BoxDecoration(
    color: AppColors.emeraldLight,
    borderRadius: BorderRadius.circular(AppColors.radius16),
    border: const Border(
      left: BorderSide(color: AppColors.goldWarm, width: 4),
    ),
  );
}
