import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../localization/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';
import '../../widgets/glass/glass_container.dart';

/// Branded header used at the top of every auth screen.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.titleKey, required this.subtitleKey});
  final String titleKey;
  final String subtitleKey;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final glass = Theme.of(context).extension<GlassTokens>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: AppDimens.brMd),
          child: const Icon(Icons.directions_car_filled_rounded, color: Colors.white, size: 34),
        ),
        const SizedBox(height: AppDimens.lg),
        Text(l.t(titleKey), style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: AppDimens.xs),
        Text(l.t(subtitleKey),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: glass.textMuted)),
      ],
    );
  }
}

/// "or continue with" + Google / Apple buttons.
class SocialAuthSection extends ConsumerWidget {
  const SocialAuthSection({super.key});

  Future<void> _social(BuildContext context, WidgetRef ref, Future<bool> Function() action) async {
    final ok = await action();
    if (!context.mounted) return;
    if (ok) {
      context.go(AppRoutes.home);
    } else {
      final key = ref.read(authControllerProvider).errorKey ?? 'auth_failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr(key))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final notifier = ref.read(authControllerProvider.notifier);
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: glass.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.md),
              child: Text(l.t('or_continue_with'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: glass.textMuted)),
            ),
            Expanded(child: Divider(color: glass.border)),
          ],
        ),
        const SizedBox(height: AppDimens.lg),
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                icon: Icons.g_mobiledata_rounded,
                label: 'Google',
                onTap: () => _social(context, ref, notifier.signInWithGoogle),
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: _SocialButton(
                icon: Icons.apple_rounded,
                label: 'Apple',
                onTap: () => _social(context, ref, notifier.signInWithApple),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        strong: true,
        height: 54,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26),
            const SizedBox(width: AppDimens.sm),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}

/// Form validators that return localized messages.
class AuthValidators {
  AuthValidators._();

  static String? email(String? v, AppLocalizations l) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return l.t('required_field');
    final re = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    return re.hasMatch(value) ? null : l.t('invalid_email');
  }

  static String? password(String? v, AppLocalizations l) {
    if ((v ?? '').isEmpty) return l.t('required_field');
    return (v!.length >= 6) ? null : l.t('weak_password');
  }

  static String? required(String? v, AppLocalizations l) =>
      (v ?? '').trim().isEmpty ? l.t('required_field') : null;
}
