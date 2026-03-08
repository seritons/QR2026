import 'package:flutter/material.dart';
import 'tokens.dart';

class AppetiteTheme {
  static ThemeData light() {
    const t = AppTokens.light;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: t.bg,
      colorScheme: ColorScheme.light(
        primary: t.primary,
        secondary: t.primary2,
        surface: t.surface,
        error: t.danger,
      ),
      extensions: const [AppTokens.light],
      textTheme: const TextTheme(),
      cardTheme: CardThemeData(
        color: t.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.rLg),
          side: BorderSide(color: t.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surface,
        hintStyle: TextStyle(color: t.muted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.rMd),
          borderSide: BorderSide(color: t.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.rMd),
          borderSide: BorderSide(color: t.focusRing, width: 1.3),
        ),
      ),
    );
  }

  static ThemeData dark() {
    const t = AppTokens.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: t.bg,
      colorScheme: ColorScheme.dark(
        primary: t.primary,
        secondary: t.primary2,
        surface: t.surface,
        error: t.danger,
      ),
      extensions: const [AppTokens.dark],
      textTheme: const TextTheme(),
      cardTheme: CardThemeData(
        color: t.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.rLg),
          side: BorderSide(color: t.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surface,
        hintStyle: TextStyle(color: t.muted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.rMd),
          borderSide: BorderSide(color: t.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.rMd),
          borderSide: BorderSide(color: t.focusRing, width: 1.3),
        ),
      ),
    );
  }

  static BoxDecoration background(BuildContext context) {
    final t = Theme.of(context).extension<AppTokens>()!;
    return BoxDecoration(
      color: t.bg,
    );
  }

  static BoxDecoration background2(BuildContext context) {
    final t = Theme.of(context).extension<AppTokens>()!;
    return BoxDecoration(
      gradient: RadialGradient(
        center: const Alignment(-0.8, -0.9),
        radius: 1.2,
        colors: [
          t.primarySoft,
          Colors.transparent,
        ],
        stops: const [0.0, 0.55],
      ),
    );
  }
}