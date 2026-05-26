import 'package:flutter/material.dart';

class OpenVtsTypography {
  const OpenVtsTypography._();

  /// Primary ecosystem font used across OpenVTS product UI.
  static const String primaryFontFamily = 'Inter';

  /// Secondary brand font used only for controlled brand/editorial moments.
  /// Do not use Satoshi for normal product body text or dense data UI.
  static const String secondaryFontFamily = 'Satoshi';

  /// Backward-compatible alias used by existing widgets.
  static const String fontFamily = primaryFontFamily;

  static const List<String> fontFallback = <String>[
    primaryFontFamily,
    'Roboto',
    'Arial',
    'sans-serif',
  ];

  static const List<String> secondaryFontFallback = <String>[
    primaryFontFamily,
    'SF Pro Display',
    'Segoe UI',
    'Roboto',
    'Arial',
    'sans-serif',
  ];

  static const titleLarge = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallback,
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );

  static const titleMedium = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallback,
    fontSize: 22,
    height: 1.25,
    fontWeight: FontWeight.w600,
  );

  static const titleSmall = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallback,
    fontSize: 18,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );

  static const bodyLarge = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallback,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  static const body = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallback,
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  static const label = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallback,
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w500,
  );

  static const meta = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallback,
    fontSize: 12,
    height: 1.35,
    fontWeight: FontWeight.w400,
  );

  /// Use only for controlled brand moments such as splash/onboarding eyebrow,
  /// campaign-style headings, or premium empty-state headlines.
  /// Normal product screens should use Inter via Theme.of(context).textTheme.
  static const brandTitle = TextStyle(
    fontFamily: secondaryFontFamily,
    fontFamilyFallback: secondaryFontFallback,
    fontSize: 24,
    height: 1.25,
    fontWeight: FontWeight.w700,
  );

  static const brandLabel = TextStyle(
    fontFamily: secondaryFontFamily,
    fontFamilyFallback: secondaryFontFallback,
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w700,
  );

  static const numeric = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallback,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
    fontSize: 28,
    height: 1.15,
    fontWeight: FontWeight.w600,
  );
}
