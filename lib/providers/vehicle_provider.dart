import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/vehicle.dart';
import '../repositories/vehicle_repository.dart';
import '../services/local_store.dart';

final vehicleRepositoryProvider = Provider((_) => const VehicleRepository());

class VehiclesState {
  const VehiclesState({this.vehicles = const [], this.selectedId});
  final List<Vehicle> vehicles;
  final String? selectedId;

  Vehicle? get selected {
    if (vehicles.isEmpty) return null;
    return vehicles.firstWhere(
      (v) => v.id == selectedId,
      orElse: () => vehicles.first,
    );
  }

  bool get isEmpty => vehicles.isEmpty;

  VehiclesState copyWith({List<Vehicle>? vehicles, String? selectedId}) =>
      VehiclesState(vehicles: vehicles ?? this.vehicles, selectedId: selectedId ?? this.selectedId);
}

class VehiclesNotifier extends Notifier<VehiclesState> {
  static const _uuid = Uuid();
  static const _kSelected = 'selected_vehicle';

  VehicleRepository get _repo => ref.read(vehicleRepositoryProvider);

  @override
  VehiclesState build() {
    final vehicles = _repo.getAll();
    final stored = LocalStore.instance.setting<String>(_kSelected);
    final selected = vehicles.any((v) => v.id == stored) ? stored : vehicles.firstOrNull?.id;
    return VehiclesState(vehicles: vehicles, selectedId: selected);
  }

  void _reload({String? select}) {
    final vehicles = _repo.getAll();
    final selected = select ??
        (vehicles.any((v) => v.id == state.selectedId) ? state.selectedId : vehicles.firstOrNull?.id);
    state = VehiclesState(vehicles: vehicles, selectedId: selected);
  }

  Future<void> select(String id) async {
    state = state.copyWith(selectedId: id);
    await LocalStore.instance.setSetting(_kSelected, id);
  }

  Future<Vehicle> addOrUpdate(Vehicle vehicle, {bool isNew = false}) async {
    final toSave = isNew
        ? vehicle.copyWith()
        : vehicle;
    await _repo.save(toSave);
    _reload(select: isNew ? toSave.id : state.selectedId);
    if (isNew) await LocalStore.instance.setSetting(_kSelected, toSave.id);
    return toSave;
  }

  /// Build a brand-new vehicle with a generated id and creation timestamp.
  Vehicle draft() => Vehicle(
        id: _uuid.v4(),
        brand: '',
        model: '',
        year: DateTime.now().year,
        isPrimary: state.vehicles.isEmpty,
        createdAt: DateTime.now(),
      );

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _reload();
  }

  Future<void> updateMileage(int mileage) async {
    final v = state.selected;
    if (v == null || mileage <= v.currentMileage) return;
    await addOrUpdate(v.copyWith(currentMileage: mileage));
  }
}

final vehiclesProvider = NotifierProvider<VehiclesNotifier, VehiclesState>(VehiclesNotifier.new);

final selectedVehicleProvider = Provider<Vehicle?>((ref) => ref.watch(vehiclesProvider).selected);
