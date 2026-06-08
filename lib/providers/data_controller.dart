import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import '../models/fuel_log.dart';
import '../models/maintenance_record.dart';
import '../models/vehicle.dart';
import '../models/vehicle_document.dart';
import '../services/health_service.dart';
import '../services/notification_service.dart';
import 'data_providers.dart';
import 'settings_provider.dart';
import 'vehicle_provider.dart';

/// Single entry point for all data mutations. Persists through the repository,
/// refreshes derived providers, keeps the vehicle's mileage current and
/// (re)schedules local reminders.
class DataController {
  DataController(this.ref);
  final Ref ref;

  void _bump() => ref.read(dataRefreshProvider.notifier).state++;

  Future<void> _syncMileage(int odometer) async {
    final v = ref.read(selectedVehicleProvider);
    if (v != null && odometer > v.currentMileage) {
      await ref.read(vehiclesProvider.notifier).updateMileage(odometer);
    }
  }

  // ---- Maintenance ----------------------------------------------------------
  Future<void> saveMaintenance(MaintenanceRecord record) async {
    await ref.read(maintenanceRepositoryProvider).save(record);
    await _syncMileage(record.changeMileage);
    _bump();
    await rescheduleReminders();
  }

  Future<void> deleteMaintenance(String id) async {
    await ref.read(maintenanceRepositoryProvider).delete(id);
    _bump();
    await rescheduleReminders();
  }

  // ---- Fuel -----------------------------------------------------------------
  Future<void> saveFuel(FuelLog log) async {
    await ref.read(fuelRepositoryProvider).save(log);
    await _syncMileage(log.odometer);
    _bump();
  }

  Future<void> deleteFuel(String id) async {
    await ref.read(fuelRepositoryProvider).delete(id);
    _bump();
  }

  // ---- Expenses -------------------------------------------------------------
  Future<void> saveExpense(Expense expense) async {
    await ref.read(expenseRepositoryProvider).save(expense);
    _bump();
  }

  Future<void> deleteExpense(String id) async {
    await ref.read(expenseRepositoryProvider).delete(id);
    _bump();
  }

  // ---- Documents ------------------------------------------------------------
  Future<void> saveDocument(VehicleDocument doc) async {
    await ref.read(documentRepositoryProvider).save(doc);
    _bump();
    await rescheduleReminders();
  }

  Future<void> deleteDocument(String id) async {
    await ref.read(documentRepositoryProvider).delete(id);
    _bump();
    await rescheduleReminders();
  }

  // ---- Reminders ------------------------------------------------------------
  /// Cancels and rebuilds all scheduled notifications from the current state.
  Future<void> rescheduleReminders() async {
    final settings = ref.read(settingsProvider);
    final notifier = NotificationService.instance;
    await notifier.cancelAll();
    if (!settings.notificationsEnabled) return;

    final vehicle = ref.read(selectedVehicleProvider);
    if (vehicle == null) return;
    final lead = Duration(days: settings.reminderDays);
    int id = 1;

    // Maintenance due-date reminders.
    final statuses = ref.read(vehicleHealthProvider).items;
    for (final s in statuses) {
      if (s.nextDueDate == null) continue;
      final when = s.nextDueDate!.subtract(lead);
      await notifier.schedule(
        id: id++,
        title: vehicle.title,
        body: 'maintenance:${s.type.name}',
        when: when,
      );
    }

    // Document & vehicle expiries.
    void expiry(DateTime? date, String tag) {
      if (date == null) return;
      notifier.schedule(id: id++, title: vehicle.title, body: 'expiry:$tag', when: date.subtract(lead));
    }

    expiry(vehicle.insuranceExpiry, 'insurance');
    expiry(vehicle.licenseExpiry, 'license');
    expiry(vehicle.inspectionDate, 'inspection');
  }
}

final dataControllerProvider = Provider<DataController>(DataController.new);

/// Builds the default next-due values for a maintenance record from its type.
({int mileage, DateTime date}) defaultNextDue(MaintenanceRecord r) {
  final interval = r.type.defaultInterval;
  return (
    mileage: r.changeMileage + interval.km,
    date: HealthService.addInterval(r.changeDate, r.type),
  );
}

extension VehicleExpiryX on Vehicle {
  /// Soonest upcoming expiry among insurance/license/inspection.
  DateTime? get nextExpiry {
    final dates = [insuranceExpiry, licenseExpiry, inspectionDate].whereType<DateTime>().toList()..sort();
    return dates.firstOrNull;
  }
}
