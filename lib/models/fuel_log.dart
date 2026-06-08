/// A single fuel fill-up entry.
class FuelLog {
  const FuelLog({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.odometer,
    required this.liters,
    required this.cost,
    this.station = '',
    this.fullTank = true,
    this.createdAt,
  });

  final String id;
  final String vehicleId;
  final DateTime date;
  final int odometer;
  final double liters;
  final double cost;
  final String station;
  final bool fullTank;
  final DateTime? createdAt;

  double get pricePerLiter => liters > 0 ? cost / liters : 0;

  FuelLog copyWith({
    DateTime? date,
    int? odometer,
    double? liters,
    double? cost,
    String? station,
    bool? fullTank,
  }) =>
      FuelLog(
        id: id,
        vehicleId: vehicleId,
        date: date ?? this.date,
        odometer: odometer ?? this.odometer,
        liters: liters ?? this.liters,
        cost: cost ?? this.cost,
        station: station ?? this.station,
        fullTank: fullTank ?? this.fullTank,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'date': date.toIso8601String(),
        'odometer': odometer,
        'liters': liters,
        'cost': cost,
        'station': station,
        'fullTank': fullTank,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory FuelLog.fromJson(Map<String, dynamic> j) => FuelLog(
        id: j['id'] as String,
        vehicleId: j['vehicleId'] as String,
        date: DateTime.parse(j['date'] as String),
        odometer: (j['odometer'] as num?)?.toInt() ?? 0,
        liters: (j['liters'] as num?)?.toDouble() ?? 0,
        cost: (j['cost'] as num?)?.toDouble() ?? 0,
        station: (j['station'] as String?) ?? '',
        fullTank: (j['fullTank'] as bool?) ?? true,
        createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'] as String) : null,
      );
}
