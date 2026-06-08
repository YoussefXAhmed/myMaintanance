import '../models/vehicle_document.dart';
import '../services/cloud_sync_service.dart';
import '../services/local_store.dart';

class DocumentRepository {
  const DocumentRepository();

  List<VehicleDocument> getForVehicle(String vehicleId) {
    final list = LocalStore.instance
        .all(LocalStore.documents)
        .map(VehicleDocument.fromJson)
        .where((d) => d.vehicleId == vehicleId)
        .toList();
    list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return list;
  }

  Future<void> save(VehicleDocument doc) async {
    await LocalStore.instance.put(LocalStore.documents, doc.id, doc.toJson());
    await CloudSync.instance.upsert(LocalStore.documents, doc.id, doc.toJson());
  }

  Future<void> delete(String id) async {
    await LocalStore.instance.delete(LocalStore.documents, id);
    await CloudSync.instance.remove(LocalStore.documents, id);
  }
}
