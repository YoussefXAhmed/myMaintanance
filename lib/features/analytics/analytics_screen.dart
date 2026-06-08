import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/router/app_router.dart';
import '../../core/ui_catalog.dart';
import '../../localization/app_localizations.dart';
import '../../models/enums.dart';
import '../../models/fuel_log.dart';
import '../../providers/data_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/stat_tile.dart';
import '../../widgets/glass/glass_app_bar.dart';
import '../../widgets/glass/glass_container.dart';
import '../../widgets/glass/glass_scaffold.dart';
import '../../widgets/states/empty_state.dart';

/// A safe finite double — replaces NaN/Infinity with [fallback].
double _safe(num v, {double fallback = 0}) {
  final d = v.toDouble();
  if (d.isNaN || d.isInfinite) return fallback;
  return d;
}

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final selectedVehicle = ref.watch(selectedVehicleProvider);

    if (selectedVehicle == null) {
      return GlassScaffoldGuard(
        title: l.t('analytics'),
        child: EmptyState(
          icon: Icons.bar_chart_rounded,
          title: l.t('no_vehicle_title'),
          message: l.t('no_vehicle_body'),
          actionLabel: l.t('add_vehicle'),
          onAction: () => context.push(AppRoutes.addVehicle),
        ),
      );
    }

    final locale = ref.watch(settingsProvider).locale.languageCode;
    final expenseStats = ref.watch(expenseStatsProvider);
    final fuelStats = ref.watch(fuelStatsProvider);
    final fuelLogs = ref.watch(fuelListProvider);
    final maintenance = ref.watch(maintenanceListProvider);
    final currency = l.t('currency');

    final maintenanceTotal =
        maintenance.fold<double>(0, (s, m) => s + (m.cost > 0 ? m.cost : 0));

    final sections = <Widget>[
      // ---------------------------------------------------------------------
      // Section 1 — Monthly spending
      // ---------------------------------------------------------------------
      SectionHeader(title: l.t('monthly_spending')),
      _MonthlySpendingCard(
        series: expenseStats.monthlySeries,
        yearly: expenseStats.yearly,
        currency: currency,
        locale: locale,
      ),

      // ---------------------------------------------------------------------
      // Section 2 — Spending breakdown
      // ---------------------------------------------------------------------
      if (expenseStats.byCategory.values.any((v) => _safe(v) > 0)) ...[
        const SizedBox(height: AppDimens.lg),
        SectionHeader(title: l.t('spending_breakdown')),
        _BreakdownCard(
          byCategory: expenseStats.byCategory,
          currency: currency,
          locale: locale,
        ),
      ],

      // ---------------------------------------------------------------------
      // Section 3 — Fuel usage
      // ---------------------------------------------------------------------
      const SizedBox(height: AppDimens.lg),
      SectionHeader(title: l.t('fuel_usage')),
      _FuelUsageCard(
        logs: fuelLogs,
        kmPerLiter: fuelStats.kmPerLiter,
        locale: locale,
      ),

      // ---------------------------------------------------------------------
      // Section 4 — Cost summary
      // ---------------------------------------------------------------------
      const SizedBox(height: AppDimens.lg),
      SectionHeader(title: l.t('cost_trends')),
      _CostSummaryGrid(
        total: expenseStats.total,
        monthlyFuel: fuelStats.monthlySpend,
        maintenance: maintenanceTotal,
        yearly: expenseStats.yearly,
        currency: currency,
        locale: locale,
      ),
    ];

    return GlassScaffoldGuard(
      title: l.t('analytics'),
      subtitle: selectedVehicle.title,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.lg, AppDimens.lg, AppDimens.xl),
          children: [
            for (var i = 0; i < sections.length; i++)
              sections[i]
                  .animate()
                  .fadeIn(delay: (i * 60).ms, duration: 380.ms)
                  .moveY(begin: 14, end: 0),
          ],
        ),
      ),
    );
  }
}

/// Tiny wrapper so the empty-state and content paths share the same scaffold.
class GlassScaffoldGuard extends StatelessWidget {
  const GlassScaffoldGuard({super.key, required this.title, this.subtitle, required this.child});
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar(title: title, subtitle: subtitle, showBack: true),
      body: child,
    );
  }
}

// ===========================================================================
// Section 1 — Monthly spending (BarChart)
// ===========================================================================
class _MonthlySpendingCard extends StatelessWidget {
  const _MonthlySpendingCard({
    required this.series,
    required this.yearly,
    required this.currency,
    required this.locale,
  });

  final List<double> series;
  final double yearly;
  final String currency;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final glass = Theme.of(context).extension<GlassTokens>()!;

    // Normalise to 6 finite values (oldest -> newest).
    final values = List<double>.generate(
      6,
      (i) => i < series.length ? _safe(series[i]).clamp(0, double.maxFinite).toDouble() : 0.0,
    );

    // Month short-labels ending at the current month.
    final now = DateTime.now();
    final labels = List<String>.generate(6, (i) {
      final m = DateTime(now.year, now.month - (5 - i), 1);
      // 'MMM yyyy' -> take the month token only for a compact axis label.
      return Fmt.monthYear(m, locale: locale).split(' ').first;
    });

    final maxVal = values.fold<double>(0, (m, v) => v > m ? v : m);
    final maxY = maxVal <= 0 ? 1.0 : maxVal * 1.25;

