import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/router/app_router.dart';
import '../../core/ui_catalog.dart';
import '../../localization/app_localizations.dart';
import '../../models/enums.dart';
import '../../models/vehicle.dart';
import '../../models/vehicle_document.dart';
import '../../providers/data_controller.dart';
import '../../providers/data_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/glass_sheet.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/glass/glass_app_bar.dart';
import '../../widgets/glass/glass_container.dart';
import '../../widgets/glass/glass_scaffold.dart';
import '../../widgets/states/empty_state.dart';
import 'add_document_sheet.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final vehicle = ref.watch(selectedVehicleProvider);

    return GlassScaffold(
      appBar: GlassAppBar(
        title: l.t('documents'),
        showBack: true,
        actions: [
          CircleGlassButton(
            icon: Icons.add_rounded,
            onTap: () => showAddDocumentSheet(context, ref),
          ),
        ],
      ),
      body: vehicle == null
          ? EmptyState(
              icon: Icons.directions_car_filled_rounded,
              title: l.t('no_vehicle_title'),
              message: l.t('no_vehicle_body'),
              actionLabel: l.t('add_vehicle'),
              onAction: () => context.push(AppRoutes.addVehicle),
            )
          : _DocumentsBody(vehicle: vehicle),
    );
  }
}

class _DocumentsBody extends ConsumerWidget {
  const _DocumentsBody({required this.vehicle});
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final locale = ref.watch(settingsProvider).locale.languageCode;
    final docs = ref.watch(documentListProvider);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          // Push content below the floating app bar.
          const SliverToBoxAdapter(child: SizedBox(height: 84)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppDimens.lg, 0, AppDimens.lg, AppDimens.xxl),
            sliver: SliverList.list(
              children: [
                // ---- Insurance & License status cards ----
                SectionHeader(title: l.t('insurance_license')),
                Row(
                  children: [
                    Expanded(
                      child: _StatusCard(
                        label: l.t('insurance_expiry'),
                        date: vehicle.insuranceExpiry,
                        locale: locale,
                      ),
                    ),
                    const SizedBox(width: AppDimens.md),
                    Expanded(
                      child: _StatusCard(
                        label: l.t('license_expiry'),
                        date: vehicle.licenseExpiry,
                        locale: locale,
                      ),
                    ),
                    const SizedBox(width: AppDimens.md),
                    Expanded(
                      child: _StatusCard(
                        label: l.t('inspection_date'),
                        date: vehicle.inspectionDate,
                        locale: locale,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 350.ms).moveY(begin: 14, end: 0),
                const SizedBox(height: AppDimens.lg),

                // ---- Documents list ----
                SectionHeader(title: l.t('documents')),
                if (docs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppDimens.xl),
                    child: EmptyState(
                      icon: Icons.folder_copy_rounded,
                      title: l.t('no_docs_title'),
                      message: l.t('no_docs_body'),
                      actionLabel: l.t('add_document'),
                      onAction: () => showAddDocumentSheet(context, ref),
                    ),
                  )
                else
                  for (var i = 0; i < docs.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppDimens.md),
                      child: _DocumentRow(doc: docs[i])
                          .animate()
                          .fadeIn(delay: (40 * i).ms, duration: 320.ms)
                          .moveY(begin: 14, end: 0),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Returns (color, isSet) for an expiry-style date relative to now.
({Color color, String text}) _expiryStatus(DateTime? date, String locale) {
  if (date == null) return (color: AppColors.success, text: '—');
  final now = DateTime.now();
  final Color color;
  if (date.isBefore(now)) {
    color = AppColors.danger;
  } else if (date.difference(now).inDays <= 30) {
    color = AppColors.warning;
  } else {
    color = AppColors.success;
  }
  return (color: color, text: Fmt.relativeDays(date, locale: locale));
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.label, required this.date, required this.locale});
  final String label;
  final DateTime? date;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final status = _expiryStatus(date, locale);

    return GlassContainer(
      padding: const EdgeInsets.all(AppDimens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: glass.textMuted),
          ),
          const SizedBox(height: AppDimens.sm),
          Text(
            date == null ? '—' : Fmt.date(date!, locale: locale),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppDimens.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: status.color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentRow extends ConsumerWidget {
  const _DocumentRow({required this.doc});
  final VehicleDocument doc;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final ok = await showGlassConfirm(
      context,
      title: l.t('delete'),
      message: l.isArabic ? 'حذف هذا المستند؟' : 'Delete this document?',
      confirmLabel: l.t('delete'),
      cancelLabel: l.t('cancel'),
      destructive: true,
    );
    if (ok) {
      await ref.read(dataControllerProvider).deleteDocument(doc.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final locale = ref.watch(settingsProvider).locale.languageCode;

    final title = doc.title.isNotEmpty ? doc.title : l.t(doc.type.labelKey);
    final typeLabel = l.t(doc.type.labelKey);
    final subtitle = doc.expiryDate != null
        ? '$typeLabel • ${Fmt.date(doc.expiryDate!, locale: locale)}'
        : typeLabel;

    final expiry = doc.expiryDate;
    Color? pillColor;
    if (expiry != null) {
      if (doc.isExpired) {
        pillColor = AppColors.danger;
      } else if (expiry.difference(DateTime.now()).inDays <= 30) {
        pillColor = AppColors.warning;
      }
    }

    return GestureDetector(
      onLongPress: () => _confirmDelete(context, ref),
      child: GlassContainer(
        padding: const EdgeInsets.all(AppDimens.md),
        child: Row(
          children: [
            _Leading(doc: doc),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: glass.textMuted),
                  ),
                ],
              ),
            ),
            if (pillColor != null) ...[
              const SizedBox(width: AppDimens.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: pillColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  Fmt.relativeDays(expiry!, locale: locale),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: pillColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Leading visual: a document thumbnail when an image is attached, otherwise a
/// tinted circle with the document-type icon.
class _Leading extends StatelessWidget {
  const _Leading({required this.doc});
  final VehicleDocument doc;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.primary;
    final fallback = _iconCircle(color);

    if (doc.localPath != null && doc.localPath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: AppDimens.brSm,
        child: Image.file(
          File(doc.localPath!),
          height: 44,
          width: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      );
    }
    if (doc.fileUrl != null && doc.fileUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: AppDimens.brSm,
        child: Image.network(
          doc.fileUrl!,
          height: 44,
          width: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      );
    }
    return fallback;
  }

  Widget _iconCircle(Color color) {
    return Container(
      height: 44,
      width: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: AppDimens.brSm,
      ),
      child: Icon(UiCatalog.documentIcon(doc.type), color: color, size: 22),
    );
  }
}
