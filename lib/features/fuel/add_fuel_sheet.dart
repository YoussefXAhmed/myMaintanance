import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/formatters.dart';
import '../../localization/app_localizations.dart';
import '../../models/fuel_log.dart';
import '../../providers/data_controller.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_dimens.dart';
import '../../widgets/common/glass_text_field.dart';
import '../../widgets/glass/glass_button.dart';
import '../../widgets/glass/glass_container.dart';
import '../../widgets/common/glass_sheet.dart';

/// Opens the "add fuel entry" form in a frosted bottom sheet.
Future<void> showAddFuelSheet(BuildContext context, WidgetRef ref) async {
  await showGlassSheet(context, child: const _AddFuelForm());
}

class _AddFuelForm extends ConsumerStatefulWidget {
  const _AddFuelForm();

  @override
  ConsumerState<_AddFuelForm> createState() => _AddFuelFormState();
}

class _AddFuelFormState extends ConsumerState<_AddFuelForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _odometer;
  final _liters = TextEditingController();
  final _cost = TextEditingController();
  final _station = TextEditingController();

  DateTime _date = DateTime.now();
  bool _fullTank = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final vehicle = ref.read(selectedVehicleProvider);
    _odometer = TextEditingController(text: '${vehicle?.currentMileage ?? 0}');
  }

  @override
  void dispose() {
    _odometer.dispose();
    _liters.dispose();
    _cost.dispose();
    _station.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final l = context.l10n;
    if (!_formKey.currentState!.validate()) return;

    final vehicle = ref.read(selectedVehicleProvider);
    if (vehicle == null) return;

    setState(() => _saving = true);

    // Capture the root messenger before any await so the toast survives the pop.
    final messenger = ScaffoldMessenger.of(context);
    final savedLabel = l.t('saved');

    final log = FuelLog(
      id: const Uuid().v4(),
      vehicleId: vehicle.id,
      date: _date,
      odometer: int.tryParse(_odometer.text.trim()) ?? 0,
      liters: double.tryParse(_liters.text.trim().replaceAll(',', '.')) ?? 0,
      cost: double.tryParse(_cost.text.trim().replaceAll(',', '.')) ?? 0,
      station: _station.text.trim(),
      fullTank: _fullTank,
      createdAt: DateTime.now(),
    );

    await ref.read(dataControllerProvider).saveFuel(log);

    if (!mounted) return;
    if (context.mounted) Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text(savedLabel)));
  }

  String? _positive(String? v, String label) {
    final value = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
    if (value == null || value <= 0) {
      return context.l10n.isArabic ? 'أدخل $label صالحًا' : 'Enter a valid $label';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final locale = ref.watch(settingsProvider).locale.languageCode;
    const decimal = TextInputType.numberWithOptions(decimal: true);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.t('add_fuel'), style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppDimens.xl),

          // Date picker.
          GlassTextField(
            controller: TextEditingController(text: Fmt.date(_date, locale: locale)),
            label: l.t('date'),
            prefixIcon: Icons.event_rounded,
            readOnly: true,
            onTap: _pickDate,
            suffixIcon: const Icon(Icons.expand_more_rounded, size: 20),
          ),
          const SizedBox(height: AppDimens.md),

          GlassTextField(
            controller: _odometer,
            label: l.t('odometer'),
            hint: l.t('km'),
            prefixIcon: Icons.speed_rounded,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: AppDimens.md),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GlassTextField(
                  controller: _liters,
                  label: l.t('liters'),
                  hint: l.t('liter'),
                  prefixIcon: Icons.local_gas_station_rounded,
                  keyboardType: decimal,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  validator: (v) => _positive(v, l.t('liters')),
                ),
              ),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: GlassTextField(
                  controller: _cost,
                  label: l.t('cost'),
                  hint: l.t('currency'),
                  prefixIcon: Icons.payments_rounded,
                  keyboardType: decimal,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  validator: (v) => _positive(v, l.t('cost')),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.md),

          GlassTextField(
            controller: _station,
            label: l.t('gas_station'),
            prefixIcon: Icons.location_on_rounded,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppDimens.md),

          // Full-tank toggle.
          GlassContainer(
            shadow: false,
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg, vertical: AppDimens.xs),
            child: Row(
              children: [
                const Icon(Icons.water_drop_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: AppDimens.md),
                Expanded(
                  child: Text(l.isArabic ? 'خزان ممتلئ' : 'Full Tank',
                      style: Theme.of(context).textTheme.bodyLarge),
                ),
                Switch(
                  value: _fullTank,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _fullTank = v),
                ),
              ],
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
      ),
    );
  }
}
