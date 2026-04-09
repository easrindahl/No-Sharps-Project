class UserModel {
  final String? id;
  final String? email;
  final int reportCount;
  final int pickupCount;
  final int totalPoints;

  const UserModel({
    this.id,
    this.email,
    this.reportCount = 0,
    this.pickupCount = 0,
    this.totalPoints = 0,
  });

  bool get isLoggedIn => id != null;

  UserModel copyWith({
    String? id,
    String? email,
    int? reportCount,
    int? pickupCount,
    int? totalPoints,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      reportCount: reportCount ?? this.reportCount,
      pickupCount: pickupCount ?? this.pickupCount,
      totalPoints: totalPoints ?? this.totalPoints,
    );
  }
}
