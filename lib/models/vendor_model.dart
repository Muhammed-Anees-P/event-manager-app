class VendorModel {
  final String id;
  final String name;
  final String category;
  final String phone;
  final String email;
  final String rating;
  bool isDeleted;

  VendorModel({
    required this.id,
    required this.name,
    required this.category,
    required this.phone,
    required this.email,
    required this.rating,
    this.isDeleted = false,
  });
}
