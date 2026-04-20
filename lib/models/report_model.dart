class ReportModel {
  final String id;
  final String? imagePath;
  final String? location;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final String status;
  final String? claimedBy;
  final DateTime? claimedAt;

  const ReportModel({
    required this.id,
    this.imagePath,
    this.location,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.status = 'open',
    this.claimedBy,
    this.claimedAt,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'].toString(),
      imagePath: map['image_path'] as String?,
      location: map['location'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: _parseDate(map['created_at']),
      status: (map['status'] as String?)?.trim().toLowerCase().isNotEmpty == true
          ? (map['status'] as String).trim().toLowerCase()
          : 'open',
      claimedBy: map['claimed_by']?.toString(),
      claimedAt: _parseDate(map['claimed_at']),
    );
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  bool get isOpen => status == 'open';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
