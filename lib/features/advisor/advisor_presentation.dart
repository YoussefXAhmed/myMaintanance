import 'package:flutter/material.dart';

import '../../core/ui_catalog.dart';
import '../../localization/app_localizations.dart';
import '../../services/ai_advisor_service.dart';
import '../../themes/app_colors.dart';

/// View model that turns a structured [AdvisorRecommendation] into localized,
/// renderable content. Shared by the dashboard reminders and advisor screen.
class AdvisorView {
  const AdvisorView({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.priorityLabel,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final String priorityLabel;

  static AdvisorView from(AdvisorRecommendation rec, AppLocalizations l) {
    final color = switch (rec.priority) {
      AdvisorPriority.high => AppColors.danger,
      AdvisorPriority.medium => AppColors.warning,
      AdvisorPriority.low => AppColors.info,
      AdvisorPriority.info => AppColors.success,
    };
    final priorityLabel = switch (rec.priority) {
      AdvisorPriority.high => l.t('priority_high'),
      AdvisorPriority.medium => l.t('priority_medium'),
      AdvisorPriority.low => l.t('priority_low'),
      AdvisorPriority.info => l.t('up_to_date'),
    };

    String absKm() => '${(rec.kmRemaining ?? 0).abs()} ${l.t('km')}';
    String absDays() => '${(rec.daysRemaining ?? 0).abs()}';

    switch (rec.kind) {
      case AdvisorKind.overdue:
        return AdvisorView(
          title: l.t(rec.type!.labelKey),
          body: '${l.t('overdue')} • ${absKm()}',
          icon: UiCatalog.maintenanceIcon(rec.type!),
          color: color,
          priorityLabel: priorityLabel,
        );
      case AdvisorKind.dueSoon:
        return AdvisorView(
          title: l.t(rec.type!.labelKey),
          body: '${l.t('due_soon')} • ${l.t('in_days', params: {'n': absDays()})}',
          icon: UiCatalog.maintenanceIcon(rec.type!),
          color: color,
          priorityLabel: priorityLabel,
        );
      case AdvisorKind.insurance:
        return AdvisorView(
          title: l.t('insurance_expiry'),
          body: l.t('in_days', params: {'n': absDays()}),
          icon: Icons.shield_rounded,
          color: color,
          priorityLabel: priorityLabel,
        );
      case AdvisorKind.license:
        return AdvisorView(
          title: l.t('license_expiry'),
          body: l.t('in_days', params: {'n': absDays()}),
          icon: Icons.badge_rounded,
          color: color,
          priorityLabel: priorityLabel,
        );
      case AdvisorKind.inspection:
        return AdvisorView(
          title: l.t('inspection_date'),
          body: l.t('in_days', params: {'n': absDays()}),
          icon: Icons.fact_check_rounded,
          color: color,
          priorityLabel: priorityLabel,
        );
      case AdvisorKind.mileageTrend:
      case AdvisorKind.allGood:
        return AdvisorView(
          title: l.t('up_to_date'),
          body: l.t('no_reminders'),
          icon: Icons.verified_rounded,
          color: AppColors.success,
          priorityLabel: priorityLabel,
        );
    }
  }
}
