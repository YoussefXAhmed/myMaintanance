import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../localization/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/glass_sheet.dart';
import '../../widgets/glass/glass_app_bar.dart';
import '../../widgets/glass/glass_button.dart';
import '../../widgets/glass/glass_container.dart';
import '../../widgets/glass/glass_scaffold.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final user = ref.watch(authControllerProvider).user;
    final vehiclesCount = ref.watch(vehiclesProvider).vehicles.length;

    final tiles = <_ProfileTile>[
      _ProfileTile(Icons.language_rounded, l.t('language')),
      _ProfileTile(Icons.palette_rounded, l.t('theme')),
      _ProfileTile(Icons.notifications_rounded, l.t('notification_settings')),
      _ProfileTile(Icons.settings_rounded, l.t('settings')),
    ];

    return GlassScaffold(
      appBar: GlassAppBar(title: l.t('profile'), showBack: true),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.md, AppDimens.lg, AppDimens.xxl),
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(AppDimens.xl),
              child: Column(
                children: [
                  Container(
                    height: 88,
                    width: 88,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    ),
                    child: Text(
                      user?.initials ?? '?',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: AppDimens.md),
                  Text(
                    user?.displayName ?? l.t('app_name'),
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  if (user?.email.isNotEmpty ?? false) ...[
                    const SizedBox(height: AppDimens.xs),
                    Text(
                      user!.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: glass.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: AppDimens.md),
                  _VerifiedBadge(verified: user?.emailVerified ?? false),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms).moveY(begin: 14, end: 0),
            const SizedBox(height: AppDimens.lg),
            GlassContainer(
              padding: const EdgeInsets.symmetric(vertical: AppDimens.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car_filled_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: AppDimens.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$vehiclesCount', style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        l.t('vehicles_count'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: glass.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 80.ms, duration: 350.ms).moveY(begin: 14, end: 0),
            const SizedBox(height: AppDimens.lg),
            for (var i = 0; i < tiles.length; i++) ...[
              GlassContainer(
                padding: EdgeInsets.zero,
                child: ListTile(
                  shape: const RoundedRectangleBorder(borderRadius: AppDimens.brLg),
                  leading: Icon(tiles[i].icon, color: AppColors.primary),
                  title: Text(tiles[i].label, style: Theme.of(context).textTheme.titleSmall),
                  trailing: Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    color: glass.textMuted,
                  ),
                  onTap: () => context.push(AppRoutes.settings),
                ),
              )
                  .animate()
                  .fadeIn(delay: (120 + i * 50).ms, duration: 300.ms)
                  .moveY(begin: 12, end: 0),
              const SizedBox(height: AppDimens.md),
            ],
            const SizedBox(height: AppDimens.md),
            GlassButton(
              variant: GlassButtonVariant.glass,
              label: l.t('logout'),
              icon: Icons.logout_rounded,
              onPressed: () async {
                final confirmed = await showGlassConfirm(
                  context,
                  title: l.t('logout'),
                  message: l.t('logout_confirm'),
                  confirmLabel: l.t('logout'),
                  cancelLabel: l.t('cancel'),
                  destructive: true,
                );
                if (!confirmed) return;
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) context.go(AppRoutes.login);
              },
            ).animate().fadeIn(delay: 320.ms, duration: 300.ms),
          ],
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge({required this.verified});
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final color = verified ? AppColors.success : glass.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(verified ? Icons.verified_rounded : Icons.error_outline_rounded, size: 18, color: color),
        const SizedBox(width: AppDimens.xs),
        Text(
          verified
              ? (l.isArabic ? 'بريد موثّق' : 'Verified')
              : (l.isArabic ? 'غير موثّق' : 'Unverified'),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ProfileTile {
  const _ProfileTile(this.icon, this.label);
  final IconData icon;
  final String label;
}
