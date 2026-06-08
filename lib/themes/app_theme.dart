import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_typography.dart';

/// Builds the Material 3 [ThemeData] for both brightnesses, wired to the
/// Liquid Glass tokens. Most surfaces are transparent because real surfaces are
/// drawn by the glass widgets on top of an animated gradient background.
class AppTheme {
  AppTheme._();

  static ThemeData light({bool arabic = false}) => _build(Brightness.light, arabic);
  static ThemeData dark({bool arabic = false}) => _build(Brightness.dark, arabic);

  static ThemeData _build(Brightness brightness, bool arabic) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      error: AppColors.danger,
      surface: isDark ? AppColors.darkBg1 : AppColors.lightBg1,
    );

    final textTheme = AppTypography.textTheme(brightness, arabic: arabic);

    return ThemeData(
      // Material 3 is the default on modern Flutter; `useMaterial3` is
      // deprecated and omitted so the project compiles cleanly on Flutter 3.44.
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      highlightColor: Colors.transparent,
      dividerTheme: DividerThemeData(
        color: AppColors.glassBorder(brightness),
        thickness: 1,
        space: AppDimens.lg,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        foregroundColor: AppColors.textPrimary(brightness),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary(brightness)),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkBg2 : AppColors.lightBg2,
        contentTextStyle: textTheme.bodyMedium,
        shape: const RoundedRectangleBorder(borderRadius: AppDimens.brMd),
        insetPadding: const EdgeInsets.all(AppDimens.lg),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassFill(brightness),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted(brightness)),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppDimens.lg, vertical: AppDimens.lg),
        border: OutlineInputBorder(
          borderRadius: AppDimens.brMd,
          borderSide: BorderSide(color: AppColors.glassBorder(brightness)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimens.brMd,
          borderSide: BorderSide(color: AppColors.glassBorder(brightness)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppDimens.brMd,
          borderSide: BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimens.brMd,
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        prefixIconColor: AppColors.textMuted(brightness),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeThroughTransitionBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      extensions: [GlassTokens(brightness: brightness)],
    );
  }
}

/// Glass tokens exposed through [ThemeExtension] so any widget can read the
/// correct frosted-glass values for the active brightness via
/// `Theme.of(context).extension<GlassTokens>()`.
class GlassTokens extends ThemeExtension<GlassTokens> {
  const GlassTokens({required this.brightness});
  final Brightness brightness;

  Color get fill => AppColors.glassFill(brightness);
  Color get fillStrong => AppColors.glassFillStrong(brightness);
  Color get border => AppColors.glassBorder(brightness);
  Color get highlight => AppColors.glassHighlight(brightness);
  Color get shadow => AppColors.shadow(brightness);
  Color get textPrimary => AppColors.textPrimary(brightness);
  Color get textMuted => AppColors.textMuted(brightness);
  List<Color> get background =>
      brightness == Brightness.dark ? AppColors.darkBackground : AppColors.lightBackground;

  @override
  GlassTokens copyWith({Brightness? brightness}) => GlassTokens(brightness: brightness ?? this.brightness);

  @override
  GlassTokens lerp(ThemeExtension<GlassTokens>? other, double t) => this;
}

class _FadeThroughTransitionBuilder extends PageTransitionsBuilder {
  const _FadeThroughTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: AppMotion.emphasized);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}
