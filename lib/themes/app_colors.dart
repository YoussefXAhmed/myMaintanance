import 'package:flutter/material.dart';

/// Centralised colour tokens for the Liquid Glass design system.
///
/// The palette is dark-first (premium automotive feel) with a carefully tuned
/// light variant. Glass surfaces are intentionally low-opacity so the animated
/// gradient background reads through them.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Brand / accent
  // ---------------------------------------------------------------------------
  static const Color primary = Color(0xFF5B8DEF); // electric blue
  static const Color primaryDeep = Color(0xFF3A63D0);
  static const Color secondary = Color(0xFF7C5CFF); // violet
  static const Color tertiary = Color(0xFF2BD9C4); // mint / teal

  static const Color accentPink = Color(0xFFFF6CAB);
  static const Color accentAmber = Color(0xFFFFB547);

  // ---------------------------------------------------------------------------
  // Semantic / health
  // ---------------------------------------------------------------------------
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFF87171);
  static const Color info = Color(0xFF60A5FA);

  // ---------------------------------------------------------------------------
  // Dark theme surfaces
  // ---------------------------------------------------------------------------
  static const Color darkBg0 = Color(0xFF070A14);
  static const Color darkBg1 = Color(0xFF0B1020);
  static const Color darkBg2 = Color(0xFF121A30);
  static const Color darkText = Color(0xFFF4F7FF);
  static const Color darkTextMuted = Color(0xFF9AA6C2);

  // ---------------------------------------------------------------------------
  // Light theme surfaces
  // ---------------------------------------------------------------------------
  static const Color lightBg0 = Color(0xFFEAF0FB);
  static const Color lightBg1 = Color(0xFFF4F7FE);
  static const Color lightBg2 = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF111726);
  static const Color lightTextMuted = Color(0xFF5C6885);

  // ---------------------------------------------------------------------------
  // Gradients
  // ---------------------------------------------------------------------------
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient mintGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tertiary, primary],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentAmber, accentPink],
  );

  static const LinearGradient healthGoodGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34D399), Color(0xFF2BD9C4)],
  );

  static const LinearGradient healthWarnGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB547), Color(0xFFFB7185)],
  );

  /// Full-screen ambient background blobs for the dark theme.
  static const List<Color> darkBackground = [darkBg0, darkBg1, darkBg2];
  static const List<Color> lightBackground = [lightBg0, lightBg1, lightBg2];

  // ---------------------------------------------------------------------------
  // Glass tokens — resolved against brightness in [GlassTokens].
  // ---------------------------------------------------------------------------
  static Color glassFill(Brightness b) =>
      b == Brightness.dark ? Colors.white.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.55);

  static Color glassFillStrong(Brightness b) =>
      b == Brightness.dark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.72);

  static Color glassBorder(Brightness b) =>
      b == Brightness.dark ? Colors.white.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.85);

  static Color glassHighlight(Brightness b) =>
      b == Brightness.dark ? Colors.white.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.95);

  static Color shadow(Brightness b) =>
      b == Brightness.dark ? Colors.black.withValues(alpha: 0.45) : const Color(0xFF8AA0CC).withValues(alpha: 0.30);

  static Color textPrimary(Brightness b) => b == Brightness.dark ? darkText : lightText;
  static Color textMuted(Brightness b) => b == Brightness.dark ? darkTextMuted : lightTextMuted;

  /// Returns a colour for a 0..100 health value.
  static Color forScore(double score) {
    if (score >= 75) return success;
    if (score >= 45) return warning;
    return danger;
  }

  static LinearGradient gradientForScore(double score) {
    if (score >= 75) return healthGoodGradient;
    if (score >= 45) return healthWarnGradient;
    return const LinearGradient(colors: [danger, accentPink]);
  }
}
