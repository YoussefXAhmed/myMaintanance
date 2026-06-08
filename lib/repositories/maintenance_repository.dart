import '../models/enums.dart';
import '../models/maintenance_record.dart';
import '../services/cloud_sync_service.dart';
import '../services/local_store.dart';

class MaintenanceRepository {
  const MaintenanceRepository();

  List<MaintenanceRecord> getForVehicle(String vehicleId) {
    final list = LocalStore.instance
        .all(LocalStore.maintenance)
        .map(MaintenanceRecord.fromJson)
        .where((r) => r.vehicleId == vehicleId)
        .toList();
    list.sort((a, b) => b.changeDate.compareTo(a.changeDate));
    return list;
  }

  /// Most recent record per maintenance type (drives the health score).
  Map<MaintenanceType, MaintenanceRecord> latestByType(String vehicleId) {
    final map = <MaintenanceType, MaintenanceRecord>{};
    for (final r in getForVehicle(vehicleId)) {
      final existing = map[r.type];
      if (existing == null || r.changeDate.isAfter(existing.changeDate)) {
        map[r.type] = r;
      }
    }
    return map;
  }

  Future<void> save(MaintenanceRecord record) async {
    await LocalStore.instance.put(LocalStore.maintenance, record.id, record.toJson());
    await CloudSync.instance.upsert(LocalStore.maintenance, record.id, record.toJson());
  }

  Future<void> delete(String id) async {
    await LocalStore.instance.delete(LocalStore.maintenance, id);
    await CloudSync.instance.remove(LocalStore.maintenance, id);
  }
}
