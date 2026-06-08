import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/router/app_router.dart';
import '../../localization/app_localizations.dart';
import '../../models/enums.dart';
import '../../providers/data_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/ai_advisor_service.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/glass/glass_app_bar.dart';
import '../../widgets/glass/glass_button.dart';
import '../../widgets/glass/glass_container.dart';
import '../../widgets/glass/glass_scaffold.dart';
import '../../widgets/indicators/circular_health_indicator.dart';
import '../../widgets/states/empty_state.dart';
import 'advisor_presentation.dart';

/// AI Maintenance Advisor — a pushed screen surfacing the deterministic,
/// on-device recommendations from [advisorProvider] (backed by
/// [RuleBasedAdvisor]). The architecture is OpenAI-ready: an [OpenAiAdvisor]
/// already exists in `services/ai_advisor_service.dart` behind the same
/// [AiAdvisor] contract, so a cloud advisor can drop in with no UI changes.
class AdvisorScreen extends ConsumerWidget {
  const AdvisorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final vehicle = ref.watch(selectedVehicleProvider);

    return GlassScaffold(
      appBar: GlassAppBar(
        title: l.t('advisor_title'),
        subtitle: l.t('advisor_subtitle'),
        showBack: true,
      ),
      body: vehicle == null
          ? EmptyState(
              icon: Icons.auto_awesome_rounded,
              title: l.t('ai_advisor'),
              message: l.t('advisor_no_data'),
              actionLabel: l.t('add_vehicle'),
              onAction: () => context.push(AppRoutes.addVehicle),
            )
          : const _AdvisorBody(),
    );
  }
}

class _AdvisorBody extends ConsumerWidget {
  const _AdvisorBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final locale = ref.watch(settingsProvider).locale.languageCode;
    final health = ref.watch(vehicleHealthProvider);
    final recs = ref.watch(advisorProvider);
    final top = recs.isNotEmpty ? recs.first : null;
    final onlyAllGood = recs.length == 1 && recs.first.kind == AdvisorKind.allGood;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppDimens.lg,
        MediaQuery.of(context).padding.top + 88,
        AppDimens.lg,
        AppDimens.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeroCard(
            health: health,
            sentence: top == null
                ? (l.isArabic
                    ? 'كل شيء ممتاز، لا حاجة لأي إجراء.'
                    : 'Everything looks great. No action needed.')
                : _topSentence(top, l, locale),
          ).animate().fadeIn(duration: AppMotion.medium).moveY(begin: 14, end: 0),
          const SizedBox(height: AppDimens.lg),
          const _AnalyzeButton(),
          const SizedBox(height: AppDimens.sm),
          SectionHeader(title: l.t('recommendation'), icon: Icons.tips_and_updates_rounded),
          if (onlyAllGood)
            _AllGoodCard()
                .animate()
                .fadeIn(duration: AppMotion.medium)
                .moveY(begin: 14, end: 0)
          else
            for (var i = 0; i < recs.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.sm),
                child: _RecommendationCard(view: AdvisorView.from(recs[i], l))
                    .animate()
                    .fadeIn(duration: AppMotion.medium, delay: (60 * i).ms)
                    .moveY(begin: 14, end: 0),
              ),
        ],
      ),
    );
  }

  /// Builds a human, localized headline sentence from the highest-priority
  /// recommendation, in either Arabic or English.
  String _topSentence(AdvisorRecommendation rec, AppLocalizations l, String locale) {
    final ar = l.isArabic;
    final km = Fmt.number((rec.kmRemaining ?? 0).abs(), locale: locale);
    final days = (rec.daysRemaining ?? 0).abs().toString();

    switch (rec.kind) {
      case AdvisorKind.overdue:
        final typeName = l.t(rec.type!.labelKey);
        return ar
            ? 'غيّر $typeName الآن — متأخرة بمقدار $km كم.'
            : 'Change $typeName now — overdue by $km km.';
      case AdvisorKind.dueSoon:
        final typeName = l.t(rec.type!.labelKey);
        return ar
            ? 'غيّر $typeName خلال $km كم.'
            : 'Change $typeName within $km km.';
      case AdvisorKind.insurance:
        final label = l.t('insurance_expiry');
        return ar ? '$label ينتهي خلال $days يوم' : '$label expires in $days days';
      case AdvisorKind.license:
        final label = l.t('license_expiry');
        return ar ? '$label ينتهي خلال $days يوم' : '$label expires in $days days';
      case AdvisorKind.inspection:
        final label = l.t('inspection_date');
        return ar ? '$label ينتهي خلال $days يوم' : '$label expires in $days days';
      case AdvisorKind.mileageTrend:
      case AdvisorKind.allGood:
        return ar
            ? 'كل شيء ممتاز، لا حاجة لأي إجراء.'
            : 'Everything looks great. No action needed.';
    }
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.health, required this.sentence});

  final VehicleHealth health;
  final String sentence;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final glass = Theme.of(context).extension<GlassTokens>()!;

    return GlassContainer(
      blur: AppDimens.blurStrong,
      strong: true,
      borderRadius: AppDimens.brXl,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primary.withValues(alpha: 0.16),
          AppColors.secondary.withValues(alpha: 0.10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.brandGradient,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: Text(l.t('ai_advisor'), style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircularHealthIndicator(
                value: health.overall,
                size: 120,
                strokeWidth: 12,
                label: l.t('vehicle_health'),
              ),
              const SizedBox(width: AppDimens.lg),
              Expanded(
                child: Text(
                  sentence,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: glass.textPrimary,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Analyze" CTA. The advisor is fully reactive (no network), so a tap simply
/// shows a brief loading spinner then confirms with a SnackBar.
class _AnalyzeButton extends StatefulWidget {
  const _AnalyzeButton();

  @override
  State<_AnalyzeButton> createState() => _AnalyzeButtonState();
}

class _AnalyzeButtonState extends State<_AnalyzeButton> {
  bool _loading = false;

  Future<void> _analyze() async {
    final l = context.l10n;
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.t('synced'))));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return GlassButton(
      label: l.t('analyze'),
      icon: Icons.auto_awesome_rounded,
      loading: _loading,
      onPressed: _analyze,
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.view});
  final AdvisorView view;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTokens>()!;
    return GlassContainer(
      padding: const EdgeInsets.all(AppDimens.md),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: view.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(view.icon, color: view.color, size: 24),
          ),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(view.title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  view.body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: glass.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: view.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              view.priorityLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: view.color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Friendly "everything is in order" card shown when the advisor returns only
/// the [AdvisorKind.allGood] item.
class _AllGoodCard extends StatelessWidget {
  const _AllGoodCard();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final glass = Theme.of(context).extension<GlassTokens>()!;
    return GlassContainer(
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 24),
          ),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.t('up_to_date'), style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  l.t('no_reminders'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: glass.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
