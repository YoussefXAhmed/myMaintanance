import 'dart:ui';
import 'package:flutter/material.dart';

import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';

/// Presents [child] in a frosted bottom sheet with a grab handle. Scrolls and
/// respects the keyboard inset.
Future<T?> showGlassSheet<T>(
  BuildContext context, {
  required Widget child,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (context) => _GlassSheet(child: child),
  );
}

class _GlassSheet extends StatelessWidget {
  const _GlassSheet({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: AppDimens.rXl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: AppDimens.blurStrong, sigmaY: AppDimens.blurStrong),
          child: Container(
            decoration: BoxDecoration(
              color: glass.fillStrong,
              borderRadius: const BorderRadius.vertical(top: AppDimens.rXl),
              border: Border(top: BorderSide(color: glass.border)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: AppDimens.md),
                    height: 5,
                    width: 44,
                    decoration: BoxDecoration(color: glass.border, borderRadius: BorderRadius.circular(8)),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(AppDimens.xl, 0, AppDimens.xl, AppDimens.xl),
                      child: child,
                    ),
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

/// Confirmation dialog styled as glass.
Future<bool> showGlassConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
}) async {
  final result = await showGlassSheet<bool>(
    context,
    child: _ConfirmBody(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
    ),
  );
  return result ?? false;
}

class _ConfirmBody extends StatelessWidget {
  const _ConfirmBody({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
  });
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTokens>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: AppDimens.sm),
        Text(message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: glass.textMuted)),
        const SizedBox(height: AppDimens.xl),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelLabel),
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: destructive ? const Color(0xFFF87171) : null,
                  padding: const EdgeInsets.symmetric(vertical: AppDimens.lg),
                  shape: const RoundedRectangleBorder(borderRadius: AppDimens.brMd),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmLabel),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
