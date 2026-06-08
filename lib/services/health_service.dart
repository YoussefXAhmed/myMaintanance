import '../models/enums.dart';
import '../models/maintenance_record.dart';
import '../models/vehicle.dart';

enum DueStatus { ok, dueSoon, overdue, unknown }

/// Computed status of a single maintenance item, given the latest record and
/// the vehicle's current mileage.
class MaintenanceStatusInfo {
  const MaintenanceStatusInfo({
    required this.type,
    required this.status,
    required this.lifeUsed,
    required this.score,
    this.nextDueMileage,
    this.nextDueDate,
    this.kmRemaining,
    this.daysRemaining,
    this.hasRecord = true,
  });

  final MaintenanceType type;
  final DueStatus status;
  final double lifeUsed; // 0..1
  final double score; // 0..100
  final int? nextDueMileage;
  final DateTime? nextDueDate;
  final int? kmRemaining;
  final int? daysRemaining;
  final bool hasRecord;
}

/// Overall vehicle health plus the four headline sub-scores shown on the
/// dashboard rings.
class VehicleHealth {
  const VehicleHealth({
    required this.overall,
    required this.oil,
    required this.battery,
    required this.tires,
    required this.insurance,
    required this.items,
  });

  final double overall;
  final double oil;
  final double battery;
  final double tires;
  final double insurance;
  final List<MaintenanceStatusInfo> items;

  static const VehicleHealth empty = VehicleHealth(
    overall: 0,
    oil: 0,
    battery: 0,
    tires: 0,
    insurance: 0,
    items: [],
  );
}

class HealthService {
  HealthService._();

  static const double _unknownScore = 78; // optimistic default for new vehicles

  /// Status for one item. [latest] is the most recent record of its type (or
  /// null if never serviced).
  static MaintenanceStatusInfo statusFor(
    MaintenanceType type,
    MaintenanceRecord? latest,
    int currentMileage,
  ) {
    if (latest == null) {
      return MaintenanceStatusInfo(
        type: type,
        status: DueStatus.unknown,
        lifeUsed: 1 - _unknownScore / 100,
        score: _unknownScore,
        hasRecord: false,
      );
    }

    final interval = type.defaultInterval;
    final dueMileage = latest.nextDueMileage ?? (latest.changeMileage + interval.km);
    final dueDate = latest.nextDueDate ?? _addMonths(latest.changeDate, interval.months);

    final kmRemaining = dueMileage - currentMileage;
    final daysRemaining = dueDate.difference(DateTime.now()).inDays;

    final kmUsed = ((currentMileage - latest.changeMileage) / interval.km).clamp(0.0, 2.0);
    final timeUsed =
        (DateTime.now().difference(latest.changeDate).inDays / (interval.months * 30.0)).clamp(0.0, 2.0);
    final lifeUsed = kmUsed > timeUsed ? kmUsed : timeUsed;
    final score = ((1 - lifeUsed) * 100).clamp(0.0, 100.0);

    DueStatus status;
    if (kmRemaining <= 0 || daysRemaining <= 0) {
      status = DueStatus.overdue;
    } else if (kmRemaining <= interval.km * 0.12 || daysRemaining <= 14) {
      status = DueStatus.dueSoon;
    } else {
      status = DueStatus.ok;
    }

    return MaintenanceStatusInfo(
      type: type,
      status: status,
      lifeUsed: lifeUsed.toDouble(),
      score: score.toDouble(),
      nextDueMileage: dueMileage,
      nextDueDate: dueDate,
      kmRemaining: kmRemaining,
      daysRemaining: daysRemaining,
    );
  }

  static double insuranceScore(Vehicle v) {
    final dates = [v.insuranceExpiry].whereType<DateTime>();
    if (dates.isEmpty) return _unknownScore;
    final days = v.insuranceExpiry!.difference(DateTime.now()).inDays;
    if (days <= 0) return 0;
    return (days / 180 * 100).clamp(0.0, 100.0).toDouble();
  }

  /// Full health computation. [latestByType] maps each serviced type to its
  /// most recent record.
  static VehicleHealth compute(
    Vehicle vehicle,
    Map<MaintenanceType, MaintenanceRecord> latestByType,
  ) {
    final items = <MaintenanceStatusInfo>[];
    for (final type in MaintenanceType.values) {
      items.add(statusFor(type, latestByType[type], vehicle.currentMileage));
    }

    double scoreOf(MaintenanceType t) => items.firstWhere((i) => i.type == t).score;

    final insurance = insuranceScore(vehicle);

    // Weighted overall — safety-critical items count for more.
    const weights = <MaintenanceType, double>{
      MaintenanceType.engineOil: 1.6,
      MaintenanceType.brakePads: 1.5,
      MaintenanceType.tires: 1.4,
      MaintenanceType.battery: 1.2,
      MaintenanceType.timingBelt: 1.3,
      MaintenanceType.brakeFluid: 1.1,
      MaintenanceType.coolant: 1.0,
      MaintenanceType.transmissionOil: 1.0,
      MaintenanceType.sparkPlugs: 0.9,
      MaintenanceType.oilFilter: 0.8,
      MaintenanceType.airFilter: 0.7,
      MaintenanceType.cabinFilter: 0.6,
    };

    double weightedSum = 0, weightTotal = 0;
    for (final item in items) {
      final w = weights[item.type] ?? 1.0;
      weightedSum += item.score * w;
      weightTotal += w;
    }
    // Fold insurance in with a meaningful weight.
    const insWeight = 1.2;
    weightedSum += insurance * insWeight;
    weightTotal += insWeight;

    final overall = (weightedSum / weightTotal).clamp(0.0, 100.0).toDouble();

    return VehicleHealth(
      overall: overall,
      oil: scoreOf(MaintenanceType.engineOil),
      battery: scoreOf(MaintenanceType.battery),
      tires: scoreOf(MaintenanceType.tires),
      insurance: insurance,
      items: items,
    );
  }

  static DateTime _addMonths(DateTime d, int months) {
    final totalMonth = d.month - 1 + months;
    final year = d.year + totalMonth ~/ 12;
    final month = totalMonth % 12 + 1;
    final day = d.day.clamp(1, _daysInMonth(year, month));
    return DateTime(year, month, day);
  }

  static int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  static DateTime addInterval(DateTime from, MaintenanceType type) =>
      _addMonths(from, type.defaultInterval.months);
}
