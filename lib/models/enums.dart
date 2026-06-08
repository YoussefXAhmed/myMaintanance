/// Domain enums. Kept free of Flutter imports so they stay test-friendly.
/// UI mappings (icons, gradients) live in `core/ui_catalog.dart`.

enum FuelType { petrol, diesel, electric, hybrid }

extension FuelTypeX on FuelType {
  String get labelKey => switch (this) {
        FuelType.petrol => 'petrol',
        FuelType.diesel => 'diesel',
        FuelType.electric => 'electric',
        FuelType.hybrid => 'hybrid',
      };
}

enum TransmissionType { automatic, manual, cvt }

extension TransmissionTypeX on TransmissionType {
  String get labelKey => switch (this) {
        TransmissionType.automatic => 'automatic',
        TransmissionType.manual => 'manual',
        TransmissionType.cvt => 'cvt',
      };
}

/// The twelve tracked maintenance items, each with a sensible default service
/// interval used to compute "next due" and the health score.
enum MaintenanceType {
  engineOil,
  oilFilter,
  airFilter,
  cabinFilter,
  sparkPlugs,
  brakePads,
  brakeFluid,
  coolant,
  timingBelt,
  battery,
  tires,
  transmissionOil,
}

class MaintenanceInterval {
  const MaintenanceInterval(this.km, this.months);
  final int km;
  final int months;
}

extension MaintenanceTypeX on MaintenanceType {
  String get labelKey => switch (this) {
        MaintenanceType.engineOil => 'engine_oil',
        MaintenanceType.oilFilter => 'oil_filter',
        MaintenanceType.airFilter => 'air_filter',
        MaintenanceType.cabinFilter => 'cabin_filter',
        MaintenanceType.sparkPlugs => 'spark_plugs',
        MaintenanceType.brakePads => 'brake_pads',
        MaintenanceType.brakeFluid => 'brake_fluid',
        MaintenanceType.coolant => 'coolant',
        MaintenanceType.timingBelt => 'timing_belt',
        MaintenanceType.battery => 'battery',
        MaintenanceType.tires => 'tires',
        MaintenanceType.transmissionOil => 'transmission_oil',
      };

  /// Default service interval (distance, time) for newly created items.
  MaintenanceInterval get defaultInterval => switch (this) {
        MaintenanceType.engineOil => const MaintenanceInterval(5000, 6),
        MaintenanceType.oilFilter => const MaintenanceInterval(5000, 6),
        MaintenanceType.airFilter => const MaintenanceInterval(20000, 12),
        MaintenanceType.cabinFilter => const MaintenanceInterval(15000, 12),
        MaintenanceType.sparkPlugs => const MaintenanceInterval(40000, 24),
        MaintenanceType.brakePads => const MaintenanceInterval(40000, 24),
        MaintenanceType.brakeFluid => const MaintenanceInterval(40000, 24),
        MaintenanceType.coolant => const MaintenanceInterval(60000, 36),
        MaintenanceType.timingBelt => const MaintenanceInterval(90000, 60),
        MaintenanceType.battery => const MaintenanceInterval(60000, 36),
        MaintenanceType.tires => const MaintenanceInterval(50000, 36),
        MaintenanceType.transmissionOil => const MaintenanceInterval(60000, 36),
      };
}

enum ExpenseCategory {
  fuel,
  maintenance,
  insurance,
  parking,
  carWash,
  registration,
  fines,
  accessories,
  other,
}

extension ExpenseCategoryX on ExpenseCategory {
  String get labelKey => switch (this) {
        ExpenseCategory.fuel => 'cat_fuel',
        ExpenseCategory.maintenance => 'cat_maintenance',
        ExpenseCategory.insurance => 'cat_insurance',
        ExpenseCategory.parking => 'cat_parking',
        ExpenseCategory.carWash => 'cat_carwash',
        ExpenseCategory.registration => 'cat_registration',
        ExpenseCategory.fines => 'cat_fines',
        ExpenseCategory.accessories => 'cat_accessories',
        ExpenseCategory.other => 'cat_other',
      };
}

enum DocumentType { license, insurance, inspection, invoice, receipt }

extension DocumentTypeX on DocumentType {
  String get labelKey => switch (this) {
        DocumentType.license => 'doc_license',
        DocumentType.insurance => 'doc_insurance',
        DocumentType.inspection => 'doc_inspection',
        DocumentType.invoice => 'doc_invoice',
        DocumentType.receipt => 'doc_receipt',
      };
}

/// Small helper to safely decode an enum from its stored name.
T enumFromName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}
