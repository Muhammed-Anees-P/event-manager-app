class PaymentModel {
  final String id;
  final String date;
  final String eventType;
  final double amount;
  final String method; // e.g. UPI, Bank Transfer, Cash

  const PaymentModel({
    required this.id,
    required this.date,
    required this.eventType,
    required this.amount,
    required this.method,
  });
}
