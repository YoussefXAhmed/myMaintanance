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
import '../../widgets/common/glass_text_field.dart';
import '../../widgets/glass/frosted_background.dart';
import '../../widgets/glass/glass_app_bar.dart';
import '../../widgets/glass/glass_button.dart';
import '../../widgets/glass/glass_container.dart';
import 'auth_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await ref.read(authControllerProvider.notifier).signUp(_name.text, _email.text, _password.text);
    if (!mounted) return;
    if (ok) {
      context.go(AppRoutes.verifyEmail);
    } else {
      final key = ref.read(authControllerProvider).errorKey ?? 'auth_failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr(key))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final loading = ref.watch(authControllerProvider).loading;

    return FrostedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const GlassAppBar(title: '', showBack: true),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeader(titleKey: 'create_account_title', subtitleKey: 'register_subtitle'),
                const SizedBox(height: AppDimens.xxl),
                GlassContainer(
                  blur: AppDimens.blurStrong,
                  padding: const EdgeInsets.all(AppDimens.xl),
                  child: Column(
                    children: [
                      GlassTextField(
                        controller: _name,
                        label: l.t('full_name'),
                        prefixIcon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                        validator: (v) => AuthValidators.required(v, l),
                      ),
                      const SizedBox(height: AppDimens.lg),
                      GlassTextField(
                        controller: _email,
                        label: l.t('email'),
                        prefixIcon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) => AuthValidators.email(v, l),
                      ),
                      const SizedBox(height: AppDimens.lg),
                      GlassTextField(
                        controller: _password,
                        label: l.t('password'),
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.next,
                        validator: (v) => AuthValidators.password(v, l),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              size: 20, color: glass.textMuted),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      const SizedBox(height: AppDimens.lg),
                      GlassTextField(
                        controller: _confirm,
                        label: l.t('confirm_password'),
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        validator: (v) => v != _password.text ? l.t('password_mismatch') : null,
                      ),
                      const SizedBox(height: AppDimens.xl),
                      GlassButton(label: l.t('register'), loading: loading, onPressed: _submit),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).moveY(begin: 18, end: 0),
                const SizedBox(height: AppDimens.xl),
                const SocialAuthSection(),
                const SizedBox(height: AppDimens.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l.t('have_account'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: glass.textMuted)),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(l.t('login'),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
