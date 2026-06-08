import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../themes/app_colors.dart';
import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';
import '../glass/glass_button.dart';

/// Modern, friendly empty state with a floating glass icon medallion.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTokens>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 104,
              width: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.25),
                    AppColors.secondary.withValues(alpha: 0.18),
                  ],
                ),
                border: Border.all(color: glass.border),
              ),
              child: Icon(icon, size: 46, color: AppColors.primary),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
                  begin: -6,
                  end: 6,
                  duration: 2200.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: AppDimens.xl),
            Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppDimens.sm),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: glass.textMuted),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppDimens.xl),
              GlassButton(label: actionLabel!, onPressed: onAction, expand: false, icon: Icons.add_rounded),
            ],
          ],
        ),
      ),
    );
  }
}
