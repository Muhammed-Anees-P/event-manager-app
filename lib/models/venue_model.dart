class VenueModel {
  final String id;
  final String name;
  final String location;
  final int capacity;
  final double pricePerDay;
  final String contactPerson;
  bool isDeleted;

  VenueModel({
    required this.id,
    required this.name,
    required this.location,
    required this.capacity,
    required this.pricePerDay,
    required this.contactPerson,
    this.isDeleted = false,
  });
}
