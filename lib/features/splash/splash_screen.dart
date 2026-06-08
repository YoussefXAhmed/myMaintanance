import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_config.dart';
import '../../core/router/app_router.dart';
import '../../localization/app_localizations.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_dimens.dart';
import '../../widgets/glass/frosted_background.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(AppConfig.splashMinDuration, () {
      if (mounted) context.go(AppRoutes.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return FrostedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 108,
                width: 108,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: AppDimens.brXl,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 40,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: const Icon(Icons.directions_car_filled_rounded, color: Colors.white, size: 56),
              )
                  .animate()
                  .scale(begin: const Offset(0.6, 0.6), end: const Offset(1, 1), duration: 700.ms, curve: Curves.easeOutBack)
                  .fadeIn(duration: 500.ms),
              const SizedBox(height: AppDimens.xl),
              Text(l.t('app_name'), style: Theme.of(context).textTheme.displaySmall)
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 600.ms)
                  .moveY(begin: 12, end: 0),
              const SizedBox(height: AppDimens.xs),
              Text(
                l.t('app_tagline'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.darkTextMuted),
              ).animate().fadeIn(delay: 500.ms, duration: 600.ms),
              const SizedBox(height: AppDimens.xxxl),
              const SizedBox(
                height: 26,
                width: 26,
                child: CircularProgressIndicator(strokeWidth: 2.6, color: AppColors.primary),
              ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}
