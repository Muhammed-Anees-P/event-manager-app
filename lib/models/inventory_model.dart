class InventoryModel {
  final String id;
  final String itemName;
  final String category; // Furniture, Audio Visual, Lighting, Tableware
  final int quantity;
  final double rentalPrice;

  InventoryModel({
    required this.id,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.rentalPrice,
  });
}
