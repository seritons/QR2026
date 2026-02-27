import 'package:flutter/material.dart';
import 'tokens.dart';

class AppetiteTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTokens.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppTokens.primary,
        secondary: AppTokens.primary2,
        surface: AppTokens.surface,
        error: AppTokens.danger,
      ),
      scaffoldBackgroundColor: AppTokens.bg,
      textTheme: const TextTheme(),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppTokens.text,
        displayColor: AppTokens.text,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.surface,
        hintStyle: TextStyle(color: AppTokens.muted.withOpacity(0.75)),
        labelStyle: const TextStyle(color: AppTokens.muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rMd),
          borderSide: BorderSide(color: const Color(0xFF1F2937).withOpacity(0.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rMd),
          borderSide: BorderSide(color: AppTokens.primary.withOpacity(0.55), width: 1.2),
        ),
      ),
    );
  }

  // CSS arka planındaki iki radial gradient hissini Flutter’da taklit ediyoruz.
  static BoxDecoration background() {
    return BoxDecoration(
      color: AppTokens.bg,
      gradient: RadialGradient(
        center: const Alignment(-0.8, -0.9),
        radius: 1.2,
        colors: [
          AppTokens.primary.withOpacity(0.16),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55],
      ),
    );
  }

  static BoxDecoration background2() {
    return BoxDecoration(
      gradient: RadialGradient(
        center: const Alignment(0.9, -0.8),
        radius: 1.15,
        colors: [
          AppTokens.primary2.withOpacity(0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55],
      ),
    );
  }
}
