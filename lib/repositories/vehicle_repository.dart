import '../models/vehicle.dart';
import '../services/cloud_sync_service.dart';
import '../services/local_store.dart';

/// Offline-first CRUD for vehicles.
class VehicleRepository {
  const VehicleRepository();

  List<Vehicle> getAll() {
    final list = LocalStore.instance.all(LocalStore.vehicles).map(Vehicle.fromJson).toList();
    list.sort((a, b) {
      if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
      return (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0));
    });
    return list;
  }

  Future<void> save(Vehicle vehicle) async {
    await LocalStore.instance.put(LocalStore.vehicles, vehicle.id, vehicle.toJson());
    await CloudSync.instance.upsert(LocalStore.vehicles, vehicle.id, vehicle.toJson());
  }

  Future<void> delete(String id) async {
    await LocalStore.instance.delete(LocalStore.vehicles, id);
    await CloudSync.instance.remove(LocalStore.vehicles, id);
    // Cascade: drop dependent records locally.
    for (final c in [LocalStore.maintenance, LocalStore.fuel, LocalStore.expenses, LocalStore.documents]) {
      await LocalStore.instance.deleteWhere(c, (j) => j['vehicleId'] == id);
    }
  }
}
