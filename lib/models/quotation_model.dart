class QuotationModel {
  final String id;
  final String quoteNumber;
  final String customerName;
  final String eventType;
  final String date;
  final double totalAmount;
  final String status; // Draft, Sent, Accepted, Rejected

  QuotationModel({
    required this.id,
    required this.quoteNumber,
    required this.customerName,
    required this.eventType,
    required this.date,
    required this.totalAmount,
    this.status = 'Sent',
  });
}
