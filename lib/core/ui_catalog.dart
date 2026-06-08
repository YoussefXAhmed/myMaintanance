import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../themes/app_colors.dart';

/// Maps domain enums to their visual identity (icon + accent). Keeps the model
/// layer free of Flutter while giving the UI a single source of truth.
class UiCatalog {
  UiCatalog._();

  static IconData maintenanceIcon(MaintenanceType t) => switch (t) {
        MaintenanceType.engineOil => Icons.oil_barrel_rounded,
        MaintenanceType.oilFilter => Icons.filter_alt_rounded,
        MaintenanceType.airFilter => Icons.air_rounded,
        MaintenanceType.cabinFilter => Icons.ac_unit_rounded,
        MaintenanceType.sparkPlugs => Icons.bolt_rounded,
        MaintenanceType.brakePads => Icons.disc_full_rounded,
        MaintenanceType.brakeFluid => Icons.water_drop_rounded,
        MaintenanceType.coolant => Icons.thermostat_rounded,
        MaintenanceType.timingBelt => Icons.settings_rounded,
        MaintenanceType.battery => Icons.battery_charging_full_rounded,
        MaintenanceType.tires => Icons.trip_origin_rounded,
        MaintenanceType.transmissionOil => Icons.settings_input_component_rounded,
      };

  static Gradient maintenanceGradient(MaintenanceType t) {
    const gradients = [
      AppColors.brandGradient,
      AppColors.mintGradient,
      AppColors.sunsetGradient,
    ];
    return gradients[t.index % gradients.length];
  }

  static IconData expenseIcon(ExpenseCategory c) => switch (c) {
        ExpenseCategory.fuel => Icons.local_gas_station_rounded,
        ExpenseCategory.maintenance => Icons.build_rounded,
        ExpenseCategory.insurance => Icons.shield_rounded,
        ExpenseCategory.parking => Icons.local_parking_rounded,
        ExpenseCategory.carWash => Icons.local_car_wash_rounded,
        ExpenseCategory.registration => Icons.assignment_rounded,
        ExpenseCategory.fines => Icons.gavel_rounded,
        ExpenseCategory.accessories => Icons.auto_awesome_rounded,
        ExpenseCategory.other => Icons.category_rounded,
      };

  static Color expenseColor(ExpenseCategory c) => switch (c) {
        ExpenseCategory.fuel => AppColors.accentAmber,
        ExpenseCategory.maintenance => AppColors.primary,
        ExpenseCategory.insurance => AppColors.tertiary,
        ExpenseCategory.parking => AppColors.info,
        ExpenseCategory.carWash => const Color(0xFF38BDF8),
        ExpenseCategory.registration => AppColors.secondary,
        ExpenseCategory.fines => AppColors.danger,
        ExpenseCategory.accessories => AppColors.accentPink,
        ExpenseCategory.other => const Color(0xFF94A3B8),
      };

  static IconData documentIcon(DocumentType t) => switch (t) {
        DocumentType.license => Icons.badge_rounded,
        DocumentType.insurance => Icons.verified_user_rounded,
        DocumentType.inspection => Icons.fact_check_rounded,
        DocumentType.invoice => Icons.receipt_long_rounded,
        DocumentType.receipt => Icons.receipt_rounded,
      };

  static IconData fuelIcon(FuelType t) => switch (t) {
        FuelType.petrol => Icons.local_gas_station_rounded,
        FuelType.diesel => Icons.local_gas_station_rounded,
        FuelType.electric => Icons.electric_bolt_rounded,
        FuelType.hybrid => Icons.eco_rounded,
      };
}
