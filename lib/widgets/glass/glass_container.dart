import 'dart:ui';
import 'package:flutter/material.dart';

import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';

/// The foundational frosted-glass surface. Everything visual in the app is
/// built from this: a [BackdropFilter] blur, a translucent fill, a soft 1px
/// light border, a top highlight reflection and a soft drop shadow.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = AppDimens.cardPadding,
    this.margin,
    this.borderRadius = AppDimens.brLg,
    this.blur = AppDimens.blurMedium,
    this.strong = false,
    this.gradient,
    this.border = true,
    this.shadow = true,
    this.width,
    this.height,
    this.alignment,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius borderRadius;
  final double blur;

  /// Uses the higher-opacity fill (for floating/elevated surfaces).
  final bool strong;

  /// Optional accent gradient layered over the glass fill.
  final Gradient? gradient;
  final bool border;
  final bool shadow;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final fill = strong ? glass.fillStrong : glass.fill;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: glass.shadow,
                  blurRadius: 30,
                  spreadRadius: -6,
                  offset: const Offset(0, 18),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            alignment: alignment,
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: gradient ??
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [fill, fill.withValues(alpha: fill.a * 0.55)],
                  ),
              border: border ? Border.all(color: glass.border, width: 1) : null,
            ),
            child: Stack(
              children: [
                // Top edge highlight — the signature liquid-glass reflection.
                Positioned(
                  top: 0,
                  left: 16,
                  right: 16,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          glass.highlight.withValues(alpha: 0),
                          glass.highlight,
                          glass.highlight.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
