import 'enums.dart';

/// A vehicle in the user's garage. Insurance / license / inspection dates live
/// here so expiry reminders and the health score can read them directly.
class Vehicle {
  const Vehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    this.trim = '',
    this.engine = '',
    this.fuelType = FuelType.petrol,
    this.transmission = TransmissionType.automatic,
    this.plateNumber = '',
    this.vin = '',
    this.currentMileage = 0,
    this.imageUrl,
    this.colorHex,
    this.insuranceExpiry,
    this.licenseExpiry,
    this.inspectionDate,
    this.isPrimary = false,
    this.createdAt,
  });

  final String id;
  final String brand;
  final String model;
  final int year;
  final String trim;
  final String engine;
  final FuelType fuelType;
  final TransmissionType transmission;
  final String plateNumber;
  final String vin;
  final int currentMileage;
  final String? imageUrl;
  final String? colorHex;
  final DateTime? insuranceExpiry;
  final DateTime? licenseExpiry;
  final DateTime? inspectionDate;
  final bool isPrimary;
  final DateTime? createdAt;

  String get title => '$brand $model';
  String get subtitle => [year.toString(), if (trim.isNotEmpty) trim].join(' • ');

  Vehicle copyWith({
    String? brand,
    String? model,
    int? year,
    String? trim,
    String? engine,
    FuelType? fuelType,
    TransmissionType? transmission,
    String? plateNumber,
    String? vin,
    int? currentMileage,
    String? imageUrl,
    String? colorHex,
    DateTime? insuranceExpiry,
    DateTime? licenseExpiry,
    DateTime? inspectionDate,
    bool? isPrimary,
  }) =>
      Vehicle(
        id: id,
        brand: brand ?? this.brand,
        model: model ?? this.model,
        year: year ?? this.year,
        trim: trim ?? this.trim,
        engine: engine ?? this.engine,
        fuelType: fuelType ?? this.fuelType,
        transmission: transmission ?? this.transmission,
        plateNumber: plateNumber ?? this.plateNumber,
        vin: vin ?? this.vin,
        currentMileage: currentMileage ?? this.currentMileage,
        imageUrl: imageUrl ?? this.imageUrl,
        colorHex: colorHex ?? this.colorHex,
        insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
        licenseExpiry: licenseExpiry ?? this.licenseExpiry,
        inspectionDate: inspectionDate ?? this.inspectionDate,
        isPrimary: isPrimary ?? this.isPrimary,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'model': model,
        'year': year,
        'trim': trim,
        'engine': engine,
        'fuelType': fuelType.name,
        'transmission': transmission.name,
        'plateNumber': plateNumber,
        'vin': vin,
        'currentMileage': currentMileage,
        'imageUrl': imageUrl,
        'colorHex': colorHex,
        'insuranceExpiry': insuranceExpiry?.toIso8601String(),
        'licenseExpiry': licenseExpiry?.toIso8601String(),
        'inspectionDate': inspectionDate?.toIso8601String(),
        'isPrimary': isPrimary,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        id: j['id'] as String,
        brand: (j['brand'] as String?) ?? '',
        model: (j['model'] as String?) ?? '',
        year: (j['year'] as num?)?.toInt() ?? DateTime.now().year,
        trim: (j['trim'] as String?) ?? '',
        engine: (j['engine'] as String?) ?? '',
        fuelType: enumFromName(FuelType.values, j['fuelType'] as String?, FuelType.petrol),
        transmission:
            enumFromName(TransmissionType.values, j['transmission'] as String?, TransmissionType.automatic),
        plateNumber: (j['plateNumber'] as String?) ?? '',
        vin: (j['vin'] as String?) ?? '',
        currentMileage: (j['currentMileage'] as num?)?.toInt() ?? 0,
        imageUrl: j['imageUrl'] as String?,
        colorHex: j['colorHex'] as String?,
        insuranceExpiry: _date(j['insuranceExpiry']),
        licenseExpiry: _date(j['licenseExpiry']),
        inspectionDate: _date(j['inspectionDate']),
        isPrimary: (j['isPrimary'] as bool?) ?? false,
        createdAt: _date(j['createdAt']),
      );

  static DateTime? _date(Object? v) => v == null ? null : DateTime.tryParse(v as String);
}
