import 'package:flutter/material.dart';

import '../../themes/app_colors.dart';
import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';
import '../glass/glass_card.dart';

/// Compact KPI tile used on the dashboard quick-stats grid.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
    this.gradient = AppColors.brandGradient,
    this.onTap,
    this.trend,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? unit;
  final Gradient gradient;
  final VoidCallback? onTap;
  final String? trend;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTokens>()!;
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(gradient: gradient, borderRadius: AppDimens.brSm),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const Spacer(),
              if (trend != null)
                Text(trend!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.success)),
            ],
          ),
          const SizedBox(height: AppDimens.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(unit!, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: glass.textMuted)),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: glass.textMuted)),
        ],
      ),
    );
  }
}
