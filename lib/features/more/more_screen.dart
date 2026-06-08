import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../localization/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/glass/glass_card.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final user = ref.watch(authControllerProvider).user;

    final entries = <_MoreEntry>[
      _MoreEntry(l.t('my_vehicles'), Icons.directions_car_filled_rounded, AppRoutes.vehicles, AppColors.brandGradient),
      _MoreEntry(l.t('documents'), Icons.folder_copy_rounded, AppRoutes.documents, AppColors.mintGradient),
      _MoreEntry(l.t('analytics'), Icons.bar_chart_rounded, AppRoutes.analytics, AppColors.sunsetGradient),
      _MoreEntry(l.t('ai_advisor'), Icons.auto_awesome_rounded, AppRoutes.advisor,
          const LinearGradient(colors: [AppColors.secondary, AppColors.primary])),
      _MoreEntry(l.t('insurance_license'), Icons.shield_rounded, AppRoutes.documents, AppColors.mintGradient),
      _MoreEntry(l.t('profile'), Icons.person_rounded, AppRoutes.profile, AppColors.brandGradient),
      _MoreEntry(l.t('settings'), Icons.settings_rounded, AppRoutes.settings, AppColors.sunsetGradient),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.lg, AppDimens.lg, 130),
              sliver: SliverList.list(
                children: [
                  GlassCard(
                    onTap: () => context.push(AppRoutes.profile),
                    padding: const EdgeInsets.all(AppDimens.lg),
                    child: Row(
                      children: [
                        Container(
                          height: 56,
                          width: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                          ),
                          child: Text(
                            user?.initials ?? '?',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: AppDimens.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? l.t('app_name'),
                                style: Theme.of(context).textTheme.titleMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (user?.email.isNotEmpty ?? false)
                                Text(
                                  user!.email,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: glass.textMuted),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          Directionality.of(context) == TextDirection.rtl
                              ? Icons.chevron_left_rounded
                              : Icons.chevron_right_rounded,
                          color: glass.textMuted,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 350.ms).moveY(begin: 14, end: 0),
                  const SizedBox(height: AppDimens.lg),
                  SectionHeader(title: l.t('nav_more')),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppDimens.md,
                    crossAxisSpacing: AppDimens.md,
                    childAspectRatio: 1.55,
                    children: [
                      for (var i = 0; i < entries.length; i++)
                        _MoreTile(entry: entries[i])
                            .animate()
                            .fadeIn(delay: (60 + i * 50).ms, duration: 350.ms)
                            .moveY(begin: 14, end: 0),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreEntry {
  const _MoreEntry(this.label, this.icon, this.route, this.gradient);
  final String label;
  final IconData icon;
  final String route;
  final Gradient gradient;
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.entry});
  final _MoreEntry entry;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => context.push(entry.route),
      padding: const EdgeInsets.all(AppDimens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 44,
            width: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(gradient: entry.gradient, borderRadius: BorderRadius.circular(14)),
            child: Icon(entry.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: AppDimens.md),
          Text(
            entry.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}
