import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/router/app_router.dart';
import '../../localization/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/stat_tile.dart';
import '../../widgets/glass/glass_app_bar.dart';
import '../../widgets/glass/glass_card.dart';
import '../../widgets/glass/glass_container.dart';
import '../../widgets/indicators/circular_health_indicator.dart';
import '../../widgets/states/empty_state.dart';
import '../vehicles/vehicle_widgets.dart';
import 'reminders_section.dart';

class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key});

  String _greetingKey() {
    final h = DateTime.now().hour;
    if (h < 12) return 'good_morning';
    if (h < 18) return 'good_afternoon';
    return 'good_evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final user = ref.watch(authControllerProvider).user;
    final vehicle = ref.watch(selectedVehicleProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.sm, AppDimens.lg, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.t(_greetingKey()),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: glass.textMuted)),
                          Text(user?.displayName ?? l.t('app_name'),
                              style: Theme.of(context).textTheme.headlineSmall),
                        ],
                      ),
                    ),
                    CircleGlassButton(
                      icon: Icons.notifications_none_rounded,
                      badge: ref.watch(advisorProvider).length > 1,
                      onTap: () => context.push(AppRoutes.advisor),
                    ),
                    const SizedBox(width: AppDimens.sm),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.profile),
                      child: _Avatar(initials: user?.initials ?? '?'),
                    ),
                  ],
                ),
              ),
            ),
            if (vehicle == null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.directions_car_filled_rounded,
                  title: l.t('no_vehicle_title'),
                  message: l.t('no_vehicle_body'),
                  actionLabel: l.t('add_vehicle'),
                  onAction: () => context.push(AppRoutes.addVehicle),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.lg, AppDimens.lg, 130),
                sliver: SliverList.list(
                  children: [
                    VehicleHeroCard(vehicle: vehicle, onTap: () => showVehiclePicker(context, ref))
                        .animate()
                        .fadeIn(duration: 350.ms)
                        .moveY(begin: 14, end: 0),
                    const SizedBox(height: AppDimens.lg),
                    const _HealthCard().animate().fadeIn(delay: 80.ms, duration: 400.ms).moveY(begin: 14, end: 0),
                    const SizedBox(height: AppDimens.lg),
                    SectionHeader(title: l.t('quick_stats')),
                    const _QuickStatsGrid(),
                    const SizedBox(height: AppDimens.sm),
                    SectionHeader(title: l.t('quick_actions')),
                    const _QuickActions(),
                    const SizedBox(height: AppDimens.lg),
                    SectionHeader(
                      title: l.t('upcoming_reminders'),
                      actionLabel: l.t('see_all'),
                      onAction: () => context.push(AppRoutes.advisor),
                    ),
                    const RemindersSection(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(14)),
      child: Text(initials,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
    );
  }
}

class _HealthCard extends ConsumerWidget {
  const _HealthCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final health = ref.watch(vehicleHealthProvider);
    return GlassContainer(
      blur: AppDimens.blurStrong,
      padding: const EdgeInsets.all(AppDimens.xl),
      child: Column(
        children: [
          CircularHealthIndicator(value: health.overall, label: l.t('vehicle_health'), size: 190),
          const SizedBox(height: AppDimens.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MiniHealthRing(value: health.oil, icon: Icons.oil_barrel_rounded, label: l.t('oil_health')),
              MiniHealthRing(value: health.battery, icon: Icons.battery_charging_full_rounded, label: l.t('battery_health')),
              MiniHealthRing(value: health.tires, icon: Icons.trip_origin_rounded, label: l.t('tire_health')),
              MiniHealthRing(value: health.insurance, icon: Icons.shield_rounded, label: l.t('insurance_status')),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStatsGrid extends ConsumerWidget {
  const _QuickStatsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final locale = ref.watch(settingsProvider).locale.languageCode;
    final vehicle = ref.watch(selectedVehicleProvider)!;
    final fuelStats = ref.watch(fuelStatsProvider);
    final expenseStats = ref.watch(expenseStatsProvider);
    final health = ref.watch(vehicleHealthProvider);

    // Nearest upcoming service.
    final upcoming = health.items.where((i) => i.nextDueMileage != null).toList()
      ..sort((a, b) => (a.kmRemaining ?? 1 << 30).compareTo(b.kmRemaining ?? 1 << 30));
    final nextKm = upcoming.isEmpty ? null : upcoming.first.kmRemaining;

    final tiles = [
      StatTile(
        icon: Icons.speed_rounded,
        label: l.t('current_mileage'),
        value: Fmt.number(vehicle.currentMileage, locale: locale),
        unit: l.t('km'),
        gradient: AppColors.brandGradient,
      ),
      StatTile(
        icon: Icons.local_gas_station_rounded,
        label: l.t('fuel_economy'),
        value: fuelStats.kmPerLiter > 0 ? Fmt.number(fuelStats.kmPerLiter, decimals: 1, locale: locale) : '—',
        unit: l.t('km_per_liter'),
        gradient: AppColors.mintGradient,
      ),
      StatTile(
        icon: Icons.event_available_rounded,
        label: l.t('upcoming_service'),
        value: nextKm == null ? '—' : Fmt.number(nextKm.clamp(0, 1 << 30), locale: locale),
        unit: nextKm == null ? null : l.t('km'),
        gradient: AppColors.sunsetGradient,
      ),
      StatTile(
        icon: Icons.account_balance_wallet_rounded,
        label: l.t('monthly_expenses'),
        value: Fmt.number(expenseStats.monthly, locale: locale),
        unit: l.t('currency'),
        gradient: const LinearGradient(colors: [AppColors.secondary, AppColors.accentPink]),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimens.md,
      crossAxisSpacing: AppDimens.md,
      childAspectRatio: 1.45,
      children: tiles,
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final actions = [
      (_QA(Icons.local_gas_station_rounded, l.t('log_fuel'), AppColors.mintGradient, AppRoutes.fuel)),
      (_QA(Icons.build_rounded, l.t('add_service'), AppColors.brandGradient, AppRoutes.maintenance)),
      (_QA(Icons.account_balance_wallet_rounded, l.t('add_expense'), AppColors.sunsetGradient, AppRoutes.expenses)),
      (_QA(Icons.auto_awesome_rounded, l.t('ai_advisor'),
          const LinearGradient(colors: [AppColors.secondary, AppColors.primary]), AppRoutes.advisor)),
    ];
    return Row(
      children: [
        for (final a in actions)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
                onTap: () => a.route == AppRoutes.advisor ? context.push(a.route) : context.go(a.route),
                child: Column(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(gradient: a.gradient, borderRadius: BorderRadius.circular(14)),
                      child: Icon(a.icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(height: AppDimens.sm),
                    Text(a.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _QA {
  const _QA(this.icon, this.label, this.gradient, this.route);
  final IconData icon;
  final String label;
  final Gradient gradient;
  final String route;
}
