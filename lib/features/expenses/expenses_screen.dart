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
import '../../models/expense.dart';
import '../../providers/data_controller.dart';
import '../../providers/data_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/glass_sheet.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/glass/glass_app_bar.dart';
import '../../widgets/glass/glass_container.dart';
import '../../widgets/states/empty_state.dart';
import 'add_expense_sheet.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

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
                      child: Text(l.t('expenses'), style: Theme.of(context).textTheme.headlineSmall),
                    ),
                    CircleGlassButton(
                      icon: Icons.add_rounded,
                      onTap: () => showAddExpenseSheet(context, ref),
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
                    const _SummaryCard()
                        .animate()
                        .fadeIn(duration: 350.ms)
                        .moveY(begin: 14, end: 0),
                    const SizedBox(height: AppDimens.lg),
                    const _CategoryBreakdown(),
                    SectionHeader(title: l.t('expenses')),
                    const _ExpenseList(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final locale = ref.watch(settingsProvider).locale.languageCode;
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final stats = ref.watch(expenseStatsProvider);
    final currency = l.t('currency');

    return GlassContainer(
      blur: AppDimens.blurStrong,
      padding: const EdgeInsets.all(AppDimens.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.t('monthly_expenses'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: glass.textMuted),
          ),
          const SizedBox(height: AppDimens.xs),
          GradientText(
            Fmt.money(stats.monthly, currency: currency, locale: locale),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800) ??
                const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppDimens.md),
          Row(
            children: [
              Text(
                '${l.t('yearly_report')}: ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: glass.textMuted),
              ),
              Text(
                Fmt.money(stats.yearly, currency: currency, locale: locale),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryBreakdown extends ConsumerWidget {
  const _CategoryBreakdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final locale = ref.watch(settingsProvider).locale.languageCode;
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final byCategory = ref.watch(expenseStatsProvider).byCategory;
    final currency = l.t('currency');

    if (byCategory.isEmpty) return const SizedBox.shrink();

    final entries = byCategory.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) return const SizedBox.shrink();

    final sections = <PieChartSectionData>[
      for (final e in entries)
        PieChartSectionData(
          value: e.value,
          color: UiCatalog.expenseColor(e.key),
          radius: 46,
          showTitle: false,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l.t('by_category')),
        GlassContainer(
          blur: AppDimens.blurStrong,
          padding: const EdgeInsets.all(AppDimens.lg),
          child: Row(
            children: [
              SizedBox(
                height: 150,
                width: 150,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 28,
                    sectionsSpace: 2,
                    pieTouchData: PieTouchData(enabled: false),
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final e in entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              height: 10,
                              width: 10,
                              decoration: BoxDecoration(
                                color: UiCatalog.expenseColor(e.key),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppDimens.sm),
                            Expanded(
                              child: Text(
                                l.t(e.key.labelKey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: glass.textMuted),
                              ),
                            ),
                            const SizedBox(width: AppDimens.sm),
                            Text(
                              Fmt.money(e.value, currency: currency, locale: locale),
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                  ],
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

class _ExpenseList extends ConsumerWidget {
  const _ExpenseList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final expenses = ref.watch(expenseListProvider);

    if (expenses.isEmpty) {
      return EmptyState(
        icon: Icons.account_balance_wallet_rounded,
        title: l.t('no_expense_title'),
        message: l.t('no_expense_body'),
        actionLabel: l.t('add_expense'),
        onAction: () => showAddExpenseSheet(context, ref),
      );
    }

    // Newest first.
    final sorted = [...expenses]..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: [
        for (final expense in sorted)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.sm),
            child: _ExpenseRow(expense: expense),
          ),
      ],
    );
  }
}

class _ExpenseRow extends ConsumerWidget {
  const _ExpenseRow({required this.expense});
  final Expense expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final locale = ref.watch(settingsProvider).locale.languageCode;
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final color = UiCatalog.expenseColor(expense.category);
    final title = expense.title.isNotEmpty ? expense.title : l.t(expense.category.labelKey);

    Future<void> confirmDelete() async {
      final ok = await showGlassConfirm(
        context,
        title: l.t('delete'),
        message: l.isArabic ? 'حذف هذا المصروف؟' : 'Delete this expense?',
        confirmLabel: l.t('delete'),
        cancelLabel: l.t('cancel'),
        destructive: true,
      );
      if (ok) await ref.read(dataControllerProvider).deleteExpense(expense.id);
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
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: AppDimens.brSm,
              ),
              child: Icon(UiCatalog.expenseIcon(expense.category), color: color, size: 22),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Fmt.date(expense.date, locale: locale),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: glass.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimens.sm),
            Text(
              Fmt.money(expense.amount, currency: l.t('currency'), locale: locale),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
