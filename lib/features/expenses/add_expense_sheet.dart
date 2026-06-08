import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/formatters.dart';
import '../../core/ui_catalog.dart';
import '../../localization/app_localizations.dart';
import '../../models/enums.dart';
import '../../models/expense.dart';
import '../../providers/data_controller.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_dimens.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/glass_sheet.dart';
import '../../widgets/common/glass_text_field.dart';
import '../../widgets/glass/glass_button.dart';

/// Opens the "add expense" form in a frosted bottom sheet.
Future<void> showAddExpenseSheet(BuildContext context, WidgetRef ref) async {
  await showGlassSheet(context, child: const _AddExpenseForm());
}

class _AddExpenseForm extends ConsumerStatefulWidget {
  const _AddExpenseForm();

  @override
  ConsumerState<_AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends ConsumerState<_AddExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _title = TextEditingController();
  final _notes = TextEditingController();

  ExpenseCategory _category = ExpenseCategory.other;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _notes.dispose();
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

    final expense = Expense(
      id: const Uuid().v4(),
      vehicleId: vehicle.id,
      category: _category,
      amount: double.tryParse(_amount.text.trim().replaceAll(',', '.')) ?? 0,
      date: _date,
      title: _title.text.trim(),
      notes: _notes.text.trim(),
      createdAt: DateTime.now(),
    );

    await ref.read(dataControllerProvider).saveExpense(expense);

    if (!mounted) return;
    if (context.mounted) Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text(savedLabel)));
  }

  String? _positiveAmount(String? v) {
    final value = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
    if (value == null || value <= 0) {
      return context.l10n.isArabic ? 'أدخل مبلغًا صالحًا' : 'Enter a valid amount';
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
          Text(l.t('add_expense'), style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppDimens.xl),

          // Category selector.
          Wrap(
            spacing: AppDimens.sm,
            runSpacing: AppDimens.sm,
            children: [
              for (final c in ExpenseCategory.values)
                _CategoryChip(
                  category: c,
                  selected: _category == c,
                  onTap: () => setState(() => _category = c),
                ),
            ],
          ),
          const SizedBox(height: AppDimens.lg),

          // Amount + date.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GlassTextField(
                  controller: _amount,
                  label: l.t('amount'),
                  hint: l.t('currency'),
                  prefixIcon: Icons.payments_rounded,
                  keyboardType: decimal,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  validator: _positiveAmount,
                ),
              ),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: GlassTextField(
                  controller: TextEditingController(text: Fmt.date(_date, locale: locale)),
                  label: l.t('date'),
                  prefixIcon: Icons.event_rounded,
                  readOnly: true,
                  onTap: _pickDate,
                  suffixIcon: const Icon(Icons.expand_more_rounded, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.md),

          GlassTextField(
            controller: _title,
            label: l.isArabic ? 'العنوان' : 'Title',
            prefixIcon: Icons.title_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppDimens.md),

          GlassTextField(
            controller: _notes,
            label: l.t('notes'),
            prefixIcon: Icons.notes_rounded,
            maxLines: 3,
            textInputAction: TextInputAction.done,
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category, required this.selected, required this.onTap});

  final ExpenseCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final glass = Theme.of(context).extension<GlassTokens>()!;
    final color = UiCatalog.expenseColor(category);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.md, vertical: AppDimens.sm),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.brandGradient : null,
          color: selected ? null : glass.fill,
          borderRadius: AppDimens.brSm,
          border: Border.all(color: selected ? Colors.transparent : glass.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              UiCatalog.expenseIcon(category),
              size: 18,
              color: selected ? Colors.white : color,
            ),
            const SizedBox(width: AppDimens.xs),
            Text(
              l.t(category.labelKey),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected ? Colors.white : glass.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
