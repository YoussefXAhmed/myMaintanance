import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/formatters.dart';
import '../../core/ui_catalog.dart';
import '../../localization/app_localizations.dart';
import '../../models/enums.dart';
import '../../models/vehicle_document.dart';
import '../../providers/data_controller.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/glass_sheet.dart';
import '../../widgets/common/glass_text_field.dart';
import '../../widgets/glass/glass_button.dart';

/// Opens the add-document bottom sheet for the selected vehicle.
Future<void> showAddDocumentSheet(BuildContext context, WidgetRef ref) {
  return showGlassSheet<void>(
    context,
    child: const _AddDocumentForm(),
  );
}

class _AddDocumentForm extends ConsumerStatefulWidget {
  const _AddDocumentForm();

  @override
  ConsumerState<_AddDocumentForm> createState() => _AddDocumentFormState();
}

class _AddDocumentFormState extends ConsumerState<_AddDocumentForm> {
  DocumentType _type = DocumentType.license;
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  DateTime? _expiryDate;
  DateTime? _issueDate;
  String? _localPath;
  bool _saving = false;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 30),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _pickIssue() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _issueDate ?? now,
      firstDate: DateTime(now.year - 30),
      lastDate: now,
    );
    if (picked != null) setState(() => _issueDate = picked);
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (file != null) setState(() => _localPath = file.path);
    } catch (_) {
      // Picker unavailable (e.g. no gallery permission) — silently ignore.
    }
  }

  Future<void> _save() async {
    final vehicle = ref.read(selectedVehicleProvider);
    if (vehicle == null) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      final l = context.l10n;
      setState(() => _titleError = l.isArabic ? 'العنوان مطلوب' : 'Title is required');
      return;
    }

    setState(() => _saving = true);

    final doc = VehicleDocument(
      id: const Uuid().v4(),
      vehicleId: vehicle.id,
      type: _type,
      title: title,
      localPath: _localPath,
      expiryDate: _expiryDate,
      issueDate: _issueDate,
      notes: _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    await ref.read(dataControllerProvider).saveDocument(doc);
    if (!mounted) return;
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (context.mounted) Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text(l.t('saved'))));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final locale = ref.watch(settingsProvider).locale.languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l.t('add_document'),
            style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: AppDimens.lg),

        // Type selector — wrap of selectable glass chips.
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(l.t('documents'),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: glass.textMuted)),
        ),
        Wrap(
          spacing: AppDimens.sm,
          runSpacing: AppDimens.sm,
          children: [
            for (final type in DocumentType.values)
              _TypeChip(
                type: type,
                selected: type == _type,
                onTap: () => setState(() => _type = type),
              ),
          ],
        ),
        const SizedBox(height: AppDimens.lg),

        // Title (required).
        GlassTextField(
          controller: _titleController,
          label: l.isArabic ? 'العنوان' : 'Title',
          prefixIcon: Icons.title_rounded,
          onChanged: (_) {
            if (_titleError != null) setState(() => _titleError = null);
          },
        ),
        if (_titleError != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _titleError!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.danger),
            ),
          ),
        ],
        const SizedBox(height: AppDimens.lg),

        // Expiry date (optional).
        _DateField(
          label: l.t('expiry_date'),
          value: _expiryDate,
          locale: locale,
          onTap: _pickExpiry,
          onClear: _expiryDate == null ? null : () => setState(() => _expiryDate = null),
        ),
        const SizedBox(height: AppDimens.lg),

        // Issue date (optional).
        _DateField(
          label: l.isArabic ? 'تاريخ الإصدار' : 'Issue Date',
          value: _issueDate,
          locale: locale,
          onTap: _pickIssue,
          onClear: _issueDate == null ? null : () => setState(() => _issueDate = null),
        ),
        const SizedBox(height: AppDimens.lg),

        // Notes.
        GlassTextField(
          controller: _notesController,
          label: l.t('notes'),
          prefixIcon: Icons.notes_rounded,
          maxLines: 2,
        ),
        const SizedBox(height: AppDimens.lg),

        // Optional image attachment.
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(l.isArabic ? 'صورة المستند' : 'Document Image',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: glass.textMuted)),
        ),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            padding: const EdgeInsets.all(AppDimens.md),
            decoration: BoxDecoration(
              color: glass.fill,
              borderRadius: AppDimens.brMd,
              border: Border.all(color: glass.border),
            ),
            child: Row(
              children: [
                if (_localPath != null)
                  ClipRRect(
                    borderRadius: AppDimens.brSm,
                    child: Image.file(
                      File(_localPath!),
                      height: 48,
                      width: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.broken_image_rounded, size: 28, color: glass.textMuted),
                    ),
                  )
                else
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: AppDimens.brSm,
                    ),
                    child: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white, size: 24),
                  ),
                const SizedBox(width: AppDimens.md),
                Expanded(
                  child: Text(
                    _localPath == null
                        ? (l.isArabic ? 'إضافة صورة' : 'Attach image')
                        : (l.isArabic ? 'تغيير الصورة' : 'Change image'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (_localPath != null)
                  GestureDetector(
                    onTap: () => setState(() => _localPath = null),
                    child: Icon(Icons.close_rounded, size: 20, color: glass.textMuted),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimens.xl),

        GlassButton(
          label: l.t('save'),
          icon: Icons.check_rounded,
          loading: _saving,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.locale,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final String locale;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTokens>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: glass.textMuted)),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg, vertical: AppDimens.lg),
            decoration: BoxDecoration(
              color: glass.fill,
              borderRadius: AppDimens.brMd,
              border: Border.all(color: glass.border),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 20, color: glass.textMuted),
                const SizedBox(width: AppDimens.md),
                Expanded(
                  child: Text(
                    value == null ? '—' : Fmt.date(value!, locale: locale),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: value == null ? glass.textMuted : glass.textPrimary,
                        ),
                  ),
                ),
                if (onClear != null)
                  GestureDetector(
                    onTap: onClear,
                    child: Icon(Icons.close_rounded, size: 18, color: glass.textMuted),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type, required this.selected, required this.onTap});
  final DocumentType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final glass = Theme.of(context).extension<GlassTokens>()!;
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
            Icon(
              UiCatalog.documentIcon(type),
              size: 18,
              color: selected ? Colors.white : glass.textMuted,
            ),
            const SizedBox(width: AppDimens.sm),
            Text(
              l.t(type.labelKey),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected ? Colors.white : glass.textPrimary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
