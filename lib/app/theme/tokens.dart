import 'package:flutter/material.dart';

@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  final Color bg;
  final Color surface;
  final Color text;
  final Color muted;
  final Color primary;
  final Color primary2;
  final Color success;
  final Color danger;
  final Color warning;
  final Color info;
  final Color border;
  final Color surfaceSoft;
  final Color surfaceMuted;
  final Color primarySoft;
  final Color primarySoft2;
  final Color focusRing;
  final Color divider;
  final Color disabledBg;
  final Color disabledText;

  final Color codeBg;
  final Color codeBorder;
  final Color tokenKeyword;
  final Color tokenString;
  final Color tokenNumber;
  final Color tokenComment;
  final Color tokenFunction;
  final Color tokenType;
  final Color tokenVariable;
  final Color tokenOperator;
  final Color tokenPunctuation;

  final double rLg;
  final double rMd;
  final List<BoxShadow> shadow;
  final List<BoxShadow> shadow2;

  const AppTokens({
    required this.bg,
    required this.surface,
    required this.text,
    required this.muted,
    required this.primary,
    required this.primary2,
    required this.success,
    required this.danger,
    required this.warning,
    required this.info,
    required this.border,
    required this.surfaceSoft,
    required this.surfaceMuted,
    required this.primarySoft,
    required this.primarySoft2,
    required this.focusRing,
    required this.divider,
    required this.disabledBg,
    required this.disabledText,
    required this.codeBg,
    required this.codeBorder,
    required this.tokenKeyword,
    required this.tokenString,
    required this.tokenNumber,
    required this.tokenComment,
    required this.tokenFunction,
    required this.tokenType,
    required this.tokenVariable,
    required this.tokenOperator,
    required this.tokenPunctuation,
    required this.rLg,
    required this.rMd,
    required this.shadow,
    required this.shadow2,
  });

  static const AppTokens light = AppTokens(
    bg: Color(0xFFFFF8F6),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF1F2430),
    muted: Color(0xFF6B7280),
    primary: Color(0xFFF0B90B),
    primary2: Color(0xFFF8D33A),
    success: Color(0xFF16A34A),
    danger: Color(0xFFDC2626),
    warning: Color(0xFFF59E0B),
    info: Color(0xFF2563EB),
    border: Color(0x1F1F2430),
    surfaceSoft: Color(0xFFFFF1D6),
    surfaceMuted: Color(0xFFF7F1E8),
    primarySoft: Color(0x33F0B90B),
    primarySoft2: Color(0x26F8D33A),
    focusRing: Color(0x66F0B90B),
    divider: Color(0x141F2430),
    disabledBg: Color(0xFFF3F4F6),
    disabledText: Color(0xFFA1A1AA),
    codeBg: Color(0xFFFFFAF5),
    codeBorder: Color(0x26F0B90B),
    tokenKeyword: Color(0xFFB45309),
    tokenString: Color(0xFF047857),
    tokenNumber: Color(0xFF7C3AED),
    tokenComment: Color(0xFF9CA3AF),
    tokenFunction: Color(0xFF0F766E),
    tokenType: Color(0xFF1D4ED8),
    tokenVariable: Color(0xFF92400E),
    tokenOperator: Color(0xFF475569),
    tokenPunctuation: Color(0xFF6B7280),
    rLg: 18,
    rMd: 14,
    shadow: [
      BoxShadow(
        color: Color(0x1A111827),
        blurRadius: 40,
        offset: Offset(0, 14),
      ),
    ],
    shadow2: [
      BoxShadow(
        color: Color(0x14111827),
        blurRadius: 18,
        offset: Offset(0, 8),
      ),
    ],
  );

  static const AppTokens dark = AppTokens(
    bg: Color(0xFF0B0E11),
    surface: Color(0xFF181A20),
    text: Color(0xFFF5F5F5),
    muted: Color(0xFF9CA3AF),
    primary: Color(0xFFF0B90B),
    primary2: Color(0xFFF8D33A),
    success: Color(0xFF03A66D),
    danger: Color(0xFFF6465D),
    warning: Color(0xFFF0B90B),
    info: Color(0xFF3B82F6),
    border: Color(0xFF2B3139),
    surfaceSoft: Color(0xFF1E2329),
    surfaceMuted: Color(0xFF232A33),
    primarySoft: Color(0x33F0B90B),
    primarySoft2: Color(0x26F8D33A),
    focusRing: Color(0x66F0B90B),
    divider: Color(0xFF2B3139),
    disabledBg: Color(0xFF2A2F36),
    disabledText: Color(0xFF6B7280),
    codeBg: Color(0xFF111418),
    codeBorder: Color(0xFF2B3139),
    tokenKeyword: Color(0xFFF0B90B),
    tokenString: Color(0xFF7DD3A0),
    tokenNumber: Color(0xFFC084FC),
    tokenComment: Color(0xFF6B7280),
    tokenFunction: Color(0xFF4FD1C5),
    tokenType: Color(0xFF60A5FA),
    tokenVariable: Color(0xFFF59E0B),
    tokenOperator: Color(0xFFCBD5E1),
    tokenPunctuation: Color(0xFF94A3B8),
    rLg: 18,
    rMd: 14,
    shadow: [
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 32,
        offset: Offset(0, 12),
      ),
    ],
    shadow2: [
      BoxShadow(
        color: Color(0x3D000000),
        blurRadius: 16,
        offset: Offset(0, 6),
      ),
    ],
  );

  LinearGradient appetiteGradient() => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primary2],
  );

  LinearGradient softGradient() => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceSoft, surfaceMuted],
  );

  LinearGradient dangerGradient() => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [danger, const Color(0xFFFF7A8A)],
  );

  LinearGradient successGradient() => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, const Color(0xFF2EBD85)],
  );

  @override
  AppTokens copyWith({
    Color? bg,
    Color? surface,
    Color? text,
    Color? muted,
    Color? primary,
    Color? primary2,
    Color? success,
    Color? danger,
    Color? warning,
    Color? info,
    Color? border,
    Color? surfaceSoft,
    Color? surfaceMuted,
    Color? primarySoft,
    Color? primarySoft2,
    Color? focusRing,
    Color? divider,
    Color? disabledBg,
    Color? disabledText,
    Color? codeBg,
    Color? codeBorder,
    Color? tokenKeyword,
    Color? tokenString,
    Color? tokenNumber,
    Color? tokenComment,
    Color? tokenFunction,
    Color? tokenType,
    Color? tokenVariable,
    Color? tokenOperator,
    Color? tokenPunctuation,
    double? rLg,
    double? rMd,
    List<BoxShadow>? shadow,
    List<BoxShadow>? shadow2,
  }) {
    return AppTokens(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      primary: primary ?? this.primary,
      primary2: primary2 ?? this.primary2,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      border: border ?? this.border,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      primarySoft: primarySoft ?? this.primarySoft,
      primarySoft2: primarySoft2 ?? this.primarySoft2,
      focusRing: focusRing ?? this.focusRing,
      divider: divider ?? this.divider,
      disabledBg: disabledBg ?? this.disabledBg,
      disabledText: disabledText ?? this.disabledText,
      codeBg: codeBg ?? this.codeBg,
      codeBorder: codeBorder ?? this.codeBorder,
      tokenKeyword: tokenKeyword ?? this.tokenKeyword,
      tokenString: tokenString ?? this.tokenString,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      tokenComment: tokenComment ?? this.tokenComment,
      tokenFunction: tokenFunction ?? this.tokenFunction,
      tokenType: tokenType ?? this.tokenType,
      tokenVariable: tokenVariable ?? this.tokenVariable,
      tokenOperator: tokenOperator ?? this.tokenOperator,
      tokenPunctuation: tokenPunctuation ?? this.tokenPunctuation,
      rLg: rLg ?? this.rLg,
      rMd: rMd ?? this.rMd,
      shadow: shadow ?? this.shadow,
      shadow2: shadow2 ?? this.shadow2,
    );
  }

  @override
  ThemeExtension<AppTokens> lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return this;
  }
}