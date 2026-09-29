class VendorModel {
  final String id;
  final String name;
  final String category; // Catering, Photography, Decor, Sound & Lighting, Florist
  final String phone;
  final String email;
  final String rating;

  VendorModel({
    required this.id,
    required this.name,
    required this.category,
    required this.phone,
    required this.email,
    required this.rating,
  });
}
