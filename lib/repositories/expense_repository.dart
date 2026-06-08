import '../models/expense.dart';
import '../services/cloud_sync_service.dart';
import '../services/local_store.dart';

class ExpenseRepository {
  const ExpenseRepository();

  List<Expense> getForVehicle(String vehicleId) {
    final list = LocalStore.instance
        .all(LocalStore.expenses)
        .map(Expense.fromJson)
        .where((e) => e.vehicleId == vehicleId)
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> save(Expense expense) async {
    await LocalStore.instance.put(LocalStore.expenses, expense.id, expense.toJson());
    await CloudSync.instance.upsert(LocalStore.expenses, expense.id, expense.toJson());
  }

  Future<void> delete(String id) async {
    await LocalStore.instance.delete(LocalStore.expenses, id);
    await CloudSync.instance.remove(LocalStore.expenses, id);
  }
}
