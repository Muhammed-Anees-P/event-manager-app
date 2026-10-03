class InventoryModel {
  final String id;
  final String itemName;
  final String category;
  final int quantity;
  final double rentalPrice;
  bool isDeleted;

  InventoryModel({
    required this.id,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.rentalPrice,
    this.isDeleted = false,
  });
}
