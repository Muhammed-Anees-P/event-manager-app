class CustomerModel {
  final String id;
  String name;
  String email;
  String phone;
  int totalEvents;
  bool isDeleted;

  CustomerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.totalEvents,
    this.isDeleted = false,
  });
}
