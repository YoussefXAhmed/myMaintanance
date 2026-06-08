import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/expense.dart';
import '../models/fuel_log.dart';
import '../models/maintenance_record.dart';
import '../models/vehicle_document.dart';
import '../repositories/document_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/fuel_repository.dart';
import '../repositories/maintenance_repository.dart';
import '../services/ai_advisor_service.dart';
import '../services/health_service.dart';
import 'vehicle_provider.dart';

/// Bumped after every write so the derived list/stat providers recompute.
final dataRefreshProvider = StateProvider<int>((_) => 0);

final maintenanceRepositoryProvider = Provider((_) => const MaintenanceRepository());
final fuelRepositoryProvider = Provider((_) => const FuelRepository());
final expenseRepositoryProvider = Provider((_) => const ExpenseRepository());
final documentRepositoryProvider = Provider((_) => const DocumentRepository());

List<T> _forSelected<T>(Ref ref, List<T> Function(String vehicleId) load) {
  ref.watch(dataRefreshProvider);
  final v = ref.watch(selectedVehicleProvider);
  if (v == null) return const [];
  return load(v.id);
}

final maintenanceListProvider = Provider<List<MaintenanceRecord>>(
    (ref) => _forSelected(ref, (id) => ref.read(maintenanceRepositoryProvider).getForVehicle(id)));

final fuelListProvider = Provider<List<FuelLog>>(
    (ref) => _forSelected(ref, (id) => ref.read(fuelRepositoryProvider).getForVehicle(id)));

final expenseListProvider = Provider<List<Expense>>(
    (ref) => _forSelected(ref, (id) => ref.read(expenseRepositoryProvider).getForVehicle(id)));

final documentListProvider = Provider<List<VehicleDocument>>(
    (ref) => _forSelected(ref, (id) => ref.read(documentRepositoryProvider).getForVehicle(id)));

final latestMaintenanceByTypeProvider = Provider<Map<MaintenanceType, MaintenanceRecord>>((ref) {
  ref.watch(dataRefreshProvider);
  final v = ref.watch(selectedVehicleProvider);
  if (v == null) return const {};
  return ref.read(maintenanceRepositoryProvider).latestByType(v.id);
});

final vehicleHealthProvider = Provider<VehicleHealth>((ref) {
  final v = ref.watch(selectedVehicleProvider);
  if (v == null) return VehicleHealth.empty;
  return HealthService.compute(v, ref.watch(latestMaintenanceByTypeProvider));
});

final advisorProvider = Provider<List<AdvisorRecommendation>>((ref) {
  final v = ref.watch(selectedVehicleProvider);
  if (v == null) return const [];
  return const RuleBasedAdvisor().analyze(vehicle: v, health: ref.watch(vehicleHealthProvider));
});

// ---------------------------------------------------------------------------
// Analytics
// ---------------------------------------------------------------------------
class FuelStats {
  const FuelStats({
    this.kmPerLiter = 0,
    this.costPerKm = 0,
    this.monthlySpend = 0,
    this.yearlySpend = 0,
    this.totalLiters = 0,
    this.avgPrice = 0,
  });
  final double kmPerLiter;
  final double costPerKm;
  final double monthlySpend;
  final double yearlySpend;
  final double totalLiters;
  final double avgPrice;
}

final fuelStatsProvider = Provider<FuelStats>((ref) {
  final logs = ref.watch(fuelListProvider);
  if (logs.length < 2) {
    final spend = logs.fold<double>(0, (s, l) => s + l.cost);
    return FuelStats(
      monthlySpend: spend,
      yearlySpend: spend,
      totalLiters: logs.fold(0, (s, l) => s + l.liters),
      avgPrice: logs.isEmpty ? 0 : logs.first.pricePerLiter,
    );
  }
  final sorted = [...logs]..sort((a, b) => a.odometer.compareTo(b.odometer));
  final totalDistance = sorted.last.odometer - sorted.first.odometer;
  // Litres used to cover that distance excludes the very first fill.
  final litersUsed = sorted.skip(1).fold<double>(0, (s, l) => s + l.liters);
  final kmPerLiter = litersUsed > 0 ? totalDistance / litersUsed : 0.0;
  final totalCost = logs.fold<double>(0, (s, l) => s + l.cost);
  final costPerKm = totalDistance > 0 ? sorted.skip(1).fold<double>(0, (s, l) => s + l.cost) / totalDistance : 0.0;

  final now = DateTime.now();
  final monthly = logs
      .where((l) => l.date.year == now.year && l.date.month == now.month)
      .fold<double>(0, (s, l) => s + l.cost);
  final yearly = logs.where((l) => l.date.year == now.year).fold<double>(0, (s, l) => s + l.cost);

  return FuelStats(
    kmPerLiter: kmPerLiter.toDouble(),
    costPerKm: costPerKm.toDouble(),
    monthlySpend: monthly,
    yearlySpend: yearly,
    totalLiters: logs.fold(0, (s, l) => s + l.liters),
    avgPrice: totalCost / logs.fold<double>(0, (s, l) => s + l.liters),
  );
});

class ExpenseStats {
  const ExpenseStats({
    this.total = 0,
    this.monthly = 0,
    this.yearly = 0,
    this.byCategory = const {},
    this.monthlySeries = const [],
  });
  final double total;
  final double monthly;
  final double yearly;
  final Map<ExpenseCategory, double> byCategory;

  /// Last 6 months of totals (oldest → newest) for the trend chart.
  final List<double> monthlySeries;
}

/// Combines tracked [Expense]s with fuel and maintenance costs for a full
/// picture of vehicle spending.
final expenseStatsProvider = Provider<ExpenseStats>((ref) {
  final expenses = ref.watch(expenseListProvider);
  final fuels = ref.watch(fuelListProvider);
  final services = ref.watch(maintenanceListProvider);
  final now = DateTime.now();

  final byCategory = <ExpenseCategory, double>{};
  void add(ExpenseCategory c, double v) => byCategory[c] = (byCategory[c] ?? 0) + v;

  double total = 0, monthly = 0, yearly = 0;
  final series = List<double>.filled(6, 0);

  void account(DateTime date, double amount, ExpenseCategory category) {
    total += amount;
    add(category, amount);
    if (date.year == now.year) yearly += amount;
    if (date.year == now.year && date.month == now.month) monthly += amount;
    final monthsAgo = (now.year - date.year) * 12 + (now.month - date.month);
    if (monthsAgo >= 0 && monthsAgo < 6) series[5 - monthsAgo] += amount;
  }

  for (final e in expenses) {
    account(e.date, e.amount, e.category);
  }
  for (final f in fuels) {
    account(f.date, f.cost, ExpenseCategory.fuel);
  }
  for (final s in services) {
    if (s.cost > 0) account(s.changeDate, s.cost, ExpenseCategory.maintenance);
  }

  return ExpenseStats(
    total: total,
    monthly: monthly,
    yearly: yearly,
    byCategory: byCategory,
    monthlySeries: series,
  );
});
