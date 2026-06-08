import 'package:flutter_test/flutter_test.dart';

import 'package:carcare_pro/models/enums.dart';
import 'package:carcare_pro/models/maintenance_record.dart';
import 'package:carcare_pro/models/vehicle.dart';
import 'package:carcare_pro/services/health_service.dart';

void main() {
  Vehicle vehicle({int mileage = 100000, DateTime? insurance}) => Vehicle(
        id: 'v1',
        brand: 'Toyota',
        model: 'Camry',
        year: 2020,
        currentMileage: mileage,
        insuranceExpiry: insurance,
      );

  MaintenanceRecord record(MaintenanceType type, {required int mileage, required DateTime date}) =>
      MaintenanceRecord(
        id: 't',
        vehicleId: 'v1',
        type: type,
        changeDate: date,
        changeMileage: mileage,
      );

  group('HealthService.statusFor', () {
    test('fresh service is healthy', () {
      final info = HealthService.statusFor(
        MaintenanceType.engineOil,
        record(MaintenanceType.engineOil, mileage: 99500, date: DateTime.now()),
        100000, // 500 km into a 5000 km interval
      );
      expect(info.status, DueStatus.ok);
      expect(info.score, greaterThan(85));
    });

    test('past the interval is overdue', () {
      final info = HealthService.statusFor(
        MaintenanceType.engineOil,
        record(MaintenanceType.engineOil, mileage: 90000, date: DateTime(2020)),
        100000, // 10000 km on a 5000 km interval
      );
      expect(info.status, DueStatus.overdue);
      expect(info.score, lessThan(20));
    });

    test('no record is treated as unknown', () {
      final info = HealthService.statusFor(MaintenanceType.tires, null, 100000);
      expect(info.status, DueStatus.unknown);
      expect(info.hasRecord, isFalse);
    });
  });

  group('HealthService.compute', () {
    test('overall score is 0..100 and weighted', () {
      final health = HealthService.compute(
        vehicle(insurance: DateTime.now().add(const Duration(days: 200))),
        {
          MaintenanceType.engineOil:
              record(MaintenanceType.engineOil, mileage: 99500, date: DateTime.now()),
        },
      );
      expect(health.overall, inInclusiveRange(0, 100));
      expect(health.oil, greaterThan(80));
      expect(health.insurance, greaterThan(80));
    });

    test('expired insurance scores zero', () {
      final health = HealthService.compute(
        vehicle(insurance: DateTime(2020)),
        const {},
      );
      expect(health.insurance, 0);
    });
  });

  test('every maintenance type has a sane default interval', () {
    for (final t in MaintenanceType.values) {
      expect(t.defaultInterval.km, greaterThan(0));
      expect(t.defaultInterval.months, greaterThan(0));
      expect(t.labelKey, isNotEmpty);
    }
  });
}
