class SystemUserModel {
  final String id;
  String username;
  String email;
  String role;
  String avatarUrl;

  SystemUserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.avatarUrl = 'avatar_1',
  });
}
