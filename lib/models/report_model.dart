class ReportModel {
  final String id;
  final String? imagePath;
  final String? location;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;

  const ReportModel({
    required this.id,
    this.imagePath,
    this.location,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'] as String,
      imagePath: map['image_path'] as String?,
      location: map['location'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: map['created_at'] is String
          ? DateTime.tryParse(map['created_at'] as String)
          : map['created_at'] as DateTime?,
    );
  }

  bool get hasCoordinates => latitude != null && longitude != null;
}

