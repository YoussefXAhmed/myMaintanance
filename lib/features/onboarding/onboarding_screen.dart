import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../localization/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';
import '../../widgets/glass/frosted_background.dart';
import '../../widgets/glass/glass_button.dart';
import '../../widgets/glass/glass_container.dart';

class _Page {
  const _Page(this.icon, this.titleKey, this.bodyKey, this.gradient);
  final IconData icon;
  final String titleKey;
  final String bodyKey;
  final Gradient gradient;
}

const _pages = [
  _Page(Icons.build_circle_rounded, 'ob1_title', 'ob1_body', AppColors.brandGradient),
  _Page(Icons.local_gas_station_rounded, 'ob2_title', 'ob2_body', AppColors.mintGradient),
  _Page(Icons.notifications_active_rounded, 'ob3_title', 'ob3_body', AppColors.sunsetGradient),
  _Page(Icons.favorite_rounded, 'ob4_title', 'ob4_body', AppColors.healthGoodGradient),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(settingsProvider.notifier).completeOnboarding();
    if (!mounted) return;
    final loggedIn = ref.read(authControllerProvider).isAuthenticated;
    context.go(loggedIn ? AppRoutes.home : AppRoutes.login);
  }

  void _next() {
    if (_index == _pages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(duration: AppMotion.medium, curve: AppMotion.emphasized);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isLast = _index == _pages.length - 1;
    return FrostedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.lg),
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(l.t('skip'),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.primary)),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemCount: _pages.length,
                  itemBuilder: (context, i) => _OnboardingPage(page: _pages[i]),
                ),
              ),
              _Dots(count: _pages.length, index: _index),
              Padding(
                padding: const EdgeInsets.all(AppDimens.xl),
                child: GlassButton(
                  label: l.t(isLast ? 'get_started' : 'next'),
                  icon: isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                  onPressed: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.page});
  final _Page page;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassContainer(
            height: 220,
            width: 220,
            borderRadius: BorderRadius.circular(60),
            blur: AppDimens.blurStrong,
            child: Center(
              child: Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(gradient: page.gradient, borderRadius: BorderRadius.circular(36)),
                child: Icon(page.icon, size: 60, color: Colors.white),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: -8, end: 8, duration: 2400.ms, curve: Curves.easeInOut),
            ),
          ).animate().scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack, duration: 600.ms),
          const SizedBox(height: AppDimens.xxxl),
          Text(
            l.t(page.titleKey),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall,
          ).animate().fadeIn(duration: 500.ms).moveY(begin: 16, end: 0),
          const SizedBox(height: AppDimens.md),
          Text(
            l.t(page.bodyKey),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Theme.of(context).extension<GlassTokens>()!.textMuted),
          ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.emphasized,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: active ? 26 : 8,
          decoration: BoxDecoration(
            gradient: active ? AppColors.brandGradient : null,
            color: active ? null : Theme.of(context).extension<GlassTokens>()!.border,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
