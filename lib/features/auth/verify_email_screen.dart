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
import '../../widgets/glass/frosted_background.dart';
import '../../widgets/glass/glass_button.dart';
import '../../widgets/glass/glass_container.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _checking = false;

  Future<void> _check() async {
    setState(() => _checking = true);
    final verified = await ref.read(authControllerProvider.notifier).refreshVerification();
    if (!mounted) return;
    setState(() => _checking = false);
    context.go(AppRoutes.home);
    if (!verified) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('synced'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final email = ref.watch(authControllerProvider).user?.email ?? '';

    return FrostedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 110,
                  width: 110,
                  decoration: BoxDecoration(
                    gradient: AppColors.mintGradient,
                    borderRadius: BorderRadius.circular(34),
                    boxShadow: [
                      BoxShadow(color: AppColors.tertiary.withValues(alpha: 0.4), blurRadius: 36, spreadRadius: -6),
                    ],
                  ),
                  child: const Icon(Icons.mark_email_read_rounded, size: 56, color: Colors.white),
                ).animate().scale(curve: Curves.easeOutBack, duration: 600.ms),
                const SizedBox(height: AppDimens.xxl),
                Text(l.t('verify_email_title'),
                    textAlign: TextAlign.center, style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: AppDimens.md),
                Text(
                  l.t('verify_email_body', params: {'email': email}),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: glass.textMuted),
                ),
                const SizedBox(height: AppDimens.xxl),
                GlassButton(label: l.t('i_verified'), loading: _checking, onPressed: _check),
                const SizedBox(height: AppDimens.md),
                GlassContainer(
                  shadow: false,
                  child: TextButton(
                    onPressed: () => ref.read(authControllerProvider.notifier).resendVerification(),
                    child: Text(l.t('resend_email'),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.primary)),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: Text(l.t('skip'),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: glass.textMuted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
