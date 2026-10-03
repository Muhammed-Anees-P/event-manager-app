class PaymentModel {
  final String id;
  final String date;
  final String eventType;
  final double amount;
  final String method;
  final String? customerName;
  bool isDeleted;

  PaymentModel({
    required this.id,
    required this.date,
    required this.eventType,
    required this.amount,
    required this.method,
    this.customerName,
    this.isDeleted = false,
  });
}
