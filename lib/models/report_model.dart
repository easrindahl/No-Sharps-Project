class ReportModel {
  static const pickupStatusOpen = 'open';
  static const pickupStatusInProgress = 'in_progress';
  static const pickupStatusCompleted = 'completed';

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
    final pickupStatus = _normalizedStatus(
      map['pickup_status'] as String? ?? map['status'] as String?,
    );

    return ReportModel(
      id: map['id'].toString(),
      imagePath: map['image_path'] as String?,
      location: map['location'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: _parseDate(map['created_at']),
      status: pickupStatus,
      claimedBy:
          map['pickup_user_id']?.toString() ?? map['claimed_by']?.toString(),
      claimedAt: _parseDate(map['pickup_claimed_at'] ?? map['claimed_at']),
    );
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  bool get isOpen => status == pickupStatusOpen;
  bool get isInProgress => status == pickupStatusInProgress;
  bool get isCompleted => status == pickupStatusCompleted;

  static String _normalizedStatus(String? rawStatus) {
    final normalized = rawStatus?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return pickupStatusOpen;
    }
    return normalized;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
