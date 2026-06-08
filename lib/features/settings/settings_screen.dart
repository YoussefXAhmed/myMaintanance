import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_config.dart';
import '../../core/router/app_router.dart';
import '../../localization/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_controller.dart';
import '../../providers/settings_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/glass_sheet.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/glass/glass_app_bar.dart';
import '../../widgets/glass/glass_container.dart';
import '../../widgets/glass/glass_scaffold.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final settings = ref.watch(settingsProvider);
    final settingsCtrl = ref.read(settingsProvider.notifier);
    final dataCtrl = ref.read(dataControllerProvider);

    return GlassScaffold(
      appBar: GlassAppBar(title: l.t('settings'), showBack: true),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.md, AppDimens.lg, AppDimens.xxl),
          children: [
            // ---- Appearance --------------------------------------------------
            _Section(
              index: 0,
              title: l.t('appearance'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.t('theme'), style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppDimens.md),
                  Wrap(
                    spacing: AppDimens.sm,
                    runSpacing: AppDimens.sm,
                    children: [
                      _GlassChip(
                        label: l.t('light_mode'),
                        icon: Icons.light_mode_rounded,
                        selected: settings.themeMode == ThemeMode.light,
                        onTap: () => settingsCtrl.setThemeMode(ThemeMode.light),
                      ),
                      _GlassChip(
                        label: l.t('dark_mode'),
                        icon: Icons.dark_mode_rounded,
                        selected: settings.themeMode == ThemeMode.dark,
                        onTap: () => settingsCtrl.setThemeMode(ThemeMode.dark),
                      ),
                      _GlassChip(
                        label: l.t('system_mode'),
                        icon: Icons.brightness_auto_rounded,
                        selected: settings.themeMode == ThemeMode.system,
                        onTap: () => settingsCtrl.setThemeMode(ThemeMode.system),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.lg),
                  Text(l.t('language'), style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppDimens.md),
                  Wrap(
                    spacing: AppDimens.sm,
                    runSpacing: AppDimens.sm,
                    children: [
                      _GlassChip(
                        label: l.t('english'),
                        selected: !settings.isArabic,
                        onTap: () => settingsCtrl.setLocale(const Locale('en')),
                      ),
                      _GlassChip(
                        label: l.t('arabic'),
                        selected: settings.isArabic,
                        onTap: () => settingsCtrl.setLocale(const Locale('ar')),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ---- Notifications -----------------------------------------------
            _Section(
              index: 1,
              title: l.t('notifications'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(l.t('enable_notifications'), style: Theme.of(context).textTheme.titleSmall),
                      ),
                      Switch(
                        value: settings.notificationsEnabled,
                        onChanged: (v) async {
                          await settingsCtrl.setNotificationsEnabled(v);
                          await dataCtrl.rescheduleReminders();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.md),
                  Text(l.t('reminder_timing'), style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppDimens.md),
                  Wrap(
                    spacing: AppDimens.sm,
                    runSpacing: AppDimens.sm,
                    children: [
                      for (final n in const [1, 3, 7, 14])
                        _GlassChip(
                          label: l.t('days_before', params: {'n': n}),
                          selected: settings.reminderDays == n,
                          onTap: () async {
                            await settingsCtrl.setReminderDays(n);
                            await dataCtrl.rescheduleReminders();
                          },
                        ),
                    ],
                  ),
                  if (settings.notificationsEnabled) ...[
                    const SizedBox(height: AppDimens.lg),
                    for (final entry in const [
                      ('oil', 'reminder_oil'),
                      ('maintenance', 'reminder_maintenance'),
                      ('insurance', 'reminder_insurance'),
                      ('license', 'reminder_license'),
                      ('battery', 'reminder_battery'),
                      ('tires', 'reminder_tires'),
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppDimens.xs),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(l.t(entry.$2), style: Theme.of(context).textTheme.bodyLarge),
                            ),
                            Switch(
                              value: settings.reminderToggles[entry.$1] ?? true,
                              onChanged: (v) => settingsCtrl.setReminderToggle(entry.$1, v),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),

            // ---- Data --------------------------------------------------------
            _Section(
              index: 2,
              title: l.t('data'),
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _DataTile(
                    icon: Icons.upload_file_rounded,
                    label: l.t('data_export'),
                    onTap: () => _snack(context, l.t('synced')),
                  ),
                  _Divider(color: glass.border),
                  _DataTile(
                    icon: Icons.backup_rounded,
                    label: l.t('backup'),
                    onTap: () => _snack(context, l.t('synced')),
                  ),
                  _Divider(color: glass.border),
                  _DataTile(
                    icon: Icons.settings_backup_restore_rounded,
                    label: l.t('restore'),
                    onTap: () => _snack(context, l.t('synced')),
                  ),
                  _Divider(color: glass.border),
                  _DataTile(
                    icon: Icons.delete_forever_rounded,
                    label: l.t('delete_account'),
                    color: AppColors.danger,
                    onTap: () async {
                      final confirmed = await showGlassConfirm(
                        context,
                        title: l.t('delete_account'),
                        message: l.t('delete_account_confirm'),
                        confirmLabel: l.t('delete'),
                        cancelLabel: l.t('cancel'),
                        destructive: true,
                      );
                      if (!confirmed) return;
                      await ref.read(authControllerProvider.notifier).deleteAccount();
                      if (context.mounted) context.go(AppRoutes.login);
                    },
                  ),
                ],
              ),
            ),

            // ---- About -------------------------------------------------------
            _Section(
              index: 3,
              title: l.t('about'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.directions_car_filled_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: AppDimens.md),
                      Expanded(
                        child: Text(AppConfig.appName, style: Theme.of(context).textTheme.titleSmall),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.t('version'),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: glass.textMuted),
                        ),
                      ),
                      Text(AppConfig.version, style: Theme.of(context).textTheme.bodyMedium),
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

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.index,
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimens.lg),
  });

  final int index;
  final String title;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: title),
        GlassContainer(padding: padding, child: child),
        const SizedBox(height: AppDimens.lg),
      ],
    ).animate().fadeIn(delay: (index * 80).ms, duration: 350.ms).moveY(begin: 14, end: 0);
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final fg = selected ? Colors.white : glass.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.md, vertical: AppDimens.sm),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.brandGradient : null,
          color: selected ? null : glass.fill,
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          border: Border.all(color: selected ? Colors.transparent : glass.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: AppDimens.xs),
            ],
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: fg, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataTile extends StatelessWidget {
  const _DataTile({required this.icon, required this.label, required this.onTap, this.color});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final tint = color ?? AppColors.primary;
    return ListTile(
      leading: Icon(icon, color: tint),
      title: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
      ),
      trailing: Icon(
        Directionality.of(context) == TextDirection.rtl
            ? Icons.chevron_left_rounded
            : Icons.chevron_right_rounded,
        color: glass.textMuted,
      ),
      onTap: onTap,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, indent: AppDimens.lg, endIndent: AppDimens.lg, color: color);
  }
}
