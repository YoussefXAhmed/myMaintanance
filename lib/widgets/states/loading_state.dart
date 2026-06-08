import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../themes/app_colors.dart';
import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';

/// Elegant shimmer placeholder used while data loads.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({super.key, this.height = 16, this.width = double.infinity, this.radius = AppDimens.radiusSm});
  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTokens>()!;
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: glass.fill,
        borderRadius: BorderRadius.circular(radius),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1400.ms, color: glass.highlight.withValues(alpha: 0.35));
  }
}

/// Centered branded loader.
class GlassLoader extends StatelessWidget {
  const GlassLoader({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTokens>()!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 54,
            width: 54,
            child: CircularProgressIndicator(strokeWidth: 3.2, color: AppColors.primary, backgroundColor: glass.border),
          )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(begin: 0.9, end: 1.05, duration: 900.ms, curve: Curves.easeInOut)
              .then()
              .scaleXY(begin: 1.05, end: 0.9, duration: 900.ms, curve: Curves.easeInOut),
          if (message != null) ...[
            const SizedBox(height: AppDimens.lg),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: glass.textMuted)),
          ],
        ],
      ),
    );
  }
}
