// lib/theme/tokens.dart (veya senin mevcut tokens.dart dosyan)
// İsimler AYNI. Sadece renkleri “CoffeeMe” tarzı daha sıcak/kırmızı tona çektim.
// Not: withOpacity kullanmıyorum. border doğrudan ARGB.

import 'package:flutter/material.dart';

class AppTokens {
  // Daha sıcak, açık arka plan (kırmızı temaya uyumlu)
  // (cream/pinkish off-white)
  static const Color bg = Color(0xFFFFF4F2);

  // Kart/surface
  static const Color surface = Color(0xFFFFFFFF);

  // Text (kömür ton)
  static const Color text = Color(0xFF1F2430);

  // Muted text
  static const Color muted = Color(0xFF6B7280);

  // Primary (CoffeeMe kırmızı)
  static const Color primary = Color(0xFFE23B3B);

  // Secondary (kırmızı-koral, gradient için)
  static const Color primary2 = Color(0xFFFF5A3D);

  static const Color success = Color(0xFF16A34A);
  static const Color danger = Color(0xFFDC2626);

  // Border: text renginin ~%12 opaklığı (ARGB -> 0x1F = 31/255 ≈ 0.12)
  static const Color border = Color(0x1F1F2430);

  // Radius
  static const double rLg = 18;
  static const double rMd = 14;

  // Shadows (soft)
  static const List<BoxShadow> shadow = [
    BoxShadow(
      color: Color(0x1A111827),
      blurRadius: 40,
      offset: Offset(0, 14),
    )
  ];

  static const List<BoxShadow> shadow2 = [
    BoxShadow(
      color: Color(0x14111827),
      blurRadius: 18,
      offset: Offset(0, 8),
    )
  ];

  static LinearGradient appetiteGradient() => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primary2],
  );
}
