import '../models/fuel_log.dart';
import '../services/cloud_sync_service.dart';
import '../services/local_store.dart';

class FuelRepository {
  const FuelRepository();

  List<FuelLog> getForVehicle(String vehicleId) {
    final list = LocalStore.instance
        .all(LocalStore.fuel)
        .map(FuelLog.fromJson)
        .where((f) => f.vehicleId == vehicleId)
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> save(FuelLog log) async {
    await LocalStore.instance.put(LocalStore.fuel, log.id, log.toJson());
    await CloudSync.instance.upsert(LocalStore.fuel, log.id, log.toJson());
  }

  Future<void> delete(String id) async {
    await LocalStore.instance.delete(LocalStore.fuel, id);
    await CloudSync.instance.remove(LocalStore.fuel, id);
  }
}
