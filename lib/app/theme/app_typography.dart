import 'package:flutter/material.dart';

class AppTypography {
  static const String family = 'Inter';

  static const TextStyle headline = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    height: 1.2,
  );

  static const TextStyle headlineItalic = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w700,
    fontStyle: FontStyle.italic,
    fontSize: 20,
    height: 1.2,
  );

  static const TextStyle title = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 1.3,
  );

  static const TextStyle titleItalic = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
    fontSize: 16,
    height: 1.3,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 1.35,
  );

  static const TextStyle body = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w400,
    fontSize: 13,
    height: 1.4,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 1.4,
  );

  static const TextStyle captionItalic = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    fontSize: 12,
    height: 1.4,
  );

  static const TextStyle button = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 1.2,
  );

  static const TextStyle metricSm = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    letterSpacing: -0.2,
  );

  static const TextStyle metric = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w600,
    fontSize: 22,
    letterSpacing: -0.3,
  );

  static const TextStyle metricLg = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    letterSpacing: -0.5,
  );
}