import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium typography. Latin uses **Inter**, Arabic uses **Cairo** — both are
/// fetched on first run by `google_fonts`, so no font files need bundling.
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Brightness brightness, {bool arabic = false}) {
    final base = arabic ? GoogleFonts.cairoTextTheme() : GoogleFonts.interTextTheme();
    final color = brightness == Brightness.dark ? const Color(0xFFF4F7FF) : const Color(0xFF111726);

    TextStyle s(double size, FontWeight w, {double? h, double? ls}) =>
        base.bodyMedium!.copyWith(fontSize: size, fontWeight: w, height: h, letterSpacing: ls, color: color);

    return TextTheme(
      displayLarge: s(40, FontWeight.w800, h: 1.05, ls: -0.5),
      displayMedium: s(32, FontWeight.w800, h: 1.08, ls: -0.4),
      displaySmall: s(28, FontWeight.w700, h: 1.1, ls: -0.3),
      headlineMedium: s(24, FontWeight.w700, h: 1.15, ls: -0.2),
      headlineSmall: s(20, FontWeight.w700, h: 1.2),
      titleLarge: s(18, FontWeight.w700, h: 1.25),
      titleMedium: s(16, FontWeight.w600, h: 1.3),
      titleSmall: s(14, FontWeight.w600, h: 1.3),
      bodyLarge: s(16, FontWeight.w400, h: 1.45),
      bodyMedium: s(14, FontWeight.w400, h: 1.45),
      bodySmall: s(12.5, FontWeight.w400, h: 1.4),
      labelLarge: s(14, FontWeight.w600, ls: 0.2),
      labelMedium: s(12, FontWeight.w600, ls: 0.3),
      labelSmall: s(11, FontWeight.w600, ls: 0.4),
    );
  }

  /// Large numeric display used on the dashboard health ring & stats.
  static TextStyle numeric(BuildContext context, {double size = 34, FontWeight weight = FontWeight.w800}) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: -1,
      color: Theme.of(context).textTheme.bodyLarge?.color,
    );
  }
}
