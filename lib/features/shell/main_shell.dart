import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../localization/app_localizations.dart';
import '../../widgets/glass/frosted_background.dart';
import '../../widgets/glass/glass_bottom_nav.dart';

/// Hosts the five primary tabs inside a frosted background with a floating
/// glass bottom navigation bar.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final items = [
      GlassNavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: l.t('nav_home')),
      GlassNavItem(icon: Icons.build_outlined, activeIcon: Icons.build_rounded, label: l.t('nav_maintenance')),
      GlassNavItem(
          icon: Icons.local_gas_station_outlined,
          activeIcon: Icons.local_gas_station_rounded,
          label: l.t('nav_fuel')),
      GlassNavItem(
          icon: Icons.account_balance_wallet_outlined,
          activeIcon: Icons.account_balance_wallet_rounded,
          label: l.t('nav_expenses')),
      GlassNavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: l.t('nav_more')),
    ];

    return FrostedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: GlassBottomNav(
          items: items,
          currentIndex: navigationShell.currentIndex,
          onTap: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
        ),
      ),
    );
  }
}
