import 'package:flutter/material.dart';

import '../../themes/app_colors.dart';
import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';
import 'glass_container.dart';

enum GlassButtonVariant { primary, glass, ghost }

/// Primary CTA / glass / ghost button with gradient fill, press spring and an
/// optional inline loading spinner.
class GlassButton extends StatefulWidget {
  const GlassButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = GlassButtonVariant.primary,
    this.gradient,
    this.expand = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final GlassButtonVariant variant;
  final Gradient? gradient;
  final bool expand;
  final bool loading;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final enabled = widget.onPressed != null && !widget.loading;
    final isPrimary = widget.variant == GlassButtonVariant.primary;

    final Color fg = switch (widget.variant) {
      GlassButtonVariant.primary => Colors.white,
      GlassButtonVariant.glass => glass.textPrimary,
      GlassButtonVariant.ghost => AppColors.primary,
    };

    final content = AnimatedSwitcher(
      duration: AppMotion.fast,
      child: widget.loading
          ? SizedBox(
              key: const ValueKey('loading'),
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 20, color: fg),
                  const SizedBox(width: AppDimens.sm),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                  ),
                ),
              ],
            ),
    );

    final body = AnimatedScale(
      scale: _pressed ? 0.96 : 1,
      duration: AppMotion.fast,
      child: isPrimary
          ? Container(
              height: 56,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.xl),
              decoration: BoxDecoration(
                gradient: enabled
                    ? (widget.gradient ?? AppColors.brandGradient)
                    : LinearGradient(colors: [glass.textMuted, glass.textMuted]),
                borderRadius: AppDimens.brMd,
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 24,
                          spreadRadius: -4,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : null,
              ),
              child: content,
            )
          : GlassContainer(
              height: 56,
              strong: widget.variant == GlassButtonVariant.glass,
              border: widget.variant == GlassButtonVariant.glass,
              shadow: false,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.xl),
              borderRadius: AppDimens.brMd,
              child: content,
            ),
    );

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: enabled ? widget.onPressed : null,
        child: widget.expand ? SizedBox(width: double.infinity, child: body) : body,
      ),
    );
  }
}
