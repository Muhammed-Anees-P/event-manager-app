class ExpenseModel {
  final String id;
  final String title;
  final String category;
  final double amount;
  final String date;
  final String paymentMethod;
  bool isDeleted;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    this.isDeleted = false,
  });
}
