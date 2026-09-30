class SystemUserModel {
  final String id;
  final String username;
  final String email;
  final String role; // Admin, Manager, Accountant
  final String avatarUrl;

  SystemUserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.avatarUrl = '',
  });
}
