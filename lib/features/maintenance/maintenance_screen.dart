import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/router/app_router.dart';
import '../../core/ui_catalog.dart';
import '../../localization/app_localizations.dart';
import '../../models/enums.dart';
import '../../models/maintenance_record.dart';
import '../../providers/data_controller.dart';
import '../../providers/data_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/health_service.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/glass_sheet.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/glass/glass_app_bar.dart';
import '../../widgets/glass/glass_card.dart';
import '../../widgets/glass/glass_container.dart';
import '../../widgets/states/empty_state.dart';
import 'add_maintenance_sheet.dart';

class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final vehicle = ref.watch(selectedVehicleProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Custom header.
            Padding(
              padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.sm, AppDimens.lg, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l.t('maintenance'), style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  CircleGlassButton(
                    icon: Icons.add_rounded,
                    onTap: () => showAddMaintenanceSheet(context, ref),
                  ),
                ],
              ),
            ),
            Expanded(
              child: vehicle == null
                  ? EmptyState(
                      icon: Icons.directions_car_filled_rounded,
                      title: l.t('no_vehicle_title'),
                      message: l.t('no_vehicle_body'),
                      actionLabel: l.t('add_vehicle'),
                      onAction: () => context.push(AppRoutes.addVehicle),
                    )
                  : const _MaintenanceBody(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceBody extends ConsumerWidget {
  const _MaintenanceBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final health = ref.watch(vehicleHealthProvider);
    final records = ref.watch(maintenanceListProvider);

    final statusByType = {for (final i in health.items) i.type: i};

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.lg, AppDimens.lg, 130),
          sliver: SliverList.list(
            children: [
              // Status grid for all 12 maintenance types.
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppDimens.md,
                crossAxisSpacing: AppDimens.md,
                childAspectRatio: 1.18,
                children: [
                  for (final type in MaintenanceType.values)
                    _StatusCard(
                      type: type,
                      info: statusByType[type],
                      onTap: () => showAddMaintenanceSheet(context, ref, initialType: type),
                    ),
                ],
              ),
              const SizedBox(height: AppDimens.lg),
              SectionHeader(title: l.t('maintenance_timeline')),
              if (records.isEmpty)
                EmptyState(
                  icon: Icons.build_rounded,
                  title: l.t('no_service_title'),
                  message: l.t('no_service_body'),
                  actionLabel: l.t('log_service'),
                  onAction: () => showAddMaintenanceSheet(context, ref),
                )
              else
                for (var i = 0; i < records.length; i++)
                  _TimelineTile(
                    record: records[i],
                    isFirst: i == 0,
                    isLast: i == records.length - 1,
                  )
                      .animate()
                      .fadeIn(delay: (40 * i).ms, duration: 320.ms)
                      .moveX(begin: 16, end: 0),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.type, required this.info, required this.onTap});
  final MaintenanceType type;
  final MaintenanceStatusInfo? info;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final glass = Theme.of(context).extension<GlassTokens>()!;

    final (pillColor, pillLabel) = switch (info?.status ?? DueStatus.unknown) {
      DueStatus.overdue => (AppColors.danger, l.t('overdue')),
      DueStatus.dueSoon => (AppColors.warning, l.t('due_soon')),
      DueStatus.ok => (AppColors.success, l.t('up_to_date')),
      DueStatus.unknown => (glass.textMuted, '—'),
    };

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  gradient: UiCatalog.maintenanceGradient(type),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(UiCatalog.maintenanceIcon(type), color: Colors.white, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: pillColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pillLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: pillColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.sm),
          Text(
            l.t(type.labelKey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const Spacer(),
          _DueSubtitle(info: info),
        ],
      ),
    );
  }
}

class _DueSubtitle extends ConsumerWidget {
  const _DueSubtitle({required this.info});
  final MaintenanceStatusInfo? info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final locale = ref.watch(settingsProvider).locale.languageCode;

    final i = info;
    String? text;
    if (i != null && i.nextDueMileage != null) {
      text = '${Fmt.number(i.nextDueMileage!, locale: locale)} ${l.t('km')}';
    } else if (i != null && i.nextDueDate != null) {
      text = Fmt.date(i.nextDueDate!, locale: locale);
    }

    return Text(
      text ?? '—',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: glass.textMuted),
    );
  }
}

class _TimelineTile extends ConsumerWidget {
  const _TimelineTile({required this.record, required this.isFirst, required this.isLast});
  final MaintenanceRecord record;
  final bool isFirst;
  final bool isLast;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final ok = await showGlassConfirm(
      context,
      title: l.t('delete'),
      message: l.isArabic ? 'حذف هذا السجل؟' : 'Delete this service record?',
      confirmLabel: l.t('delete'),
      cancelLabel: l.t('cancel'),
      destructive: true,
    );
    if (ok) {
      await ref.read(dataControllerProvider).deleteMaintenance(record.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final locale = ref.watch(settingsProvider).locale.languageCode;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline rail: node dot + connecting line.
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 8,
                  height: isFirst ? 0 : 16,
                  color: glass.border,
                ),
                Container(
                  height: 20,
                  width: 20,
                  decoration: BoxDecoration(
                    gradient: UiCatalog.maintenanceGradient(record.type),
                    shape: BoxShape.circle,
                    border: Border.all(color: glass.border),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 8, color: glass.border),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.md),
              child: GestureDetector(
                onLongPress: () => _confirmDelete(context, ref),
                child: GlassContainer(
                  padding: const EdgeInsets.all(AppDimens.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(UiCatalog.maintenanceIcon(record.type), size: 18, color: AppColors.primary),
                          const SizedBox(width: AppDimens.sm),
                          Expanded(
                            child: Text(
                              l.t(record.type.labelKey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          if (record.cost > 0)
                            Text(
                              Fmt.money(record.cost, currency: l.t('currency'), locale: locale),
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppColors.tertiary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.xs),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 13, color: glass.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            Fmt.date(record.changeDate, locale: locale),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: glass.textMuted),
                          ),
                          const SizedBox(width: AppDimens.md),
                          Icon(Icons.speed_rounded, size: 13, color: glass.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${Fmt.number(record.changeMileage, locale: locale)} ${l.t('km')}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: glass.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
