class UserModel {
  final String? id;
  final String? email;

  const UserModel({
    this.id,
    this.email,
  });

  bool get isLoggedIn => id != null;
}
