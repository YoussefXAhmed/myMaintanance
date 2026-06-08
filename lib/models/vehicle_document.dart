import 'enums.dart';

/// A stored document (license, insurance, inspection, invoice, receipt). The
/// file lives in Firebase Storage (or a local path in offline mode); [fileUrl]
/// references it. [expiryDate] drives expiry reminders.
class VehicleDocument {
  const VehicleDocument({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.title,
    this.fileUrl,
    this.localPath,
    this.expiryDate,
    this.issueDate,
    this.notes = '',
    this.createdAt,
  });

  final String id;
  final String vehicleId;
  final DocumentType type;
  final String title;
  final String? fileUrl;
  final String? localPath;
  final DateTime? expiryDate;
  final DateTime? issueDate;
  final String notes;
  final DateTime? createdAt;

  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());

  VehicleDocument copyWith({
    DocumentType? type,
    String? title,
    String? fileUrl,
    String? localPath,
    DateTime? expiryDate,
    DateTime? issueDate,
    String? notes,
  }) =>
      VehicleDocument(
        id: id,
        vehicleId: vehicleId,
        type: type ?? this.type,
        title: title ?? this.title,
        fileUrl: fileUrl ?? this.fileUrl,
        localPath: localPath ?? this.localPath,
        expiryDate: expiryDate ?? this.expiryDate,
        issueDate: issueDate ?? this.issueDate,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'type': type.name,
        'title': title,
        'fileUrl': fileUrl,
        'localPath': localPath,
        'expiryDate': expiryDate?.toIso8601String(),
        'issueDate': issueDate?.toIso8601String(),
        'notes': notes,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory VehicleDocument.fromJson(Map<String, dynamic> j) => VehicleDocument(
        id: j['id'] as String,
        vehicleId: j['vehicleId'] as String,
        type: enumFromName(DocumentType.values, j['type'] as String?, DocumentType.invoice),
        title: (j['title'] as String?) ?? '',
        fileUrl: j['fileUrl'] as String?,
        localPath: j['localPath'] as String?,
        expiryDate: j['expiryDate'] != null ? DateTime.tryParse(j['expiryDate'] as String) : null,
        issueDate: j['issueDate'] != null ? DateTime.tryParse(j['issueDate'] as String) : null,
        notes: (j['notes'] as String?) ?? '',
        createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'] as String) : null,
      );
}
