import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../localization/app_localizations.dart';
import '../../providers/data_providers.dart';
import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';
import '../../widgets/glass/glass_container.dart';
import '../advisor/advisor_presentation.dart';

/// Compact list of the soonest reminders, shown on the dashboard.
class RemindersSection extends ConsumerWidget {
  const RemindersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final recs = ref.watch(advisorProvider).take(4).toList();
    if (recs.isEmpty) {
      return GlassContainer(
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, color: Color(0xFF34D399)),
            const SizedBox(width: AppDimens.md),
            Expanded(child: Text(l.t('no_reminders'), style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final rec in recs)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.sm),
            child: _ReminderTile(view: AdvisorView.from(rec, l)),
          ),
      ],
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.view});
  final AdvisorView view;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTokens>()!;
    return GlassContainer(
      padding: const EdgeInsets.all(AppDimens.md),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: view.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(view.icon, color: view.color, size: 22),
          ),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(view.title, style: Theme.of(context).textTheme.titleSmall),
                Text(view.body, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: glass.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: view.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(view.priorityLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: view.color)),
          ),
        ],
      ),
    );
  }
}
