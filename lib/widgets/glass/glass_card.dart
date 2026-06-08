import 'package:flutter/material.dart';

import '../../themes/app_dimens.dart';
import 'glass_container.dart';

/// A tappable [GlassContainer] with a spring press-down micro-interaction.
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = AppDimens.cardPadding,
    this.margin,
    this.borderRadius = AppDimens.brLg,
    this.blur = AppDimens.blurMedium,
    this.strong = false,
    this.gradient,
    this.width,
    this.height,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius borderRadius;
  final double blur;
  final bool strong;
  final Gradient? gradient;
  final double? width;
  final double? height;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _pressed = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        child: GlassContainer(
          padding: widget.padding,
          margin: widget.margin,
          borderRadius: widget.borderRadius,
          blur: widget.blur,
          strong: widget.strong,
          gradient: widget.gradient,
          width: widget.width,
          height: widget.height,
          child: widget.child,
        ),
      ),
    );
  }
}
