import 'enums.dart';

/// A single completed service for one [MaintenanceType] on a vehicle. The most
/// recent record per type defines the current maintenance state.
class MaintenanceRecord {
  const MaintenanceRecord({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.changeDate,
    required this.changeMileage,
    this.nextDueMileage,
    this.nextDueDate,
    this.cost = 0,
    this.notes = '',
    this.invoiceImages = const [],
    this.createdAt,
  });

  final String id;
  final String vehicleId;
  final MaintenanceType type;
  final DateTime changeDate;
  final int changeMileage;
  final int? nextDueMileage;
  final DateTime? nextDueDate;
  final double cost;
  final String notes;
  final List<String> invoiceImages;
  final DateTime? createdAt;

  MaintenanceRecord copyWith({
    MaintenanceType? type,
    DateTime? changeDate,
    int? changeMileage,
    int? nextDueMileage,
    DateTime? nextDueDate,
    double? cost,
    String? notes,
    List<String>? invoiceImages,
  }) =>
      MaintenanceRecord(
        id: id,
        vehicleId: vehicleId,
        type: type ?? this.type,
        changeDate: changeDate ?? this.changeDate,
        changeMileage: changeMileage ?? this.changeMileage,
        nextDueMileage: nextDueMileage ?? this.nextDueMileage,
        nextDueDate: nextDueDate ?? this.nextDueDate,
        cost: cost ?? this.cost,
        notes: notes ?? this.notes,
        invoiceImages: invoiceImages ?? this.invoiceImages,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'type': type.name,
        'changeDate': changeDate.toIso8601String(),
        'changeMileage': changeMileage,
        'nextDueMileage': nextDueMileage,
        'nextDueDate': nextDueDate?.toIso8601String(),
        'cost': cost,
        'notes': notes,
        'invoiceImages': invoiceImages,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory MaintenanceRecord.fromJson(Map<String, dynamic> j) => MaintenanceRecord(
        id: j['id'] as String,
        vehicleId: j['vehicleId'] as String,
        type: enumFromName(MaintenanceType.values, j['type'] as String?, MaintenanceType.engineOil),
        changeDate: DateTime.parse(j['changeDate'] as String),
        changeMileage: (j['changeMileage'] as num?)?.toInt() ?? 0,
        nextDueMileage: (j['nextDueMileage'] as num?)?.toInt(),
        nextDueDate: j['nextDueDate'] != null ? DateTime.tryParse(j['nextDueDate'] as String) : null,
        cost: (j['cost'] as num?)?.toDouble() ?? 0,
        notes: (j['notes'] as String?) ?? '',
        invoiceImages: (j['invoiceImages'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'] as String) : null,
      );
}