    return GlassContainer(
      blur: AppDimens.blurStrong,
      padding: const EdgeInsets.all(AppDimens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Total this year stat.
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(l.t('this_year'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: glass.textMuted)),
              const Spacer(),
              GradientText(
                Fmt.money(_safe(yearly), currency: currency, locale: locale),
                style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.lg),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                minY: 0,
                maxY: maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => glass.fillStrong,
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      Fmt.money(rod.toY, currency: currency, locale: locale),
                      Theme.of(context).textTheme.labelMedium!.copyWith(
                            color: glass.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[i],
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: glass.textMuted),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < values.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i],
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          gradient: AppColors.brandGradient,
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: glass.fill,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Section 2 — Spending breakdown (PieChart + legend)
// ===========================================================================
class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.byCategory,
    required this.currency,
    required this.locale,
  });

  final Map<ExpenseCategory, double> byCategory;
  final String currency;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    // Sorted, positive, finite slices.
    final entries = byCategory.entries
        .map((e) => MapEntry(e.key, _safe(e.value)))
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) return const SizedBox.shrink();

    final total = entries.fold<double>(0, (s, e) => s + e.value);

    return GlassContainer(
      blur: AppDimens.blurStrong,
      padding: const EdgeInsets.all(AppDimens.lg),
      child: Row(
        children: [
          SizedBox(
            height: 160,
            width: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                startDegreeOffset: -90,
                sections: [
                  for (final e in entries)
                    PieChartSectionData(
                      value: e.value,
                      color: UiCatalog.expenseColor(e.key),
                      radius: 36,
                      showTitle: false,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppDimens.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final e in entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: _LegendRow(
                      color: UiCatalog.expenseColor(e.key),
                      label: l.t(e.key.labelKey),
                      value: Fmt.money(e.value, currency: currency, locale: locale),
                      percent: total > 0 ? (e.value / total * 100) : 0,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
    required this.percent,
  });

  final Color color;
  final String label;
  final String value;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTokens>()!;
    return Row(
      children: [
        Container(
          height: 10,
          width: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: AppDimens.sm),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(width: AppDimens.sm),
        Text(
          value,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 6),
        Text(
          '${percent.toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: glass.textMuted),
        ),
      ],
    );
  }
}

// ===========================================================================
// Section 3 — Fuel usage (LineChart)
// ===========================================================================
class _FuelUsageCard extends StatelessWidget {
  const _FuelUsageCard({
    required this.logs,
    required this.kmPerLiter,
    required this.locale,
  });

  final List<FuelLog> logs;
  final double kmPerLiter;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final glass = Theme.of(context).extension<GlassTokens>()!;

    // Sort ascending by odometer; km/L per consecutive fill.
    final sorted = [...logs]..sort((a, b) => a.odometer.compareTo(b.odometer));
    final points = <FlSpot>[];
    for (var i = 1; i < sorted.length; i++) {
      final liters = sorted[i].liters;
      if (liters <= 0) continue;
      final dist = sorted[i].odometer - sorted[i - 1].odometer;
      if (dist <= 0) continue;
      final y = _safe(dist / liters);
      if (y <= 0) continue;
      points.add(FlSpot(points.length.toDouble(), y));
    }

    final hasChart = points.length >= 2;
    final maxY =
        hasChart ? points.map((p) => p.y).reduce((a, b) => a > b ? a : b) * 1.2 : 1.0;

    return GlassContainer(
      blur: AppDimens.blurStrong,
      padding: const EdgeInsets.all(AppDimens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Average km/L stat.
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(l.t('km_per_liter'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: glass.textMuted)),
              const Spacer(),
              GradientText(
                kmPerLiter > 0 ? Fmt.number(_safe(kmPerLiter), decimals: 1, locale: locale) : '—',
                gradient: AppColors.mintGradient,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          if (hasChart) ...[
            const SizedBox(height: AppDimens.lg),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => glass.fillStrong,
                      getTooltipItems: (spots) => [
                        for (final s in spots)
                          LineTooltipItem(
                            '${Fmt.number(s.y, decimals: 1, locale: locale)} ${l.t('km_per_liter')}',
                            Theme.of(context).textTheme.labelMedium!.copyWith(
                                  color: glass.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                      ],
                    ),
                  ),
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
        ],
      ),
    );
  }
}

// ===========================================================================
// Section 4 — Cost summary (StatTile grid)
// ===========================================================================
class _CostSummaryGrid extends StatelessWidget {
  const _CostSummaryGrid({
    required this.total,
    required this.monthlyFuel,
    required this.maintenance,
    required this.yearly,
    required this.currency,
    required this.locale,
  });

  final double total;
  final double monthlyFuel;
  final double maintenance;
  final double yearly;
  final String currency;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    String money(double v) {
      final safe = _safe(v);
      return safe > 0 ? Fmt.money(safe, currency: currency, locale: locale) : '—';
    }

    final tiles = <Widget>[
      StatTile(
        icon: Icons.account_balance_wallet_rounded,
        label: l.t('total_spent'),
        value: money(total),
        gradient: AppColors.brandGradient,
      ),
      StatTile(
        icon: Icons.local_gas_station_rounded,
        label: l.t('monthly_fuel'),
        value: money(monthlyFuel),
        gradient: AppColors.mintGradient,
      ),
      StatTile(
        icon: Icons.build_rounded,
        label: l.t('maintenance_costs'),
        value: money(maintenance),
        gradient: AppColors.sunsetGradient,
      ),
      StatTile(
        icon: Icons.calendar_today_rounded,
        label: l.t('this_year'),
        value: money(yearly),
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
