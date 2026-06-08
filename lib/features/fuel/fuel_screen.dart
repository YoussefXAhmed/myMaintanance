import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/router/app_router.dart';
import '../../localization/app_localizations.dart';
import '../../models/fuel_log.dart';
import '../../providers/data_controller.dart';
import '../../providers/data_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/glass_sheet.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/stat_tile.dart';
import '../../widgets/glass/glass_app_bar.dart';
import '../../widgets/glass/glass_container.dart';
import '../../widgets/states/empty_state.dart';
import 'add_fuel_sheet.dart';

class FuelScreen extends ConsumerWidget {
  const FuelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
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
                      child: Text(l.t('fuel'), style: Theme.of(context).textTheme.headlineSmall),
                    ),
                    CircleGlassButton(
                      icon: Icons.add_rounded,
                      onTap: () => showAddFuelSheet(context, ref),
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
                    const _FuelStatsGrid()
                        .animate()
                        .fadeIn(duration: 350.ms)
                        .moveY(begin: 14, end: 0),
                    const SizedBox(height: AppDimens.lg),
                    const _ConsumptionChart(),
                    SectionHeader(title: l.t('fuel_log')),
                    const _FuelLogList(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FuelStatsGrid extends ConsumerWidget {
  const _FuelStatsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final locale = ref.watch(settingsProvider).locale.languageCode;
    final stats = ref.watch(fuelStatsProvider);

    String num1(double v) => v > 0 ? Fmt.number(v, decimals: 1, locale: locale) : '—';
    String num0(double v) => v > 0 ? Fmt.number(v, locale: locale) : '—';

    final tiles = <Widget>[
      StatTile(
        icon: Icons.speed_rounded,
        label: l.t('avg_consumption'),
        value: num1(stats.kmPerLiter),
        unit: l.t('km_per_liter'),
        gradient: AppColors.mintGradient,
      ),
      StatTile(
        icon: Icons.route_rounded,
        label: l.t('cost_per_km'),
        value: stats.costPerKm > 0 ? Fmt.number(stats.costPerKm, decimals: 2, locale: locale) : '—',
        unit: l.t('currency'),
        gradient: AppColors.brandGradient,
      ),
      StatTile(
        icon: Icons.calendar_month_rounded,
        label: l.t('monthly_fuel'),
        value: num0(stats.monthlySpend),
        unit: l.t('currency'),
        gradient: AppColors.sunsetGradient,
      ),
      StatTile(
        icon: Icons.calendar_today_rounded,
        label: l.t('yearly_fuel'),
        value: num0(stats.yearlySpend),
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

class _ConsumptionChart extends ConsumerWidget {
  const _ConsumptionChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final logs = ref.watch(fuelListProvider);
    if (logs.length < 2) return const SizedBox.shrink();

    final sorted = [...logs]..sort((a, b) => a.odometer.compareTo(b.odometer));

    // km/L between consecutive fills.
    final points = <FlSpot>[];
    for (var i = 1; i < sorted.length; i++) {
      final liters = sorted[i].liters;
      if (liters <= 0) continue;
      final dist = sorted[i].odometer - sorted[i - 1].odometer;
      if (dist <= 0) continue;
      points.add(FlSpot(points.length.toDouble(), dist / liters));
    }
    if (points.length < 2) return const SizedBox.shrink();

    final maxY = points.map((p) => p.y).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassContainer(
          blur: AppDimens.blurStrong,
          padding: const EdgeInsets.all(AppDimens.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(title: l.t('fuel_usage')),
              SizedBox(
                height: 160,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: maxY * 1.2,
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineTouchData: const LineTouchData(enabled: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: points,
                        isCurved: true,
                        barWidth: 3,
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.tertiary],
                        ),
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.primary.withValues(alpha: 0.25),
                              AppColors.tertiary.withValues(alpha: 0.02),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 80.ms, duration: 400.ms).moveY(begin: 14, end: 0),
        const SizedBox(height: AppDimens.sm),
      ],
    );
  }
}

class _FuelLogList extends ConsumerWidget {
  const _FuelLogList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final logs = ref.watch(fuelListProvider);

    if (logs.isEmpty) {
      return EmptyState(
        icon: Icons.local_gas_station_rounded,
        title: l.t('no_fuel_title'),
        message: l.t('no_fuel_body'),
        actionLabel: l.t('add_fuel'),
        onAction: () => showAddFuelSheet(context, ref),
      );
    }

    // Newest first.
    final sorted = [...logs]..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: [
        for (final log in sorted)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.sm),
            child: _FuelRow(log: log),
          ),
      ],
    );
  }
}

class _FuelRow extends ConsumerWidget {
  const _FuelRow({required this.log});
  final FuelLog log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final locale = ref.watch(settingsProvider).locale.languageCode;
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final currency = l.t('currency');

    Future<void> confirmDelete() async {
      final ok = await showGlassConfirm(
        context,
        title: l.t('delete'),
        message: l.isArabic ? 'حذف هذه التعبئة؟' : 'Delete this fuel entry?',
        confirmLabel: l.t('delete'),
        cancelLabel: l.t('cancel'),
        destructive: true,
      );
      if (ok) await ref.read(dataControllerProvider).deleteFuel(log.id);
    }

    return GestureDetector(
      onLongPress: confirmDelete,
      child: GlassContainer(
        shadow: false,
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(gradient: AppColors.mintGradient, borderRadius: AppDimens.brSm),
              child: const Icon(Icons.local_gas_station_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.station.isEmpty ? l.t('fuel') : log.station,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${Fmt.date(log.date, locale: locale)}  •  '
                    '${Fmt.number(log.liters, decimals: 1, locale: locale)} ${l.t('liter')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: glass.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimens.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Fmt.money(log.cost, currency: currency, locale: locale),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${Fmt.number(log.pricePerLiter, decimals: 2, locale: locale)} $currency / ${l.t('liter')}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: glass.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
