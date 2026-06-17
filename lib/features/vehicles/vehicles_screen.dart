import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/router/app_router.dart';
import '../../core/ui_catalog.dart';
import '../../localization/app_localizations.dart';
import '../../models/enums.dart';
import '../../models/vehicle.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/glass_sheet.dart';
import '../../widgets/glass/glass_app_bar.dart';
import '../../widgets/glass/glass_card.dart';
import '../../widgets/glass/glass_container.dart';
import '../../widgets/glass/glass_scaffold.dart';
import '../../widgets/states/empty_state.dart';
import 'vehicle_widgets.dart';

/// The garage: every vehicle the user owns, with select / edit / delete.
class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final state = ref.watch(vehiclesProvider);

    return GlassScaffold(
      appBar: GlassAppBar(
        title: l.t('my_vehicles'),
        showBack: true,
        actions: [
          CircleGlassButton(
            icon: Icons.add_rounded,
            onTap: () => context.push(AppRoutes.addVehicle),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: state.isEmpty
            ? EmptyState(
                icon: Icons.directions_car_filled_rounded,
                title: l.t('no_vehicle_title'),
                message: l.t('no_vehicle_body'),
                actionLabel: l.t('add_vehicle'),
                onAction: () => context.push(AppRoutes.addVehicle),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.lg, AppDimens.lg, AppDimens.xxl),
                itemCount: state.vehicles.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppDimens.lg),
                itemBuilder: (context, i) {
                  final v = state.vehicles[i];
                  return _VehicleTile(
                    vehicle: v,
                    selected: v.id == state.selectedId,
                  ).animate().fadeIn(delay: (60 * i).ms, duration: 350.ms).moveY(begin: 14, end: 0);
                },
              ),
      ),
    );
  }
}

class _VehicleTile extends ConsumerWidget {
  const _VehicleTile({required this.vehicle, required this.selected});
  final Vehicle vehicle;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final locale = ref.watch(settingsProvider).locale.languageCode;
    final glass = Theme.of(context).extension<GlassTokens>()!;

    void select() {
      ref.read(vehiclesProvider.notifier).select(vehicle.id);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('${l.t('switch_vehicle')}: ${vehicle.title}')),
        );
    }

    Future<void> confirmDelete() async {
      final ok = await showGlassConfirm(
        context,
        title: l.isArabic ? 'حذف المركبة' : 'Delete Vehicle',
        message: l.t('delete_vehicle_confirm'),
        confirmLabel: l.t('delete'),
        cancelLabel: l.t('cancel'),
        destructive: true,
      );
      if (ok) await ref.read(vehiclesProvider.notifier).delete(vehicle.id);
    }

    return GestureDetector(
      onLongPress: confirmDelete,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppDimens.brLg,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 26,
                    spreadRadius: -4,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: GlassCard(
          onTap: select,
          padding: const EdgeInsets.all(AppDimens.md),
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.22),
                    AppColors.secondary.withValues(alpha: 0.12),
                  ],
                )
              : null,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppDimens.brLg,
              border: selected ? Border.all(color: AppColors.primary, width: 1.4) : null,
            ),
            padding: selected ? const EdgeInsets.all(AppDimens.xs) : EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    VehicleImage(vehicle: vehicle, height: 130),
                    if (vehicle.isPrimary)
                      Positioned(
                        top: AppDimens.sm,
                        left: AppDimens.sm,
                        child: _PrimaryBadge(label: l.isArabic ? 'رئيسية' : 'Primary'),
                      ),
                    if (selected)
                      const Positioned(
                        top: AppDimens.sm,
                        right: AppDimens.sm,
                        child: Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 26),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimens.md),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(vehicle.title, style: Theme.of(context).textTheme.titleLarge),
                          Text(
                            vehicle.subtitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: glass.textMuted),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.addVehicle, extra: vehicle),
                      child: GlassContainer(
                        shadow: false,
                        padding: const EdgeInsets.all(8),
                        borderRadius: BorderRadius.circular(12),
                        child: const Icon(Icons.edit_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.md),
                Wrap(
                  spacing: AppDimens.sm,
                  runSpacing: AppDimens.sm,
                  children: [
                    _Chip(
                      icon: Icons.speed_rounded,
                      label: '${Fmt.number(vehicle.currentMileage, locale: locale)} ${l.t('km')}',
                    ),
                    _Chip(
                      icon: UiCatalog.fuelIcon(vehicle.fuelType),
                      label: l.t(vehicle.fuelType.labelKey),
                    ),
                    _Chip(
                      icon: Icons.settings_rounded,
                      label: l.t(vehicle.transmission.labelKey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryBadge extends StatelessWidget {
  const _PrimaryBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      strong: true,
      shadow: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 5),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
