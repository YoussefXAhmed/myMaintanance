import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../localization/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/local_store.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/glass_text_field.dart';
import '../../widgets/glass/frosted_background.dart';
import '../../widgets/glass/glass_button.dart';
import '../../widgets/glass/glass_container.dart';
import 'auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _remember = true;

  @override
  void initState() {
    super.initState();
    _email.text = LocalStore.instance.setting<String>('remember_email') ?? '';
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await ref.read(authControllerProvider.notifier).signIn(_email.text, _password.text);
    if (!mounted) return;
    if (ok) {
      await LocalStore.instance.setSetting('remember_email', _remember ? _email.text.trim() : '');
      if (mounted) context.go(AppRoutes.home);
    } else {
      _showError();
    }
  }

  void _showError() {
    final key = ref.read(authControllerProvider).errorKey ?? 'auth_failed';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr(key))));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final loading = ref.watch(authControllerProvider).loading;

    return FrostedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.xl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppDimens.xl),
                  const AuthHeader(titleKey: 'welcome_back', subtitleKey: 'login_subtitle'),
                  const SizedBox(height: AppDimens.xxl),
                  GlassContainer(
                    blur: AppDimens.blurStrong,
                    padding: const EdgeInsets.all(AppDimens.xl),
                    child: Column(
                      children: [
                        GlassTextField(
                          controller: _email,
                          label: l.t('email'),
                          hint: 'name@email.com',
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) => AuthValidators.email(v, l),
                        ),
                        const SizedBox(height: AppDimens.lg),
                        GlassTextField(
                          controller: _password,
                          label: l.t('password'),
                          hint: '••••••••',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          validator: (v) => AuthValidators.password(v, l),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                size: 20, color: glass.textMuted),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        const SizedBox(height: AppDimens.sm),
                        Row(
                          children: [
                            _RememberCheckbox(value: _remember, onChanged: (v) => setState(() => _remember = v)),
                            Text(l.t('remember_me'), style: Theme.of(context).textTheme.bodyMedium),
                            const Spacer(),
                            TextButton(
                              onPressed: () => context.push(AppRoutes.forgotPassword),
                              child: Text(l.t('forgot_password'),
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimens.md),
                        GlassButton(label: l.t('login'), loading: loading, onPressed: _submit),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).moveY(begin: 18, end: 0),
                  const SizedBox(height: AppDimens.xl),
                  const SocialAuthSection(),
                  const SizedBox(height: AppDimens.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l.t('no_account'),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: glass.textMuted)),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.register),
                        child: Text(l.t('sign_up'),
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RememberCheckbox extends StatelessWidget {
  const _RememberCheckbox({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        margin: const EdgeInsetsDirectional.only(end: 8),
        height: 24,
        width: 24,
        decoration: BoxDecoration(
          gradient: value ? AppColors.brandGradient : null,
          color: value ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: value ? Colors.transparent : Theme.of(context).extension<GlassTokens>()!.border),
        ),
        child: value ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
      ),
    );
  }
}
