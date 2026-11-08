import 'package:flutter/material.dart';

/// Paleta del taller: negro + naranja.
class AppColors {
  AppColors._();
  static const negro = Color(0xFF121212);
  static const superficie = Color(0xFF1E1E1E);
  static const superficieAlta = Color(0xFF2B2B2B);
  static const naranja = Color(0xFFFF9800);
  static const naranjaOscuro = Color(0xFFE65100);
  static const textoSecundario = Color(0xFFB3B3B3);
  static const verde = Color(0xFF66BB6A);
  static const rojo = Color(0xFFEF5350);
  static const amarillo = Color(0xFFFFCA28);
  static const azul = Color(0xFF42A5F5);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.naranja,
      onPrimary: Colors.black,
      secondary: AppColors.naranjaOscuro,
      onSecondary: Colors.white,
      surface: AppColors.superficie,
      onSurface: Colors.white,
      error: AppColors.rojo,
    );

    final bordeCampo = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.negro,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.negro,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.superficie,
        elevation: 4,
        shadowColor: Colors.black54,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.superficie,
        indicatorColor: AppColors.naranja.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? AppColors.naranja
                : AppColors.textoSecundario,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.naranja
                : AppColors.textoSecundario,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.superficieAlta,
        border: bordeCampo,
        enabledBorder: bordeCampo,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.naranja, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.rojo),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.rojo, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textoSecundario),
        floatingLabelStyle: const TextStyle(color: AppColors.naranja),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.naranja,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.naranja,
          side: const BorderSide(color: AppColors.naranja),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.naranja),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.naranja,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.superficieAlta,
        selectedColor: AppColors.naranja.withValues(alpha: 0.28),
        checkmarkColor: AppColors.naranja,
        labelStyle: const TextStyle(color: Colors.white),
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.superficie,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.superficieAlta,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(color: Colors.white12, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.naranja,
        linearTrackColor: AppColors.superficieAlta,
      ),
    );
  }
}
