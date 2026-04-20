class DisposalBoxModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  const DisposalBoxModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory DisposalBoxModel.fromMap(Map<String, dynamic> map) {
    return DisposalBoxModel(
      id: map['id'].toString(),
      name: map['name'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }
}
