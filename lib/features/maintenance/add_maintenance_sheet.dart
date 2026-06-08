import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/formatters.dart';
import '../../core/ui_catalog.dart';
import '../../localization/app_localizations.dart';
import '../../models/enums.dart';
import '../../models/maintenance_record.dart';
import '../../providers/data_controller.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/glass_sheet.dart';
import '../../widgets/common/glass_text_field.dart';
import '../../widgets/glass/glass_button.dart';

/// Opens the add/log maintenance bottom sheet. Optionally prefilled with a
/// [MaintenanceType] when launched from a status card.
Future<void> showAddMaintenanceSheet(
  BuildContext context,
  WidgetRef ref, {
  MaintenanceType? initialType,
}) {
  return showGlassSheet<void>(
    context,
    child: _AddMaintenanceForm(initialType: initialType),
  );
}

class _AddMaintenanceForm extends ConsumerStatefulWidget {
  const _AddMaintenanceForm({this.initialType});
  final MaintenanceType? initialType;

  @override
  ConsumerState<_AddMaintenanceForm> createState() => _AddMaintenanceFormState();
}

class _AddMaintenanceFormState extends ConsumerState<_AddMaintenanceForm> {
  late MaintenanceType _type;
  late DateTime _changeDate;
  late final TextEditingController _mileageController;
  late final TextEditingController _costController;
  late final TextEditingController _notesController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? MaintenanceType.engineOil;
    _changeDate = DateTime.now();
    final vehicle = ref.read(selectedVehicleProvider);
    _mileageController = TextEditingController(text: vehicle != null ? '${vehicle.currentMileage}' : '');
    _costController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _mileageController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _changeDate,
      firstDate: DateTime(now.year - 30),
      lastDate: now,
    );
    if (picked != null) setState(() => _changeDate = picked);
  }

  Future<void> _save() async {
    final vehicle = ref.read(selectedVehicleProvider);
    if (vehicle == null) return;

    setState(() => _saving = true);

    final changeMileage = int.tryParse(_mileageController.text.trim()) ?? vehicle.currentMileage;
    final cost = double.tryParse(_costController.text.trim()) ?? 0;

    // Build a base record, then derive next-due defaults from its type.
    final base = MaintenanceRecord(
      id: const Uuid().v4(),
      vehicleId: vehicle.id,
      type: _type,
      changeDate: _changeDate,
      changeMileage: changeMileage,
    );
    final next = defaultNextDue(base);

    final record = MaintenanceRecord(
      id: base.id,
      vehicleId: vehicle.id,
      type: _type,
      changeDate: _changeDate,
      changeMileage: changeMileage,
      nextDueMileage: next.mileage,
      nextDueDate: next.date,
      cost: cost,
      notes: _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    await ref.read(dataControllerProvider).saveMaintenance(record);
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
        Text(l.t('log_service'),
            style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: AppDimens.lg),

        // Type selector — wrap of selectable glass chips.
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(l.t('maintenance'),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: glass.textMuted)),
        ),
        Wrap(
          spacing: AppDimens.sm,
          runSpacing: AppDimens.sm,
          children: [
            for (final type in MaintenanceType.values)
              _TypeChip(
                type: type,
                selected: type == _type,
                onTap: () => setState(() => _type = type),
              ),
          ],
        ),
        const SizedBox(height: AppDimens.lg),

        // Change date.
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(l.t('last_change_date'),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: glass.textMuted)),
        ),
        GestureDetector(
          onTap: _pickDate,
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
                Text(Fmt.date(_changeDate, locale: locale),
                    style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimens.lg),

        // Change mileage.
        GlassTextField(
          controller: _mileageController,
          label: l.t('last_change_mileage'),
          hint: l.t('km'),
          prefixIcon: Icons.speed_rounded,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: AppDimens.lg),

        // Cost.
        GlassTextField(
          controller: _costController,
          label: l.t('cost'),
          hint: l.t('currency'),
          prefixIcon: Icons.payments_rounded,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        ),
        const SizedBox(height: AppDimens.lg),

        // Notes.
        GlassTextField(
          controller: _notesController,
          label: l.t('notes'),
          prefixIcon: Icons.notes_rounded,
          maxLines: 3,
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

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type, required this.selected, required this.onTap});
  final MaintenanceType type;
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
              UiCatalog.maintenanceIcon(type),
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
