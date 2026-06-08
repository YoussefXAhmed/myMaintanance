import 'package:flutter/material.dart';

import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';
import 'glass_container.dart';

/// A floating, frosted app bar with an optional subtitle and trailing actions.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.showBack = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTokens>()!;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.sm, AppDimens.lg, 0),
        child: Row(
          children: [
            if (showBack)
              _CircleGlassButton(
                icon: Directionality.of(context) == TextDirection.rtl
                    ? Icons.arrow_forward_rounded
                    : Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            if (leading != null) leading!,
            if (showBack || leading != null) const SizedBox(width: AppDimens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge, overflow: TextOverflow.ellipsis),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: glass.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (actions != null) ...actions!,
          ],
        ),
      ),
    );
  }
}

class _CircleGlassButton extends StatelessWidget {
  const _CircleGlassButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(10),
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        shadow: false,
        child: Icon(icon, size: 22),
      ),
    );
  }
}

/// Reusable circular glass icon button (used by app bars and headers).
class CircleGlassButton extends StatelessWidget {
  const CircleGlassButton({super.key, required this.icon, required this.onTap, this.badge = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(10),
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            shadow: false,
            child: Icon(icon, size: 22),
          ),
          if (badge)
            const Positioned(
              right: 6,
              top: 6,
              child: CircleAvatar(radius: 4, backgroundColor: Color(0xFFF87171)),
            ),
        ],
      ),
    );
  }
}
