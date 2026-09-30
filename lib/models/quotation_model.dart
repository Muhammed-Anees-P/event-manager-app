import 'invoice_model.dart';

class QuotationModel {
  String id;
  String quoteNumber;
  String customerName;
  String venue;
  String quotationDate;
  String dueDate;
  String eventType;
  List<InvoiceSection> sections;
  bool showDiscount;
  double discountAmount;
  bool showTax;
  double taxPercentage;
  bool showAdvancePaid;
  double advancePaid;
  String status;

  QuotationModel({
    required this.id,
    required this.quoteNumber,
    required this.customerName,
    required this.venue,
    required this.quotationDate,
    required this.dueDate,
    this.eventType = 'Wedding Event',
    required this.sections,
    this.showDiscount = false,
    this.discountAmount = 0.0,
    this.showTax = false,
    this.taxPercentage = 18.0,
    this.showAdvancePaid = false,
    this.advancePaid = 0.0,
    this.status = 'Sent',
  });

  double get rawSubtotal => sections.fold(0, (sum, section) => sum + section.subtotal);
  double get calculatedDiscount => showDiscount ? discountAmount : 0.0;
  double get subtotalAfterDiscount => (rawSubtotal - calculatedDiscount).clamp(0, double.infinity);
  double get calculatedTax => showTax ? (subtotalAfterDiscount * (taxPercentage / 100)) : 0.0;
  double get grandTotal => subtotalAfterDiscount + calculatedTax;
  double get totalAmount => grandTotal;
  double get calculatedAdvance => showAdvancePaid ? advancePaid : 0.0;
  double get balanceDue => (grandTotal - calculatedAdvance).clamp(0, double.infinity);
}
