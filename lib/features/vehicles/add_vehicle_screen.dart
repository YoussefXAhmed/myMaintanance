import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/formatters.dart';
import '../../core/ui_catalog.dart';
import '../../localization/app_localizations.dart';
import '../../models/enums.dart';
import '../../models/vehicle.dart';
import '../../providers/data_controller.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/glass_text_field.dart';
import '../../widgets/glass/glass_app_bar.dart';
import '../../widgets/glass/glass_button.dart';
import '../../widgets/glass/glass_container.dart';
import '../../widgets/glass/glass_scaffold.dart';
import 'vehicle_widgets.dart';

/// Create or edit a vehicle. Router passes the existing [vehicle] via `extra`.
class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key, this.vehicle});
  final Vehicle? vehicle;

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _year;
  late final TextEditingController _trim;
  late final TextEditingController _engine;
  late final TextEditingController _plate;
  late final TextEditingController _vin;
  late final TextEditingController _mileage;
  late final TextEditingController _imageUrlCtrl;

  String? _imageUrl;
  late FuelType _fuelType;
  late TransmissionType _transmission;
  DateTime? _insuranceExpiry;
  DateTime? _licenseExpiry;
  DateTime? _inspectionDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _brand = TextEditingController(text: v?.brand ?? '');
    _model = TextEditingController(text: v?.model ?? '');
    _year = TextEditingController(text: (v?.year ?? DateTime.now().year).toString());
    _trim = TextEditingController(text: v?.trim ?? '');
    _engine = TextEditingController(text: v?.engine ?? '');
    _plate = TextEditingController(text: v?.plateNumber ?? '');
    _vin = TextEditingController(text: v?.vin ?? '');
    _mileage = TextEditingController(text: (v?.currentMileage ?? 0).toString());
    _imageUrl = v?.imageUrl;
    _imageUrlCtrl = TextEditingController(text: v?.imageUrl ?? '');
    _fuelType = v?.fuelType ?? FuelType.petrol;
    _transmission = v?.transmission ?? TransmissionType.automatic;
    _insuranceExpiry = v?.insuranceExpiry;
    _licenseExpiry = v?.licenseExpiry;
    _inspectionDate = v?.inspectionDate;
  }

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _year.dispose();
    _trim.dispose();
    _engine.dispose();
    _plate.dispose();
    _vin.dispose();
    _mileage.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      setState(() {
        _imageUrl = picked.path;
        _imageUrlCtrl.text = picked.path;
      });
    } catch (_) {
      // Ignore picker failures (permissions, cancellation, etc.).
    }
  }

  Future<void> _pickDate(DateTime? current, ValueChanged<DateTime> onPicked) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 2, now.month, now.day),
      lastDate: DateTime(now.year + 10, now.month, now.day),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _save() async {
    final l = context.l10n;
    if (_brand.text.trim().isEmpty || _model.text.trim().isEmpty) {
      _formKey.currentState?.validate();
      return;
    }

    // Capture the messenger before any pop so the SnackBar survives navigation.
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);

    final notifier = ref.read(vehiclesProvider.notifier);
    final base = widget.vehicle ?? notifier.draft();
    final image = _imageUrl == null || _imageUrl!.trim().isEmpty ? null : _imageUrl!.trim();

    final vehicle = base.copyWith(
      brand: _brand.text.trim(),
      model: _model.text.trim(),
      year: int.tryParse(_year.text.trim()) ?? DateTime.now().year,
      trim: _trim.text.trim(),
      engine: _engine.text.trim(),
      fuelType: _fuelType,
      transmission: _transmission,
      plateNumber: _plate.text.trim(),
      vin: _vin.text.trim(),
      currentMileage: int.tryParse(_mileage.text.trim()) ?? 0,
      imageUrl: image,
      insuranceExpiry: _insuranceExpiry,
      licenseExpiry: _licenseExpiry,
      inspectionDate: _inspectionDate,
    );

    await notifier.addOrUpdate(vehicle, isNew: widget.vehicle == null);
    await ref.read(dataControllerProvider).rescheduleReminders();

    if (!mounted) return;
    if (context.mounted) context.pop();
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(l.t('saved'))));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final locale = ref.watch(settingsProvider).locale.languageCode;
    final isEdit = widget.vehicle != null;

    return GlassScaffold(
      appBar: GlassAppBar(
        title: l.t(isEdit ? 'edit_vehicle' : 'add_vehicle'),
        showBack: true,
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.lg, AppDimens.lg, AppDimens.xxl),
            children: [
              _imageHeader(l, locale)
                  .animate()
                  .fadeIn(duration: 350.ms)
                  .moveY(begin: 14, end: 0),
              const SizedBox(height: AppDimens.lg),
              _section(
                title: l.t('vehicle_details'),
                children: [
                  GlassTextField(
                    controller: _brand,
                    label: l.t('brand'),
                    prefixIcon: Icons.directions_car_filled_rounded,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? (l.isArabic ? 'مطلوب' : 'Required') : null,
                  ),
                  GlassTextField(
                    controller: _model,
                    label: l.t('model'),
                    prefixIcon: Icons.badge_rounded,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? (l.isArabic ? 'مطلوب' : 'Required') : null,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GlassTextField(
                          controller: _year,
                          label: l.t('year'),
                          prefixIcon: Icons.calendar_today_rounded,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: AppDimens.md),
                      Expanded(
                        child: GlassTextField(
                          controller: _trim,
                          label: l.t('trim'),
                          prefixIcon: Icons.tune_rounded,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  GlassTextField(
                    controller: _engine,
                    label: l.t('engine'),
                    prefixIcon: Icons.settings_rounded,
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.lg),
              _section(
                title: l.isArabic ? 'التعريف' : 'Identification',
                children: [
                  GlassTextField(
                    controller: _plate,
                    label: l.t('plate_number'),
                    prefixIcon: Icons.pin_rounded,
                    textInputAction: TextInputAction.next,
                  ),
                  GlassTextField(
                    controller: _vin,
                    label: l.t('vin'),
                    prefixIcon: Icons.tag_rounded,
                    textInputAction: TextInputAction.next,
                  ),
                  GlassTextField(
                    controller: _mileage,
                    label: l.t('current_mileage'),
                    prefixIcon: Icons.speed_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.lg),
              _section(
                title: l.t('fuel_type'),
                children: [
                  Wrap(
                    spacing: AppDimens.sm,
                    runSpacing: AppDimens.sm,
                    children: [
                      for (final f in FuelType.values)
                        _SelectChip(
                          icon: UiCatalog.fuelIcon(f),
                          label: l.t(f.labelKey),
                          selected: _fuelType == f,
                          onTap: () => setState(() => _fuelType = f),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.md),
                  Text(
                    l.t('transmission'),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).extension<GlassTokens>()!.textMuted,
                        ),
                  ),
                  const SizedBox(height: AppDimens.sm),
                  Wrap(
                    spacing: AppDimens.sm,
                    runSpacing: AppDimens.sm,
                    children: [
                      for (final t in TransmissionType.values)
                        _SelectChip(
                          icon: Icons.settings_rounded,
                          label: l.t(t.labelKey),
                          selected: _transmission == t,
                          onTap: () => setState(() => _transmission = t),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.lg),
              _section(
                title: l.isArabic ? 'التواريخ' : 'Dates',
                children: [
                  _DateRow(
                    label: l.t('insurance_expiry'),
                    value: _insuranceExpiry,
                    locale: locale,
                    onTap: () => _pickDate(_insuranceExpiry, (d) => setState(() => _insuranceExpiry = d)),
                  ),
                  _DateRow(
                    label: l.t('license_expiry'),
                    value: _licenseExpiry,
                    locale: locale,
                    onTap: () => _pickDate(_licenseExpiry, (d) => setState(() => _licenseExpiry = d)),
                  ),
                  _DateRow(
                    label: l.t('inspection_date'),
                    value: _inspectionDate,
                    locale: locale,
                    onTap: () => _pickDate(_inspectionDate, (d) => setState(() => _inspectionDate = d)),
                  ),
                ],
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
        ),
      ),
    );
  }

  Widget _imageHeader(AppLocalizations l, String locale) {
    final preview = (_imageUrl != null && _imageUrl!.trim().isNotEmpty)
        ? Vehicle(id: 'preview', brand: '', model: '', year: DateTime.now().year, imageUrl: _imageUrl!.trim())
        : null;
    return GlassContainer(
      padding: const EdgeInsets.all(AppDimens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: preview != null
                ? VehicleImage(vehicle: preview, height: 170)
                : Container(
                    height: 170,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: AppDimens.brLg,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_rounded, size: 42, color: Colors.white.withValues(alpha: 0.9)),
                        const SizedBox(height: AppDimens.sm),
                        Text(
                          l.isArabic ? 'إضافة صورة' : 'Add photo',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: AppDimens.md),
          GlassTextField(
            controller: _imageUrlCtrl,
            label: l.isArabic ? 'رابط الصورة' : 'Image URL',
            hint: 'https://…',
            prefixIcon: Icons.link_rounded,
            keyboardType: TextInputType.url,
            onChanged: (v) => setState(() => _imageUrl = v),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required List<Widget> children}) {
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) spaced.add(const SizedBox(height: AppDimens.md));
      spaced.add(children[i]);
    }
    return GlassContainer(
      padding: const EdgeInsets.all(AppDimens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: glass.textPrimary),
          ),
          const SizedBox(height: AppDimens.md),
          ...spaced,
        ],
      ),
    );
  }
}

class _SelectChip extends StatelessWidget {
  const _SelectChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTokens>()!;
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        strong: selected,
        shadow: false,
        gradient: selected
            ? LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.85),
                  AppColors.secondary.withValues(alpha: 0.85),
                ],
              )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.md, vertical: AppDimens.sm),
        borderRadius: BorderRadius.circular(14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : glass.textPrimary),
            const SizedBox(width: 6),
            Text(
              label,
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

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.locale,
    required this.onTap,
  });
  final String label;
  final DateTime? value;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final glass = Theme.of(context).extension<GlassTokens>()!;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.md),
        child: GlassContainer(
          shadow: false,
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.md, vertical: AppDimens.md),
          borderRadius: BorderRadius.circular(14),
          child: Row(
            children: [
              const Icon(Icons.event_rounded, size: 20),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                value == null ? l.t('optional') : Fmt.date(value!, locale: locale),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: value == null ? glass.textMuted : AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
