import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../localization/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/glass_text_field.dart';
import '../../widgets/glass/frosted_background.dart';
import '../../widgets/glass/glass_app_bar.dart';
import '../../widgets/glass/glass_button.dart';
import '../../widgets/glass/glass_container.dart';
import 'auth_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    await ref.read(authControllerProvider.notifier).sendPasswordReset(_email.text);
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('reset_sent'))));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final glass = Theme.of(context).extension<GlassTokens>()!;
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
                Text(l.t('forgot_password_title'), style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: AppDimens.sm),
                Text(l.t('forgot_password_body'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: glass.textMuted)),
                const SizedBox(height: AppDimens.xxl),
                GlassContainer(
                  blur: AppDimens.blurStrong,
                  padding: const EdgeInsets.all(AppDimens.xl),
                  child: Column(
                    children: [
                      GlassTextField(
                        controller: _email,
                        label: l.t('email'),
                        prefixIcon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => AuthValidators.email(v, l),
                      ),
                      const SizedBox(height: AppDimens.xl),
                      GlassButton(label: l.t('send_reset_link'), loading: _sending, onPressed: _submit),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
