class InvoiceItem {
  String name;
  double price;
  double? qty;
  double? rate;

  InvoiceItem({
    required this.name,
    required this.price,
    this.qty,
    this.rate,
  });

  void calculatePrice() {
    if (qty != null && rate != null && qty! > 0 && rate! > 0) {
      price = qty! * rate!;
    }
  }
}

class InvoiceSection {
  String heading;
  List<InvoiceItem> items;

  InvoiceSection({
    required this.heading,
    required this.items,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.price);
}

enum InvoiceStatus { pending, partiallyPaid, paid }

extension InvoiceStatusExtension on InvoiceStatus {
  String get displayName {
    switch (this) {
      case InvoiceStatus.pending:
        return 'Pending';
      case InvoiceStatus.partiallyPaid:
        return 'Partially Paid';
      case InvoiceStatus.paid:
        return 'Paid';
    }
  }
}

class InvoiceModel {
  String invoiceNumber;
  String customerName;
  String venue;
  String invoiceDate;
  String dueDate;
  List<InvoiceSection> sections;

  bool showDiscount;
  double discountAmount;

  bool showTax;
  double taxPercentage;

  bool showAdvancePaid;
  double advancePaid;

  InvoiceModel({
    required this.invoiceNumber,
    required this.customerName,
    required this.venue,
    required this.invoiceDate,
    required this.dueDate,
    required this.sections,
    this.showDiscount = false,
    this.discountAmount = 0.0,
    this.showTax = false,
    this.taxPercentage = 18.0,
    this.showAdvancePaid = false,
    this.advancePaid = 0.0,
  });

  double get rawSubtotal => sections.fold(0, (sum, section) => sum + section.subtotal);

  double get calculatedDiscount => showDiscount ? discountAmount : 0.0;

  double get subtotalAfterDiscount => (rawSubtotal - calculatedDiscount).clamp(0, double.infinity);

  double get calculatedTax => showTax ? (subtotalAfterDiscount * (taxPercentage / 100)) : 0.0;

  double get grandTotal => subtotalAfterDiscount + calculatedTax;

  double get calculatedAdvance => showAdvancePaid ? advancePaid : 0.0;

  double get balanceDue => (grandTotal - calculatedAdvance).clamp(0, double.infinity);

  InvoiceStatus get status {
    if (!showAdvancePaid || calculatedAdvance <= 0) return InvoiceStatus.pending;
    if (calculatedAdvance >= grandTotal) return InvoiceStatus.paid;
    return InvoiceStatus.partiallyPaid;
  }
}
