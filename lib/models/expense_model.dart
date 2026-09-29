class ExpenseModel {
  final String id;
  final String title;
  final String category; // Logistics, Catering, Decor, Marketing, Equipment
  final double amount;
  final String date;
  final String paymentMethod;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.paymentMethod,
  });
}
