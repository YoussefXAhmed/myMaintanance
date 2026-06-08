import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/ui_catalog.dart';
import '../../localization/app_localizations.dart';
import '../../models/enums.dart';
import '../../models/vehicle.dart';
import '../../providers/vehicle_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/glass_sheet.dart';
import '../../widgets/glass/glass_container.dart';

/// Network image with a branded gradient + car-silhouette fallback.
class VehicleImage extends StatelessWidget {
  const VehicleImage({super.key, required this.vehicle, this.height = 150, this.borderRadius = AppDimens.brLg});
  final Vehicle vehicle;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: Center(
        child: Icon(Icons.directions_car_filled_rounded, size: height * 0.45, color: Colors.white.withValues(alpha: 0.85)),
      ),
    );
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: (vehicle.imageUrl == null || vehicle.imageUrl!.isEmpty)
            ? fallback
            : Image.network(
                vehicle.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
                loadingBuilder: (c, child, p) => p == null ? child : fallback,
              ),
      ),
    );
  }
}

/// The hero card on the dashboard — image, title, key chips and mileage.
class VehicleHeroCard extends StatelessWidget {
  const VehicleHeroCard({super.key, required this.vehicle, this.onTap});
  final Vehicle vehicle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final glass = Theme.of(context).extension<GlassTokens>()!;
    return GlassContainer(
      padding: const EdgeInsets.all(AppDimens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              VehicleImage(vehicle: vehicle, height: 160),
              Positioned(
                top: AppDimens.md,
                right: AppDimens.md,
                child: _Chip(icon: UiCatalog.fuelIcon(vehicle.fuelType), label: l.t(vehicle.fuelType.labelKey)),
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
                    Text(vehicle.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: glass.textMuted)),
                  ],
                ),
              ),
              if (onTap != null)
                GestureDetector(
                  onTap: onTap,
                  child: GlassContainer(
                    shadow: false,
                    padding: const EdgeInsets.all(8),
                    borderRadius: BorderRadius.circular(12),
                    child: const Icon(Icons.unfold_more_rounded, size: 20),
                  ),
                ),
            ],
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

/// Bottom-sheet vehicle switcher with an "add vehicle" shortcut.
Future<void> showVehiclePicker(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final state = ref.read(vehiclesProvider);
  await showGlassSheet(
    context,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.t('switch_vehicle'), style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: AppDimens.lg),
        ...state.vehicles.map(
          (v) => Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.sm),
            child: GlassContainer(
              shadow: false,
              padding: const EdgeInsets.all(AppDimens.sm),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppDimens.sm),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(width: 52, height: 52, child: VehicleImage(vehicle: v, height: 52, borderRadius: BorderRadius.circular(10))),
                ),
                title: Text(v.title, style: Theme.of(context).textTheme.titleMedium),
                subtitle: Text(v.subtitle, style: Theme.of(context).textTheme.bodySmall),
                trailing: v.id == state.selectedId
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                    : const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  ref.read(vehiclesProvider.notifier).select(v.id);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimens.sm),
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            context.push(AppRoutes.addVehicle);
          },
          icon: const Icon(Icons.add_rounded, color: AppColors.primary),
          label: Text(l.t('add_vehicle'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.primary)),
        ),
      ],
    ),
  );
}
