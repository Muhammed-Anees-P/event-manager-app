import 'package:flutter/material.dart';

import '../models/customer_model.dart';
import '../models/enquiry_model.dart';
import '../models/event_model.dart';
import '../models/expense_model.dart';
import '../models/inventory_model.dart';
import '../models/invoice_model.dart';
import '../models/payment_model.dart';
import '../models/quotation_model.dart';
import '../models/task_model.dart';
import '../models/vendor_model.dart';
import '../models/venue_model.dart';

class AppDataRepository extends ChangeNotifier {
  // Singleton pattern for easy global access
  static final AppDataRepository instance = AppDataRepository._internal();
  AppDataRepository._internal();

  // -----------------------------
  // Data Lists (Local State)
  // -----------------------------

  List<EventModel> events = [
    const EventModel(
      id: '1',
      code: 'EVT-2026-001',
      title: 'Wedding - Rahul & Priya',
      date: '18 Sep 2026',
      time: '5:00 PM - 11:00 PM',
      venue: 'The Grand Palace',
      guests: 250,
      manager: 'Rahul',
      status: EventStatus.confirmed,
      contractValue: 558000,
      amountReceived: 400000,
    ),
    const EventModel(
      id: '2',
      code: 'EVT-2026-002',
      title: 'Corporate Annual Meet',
      date: '21 Sep 2026',
      time: '10:00 AM - 4:00 PM',
      venue: 'Haya Convention Center',
      guests: 120,
      manager: 'Sarah',
      status: EventStatus.planning,
      contractValue: 350000,
      amountReceived: 150000,
    ),
    const EventModel(
      id: '3',
      code: 'EVT-2026-003',
      title: 'Birthday - Aarav',
      date: '25 Sep 2026',
      time: '6:00 PM - 10:00 PM',
      venue: 'The Leela Resort',
      guests: 80,
      manager: 'Amit',
      status: EventStatus.confirmed,
      contractValue: 150000,
      amountReceived: 150000,
    ),
    const EventModel(
      id: '4',
      code: 'EVT-2026-004',
      title: 'Engagement - Neha & Karan',
      date: '28 Sep 2026',
      time: '4:00 PM - 9:00 PM',
      venue: 'Taj Mahal Palace',
      guests: 150,
      manager: 'Priya',
      status: EventStatus.completed,
      contractValue: 280000,
      amountReceived: 280000,
    ),
  ];

  List<TaskModel> tasks = [
    TaskModel(
      id: '1',
      title: 'Confirm venue booking',
      eventTitle: 'Wedding - Rahul & Priya',
      priority: TaskPriority.high,
      category: 'Today',
    ),
    TaskModel(
      id: '2',
      title: 'Call caterer',
      eventTitle: 'Corporate Annual Meet',
      priority: TaskPriority.high,
      category: 'Today',
    ),
    TaskModel(
      id: '3',
      title: 'Finalize decor theme',
      eventTitle: 'Birthday - Aarav',
      priority: TaskPriority.medium,
      category: 'Today',
    ),
    TaskModel(
      id: '4',
      title: 'Send invoice',
      eventTitle: 'Engagement - Neha & Karan',
      priority: TaskPriority.medium,
      category: 'Today',
    ),
    TaskModel(
      id: '5',
      title: 'Check equipment',
      eventTitle: 'Wedding - Rahul & Priya',
      priority: TaskPriority.low,
      category: 'Today',
    ),
  ];

  List<EnquiryModel> enquiries = [
    const EnquiryModel(
      id: '1',
      name: 'Sneha Kapoor',
      type: 'Wedding',
      totalDate: '12 Sep 2026',
      amount: 500000,
      status: EnquiryStatus.newEnquiry,
    ),
    const EnquiryModel(
      id: '2',
      name: 'ABC Technologies',
      type: 'Corporate',
      totalDate: '11 Sep 2026',
      amount: 350000,
      status: EnquiryStatus.quoted,
    ),
    const EnquiryModel(
      id: '3',
      name: 'Roshan Mehta',
      type: 'Engagement',
      totalDate: '10 Sep 2026',
      amount: 200000,
      status: EnquiryStatus.followUp,
    ),
    const EnquiryModel(
      id: '4',
      name: 'Priya Sharma',
      type: 'Birthday',
      totalDate: '09 Sep 2026',
      amount: 150000,
      status: EnquiryStatus.contacted,
    ),
  ];

  List<PaymentModel> payments = [
    const PaymentModel(
      id: '1',
      date: '10 Sep',
      eventType: 'Wedding',
      amount: 100000,
      method: 'UPI',
    ),
    const PaymentModel(
      id: '2',
      date: '08 Sep',
      eventType: 'Corporate',
      amount: 50000,
      method: 'Bank Transfer',
    ),
    const PaymentModel(
      id: '3',
      date: '05 Sep',
      eventType: 'Birthday',
      amount: 75000,
      method: 'Cash',
    ),
    const PaymentModel(
      id: '4',
      date: '01 Sep',
      eventType: 'Engagement',
      amount: 150000,
      method: 'UPI',
    ),
  ];

  List<CustomerModel> customers = [
    const CustomerModel(
      id: '1',
      name: 'Sneha Kapoor',
      email: 'sneha.k@example.com',
      phone: '+91 98765 43210',
      totalEvents: 2,
    ),
    const CustomerModel(
      id: '2',
      name: 'Rahul & Priya',
      email: 'rahul.p@example.com',
      phone: '+91 98765 12345',
      totalEvents: 1,
    ),
    const CustomerModel(
      id: '3',
      name: 'ABC Technologies',
      email: 'contact@abctech.com',
      phone: '+91 98111 22334',
      totalEvents: 3,
    ),
    const CustomerModel(
      id: '4',
      name: 'Roshan Mehta',
      email: 'roshan.m@example.com',
      phone: '+91 98222 33445',
      totalEvents: 1,
    ),
  ];

  List<QuotationModel> quotations = [
    QuotationModel(
      id: '1',
      quoteNumber: 'QT-2026-001',
      customerName: 'Sneha Kapoor',
      eventType: 'Wedding',
      date: '12 Sep 2026',
      totalAmount: 500000,
      status: 'Sent',
    ),
    QuotationModel(
      id: '2',
      quoteNumber: 'QT-2026-002',
      customerName: 'ABC Technologies',
      eventType: 'Corporate',
      date: '11 Sep 2026',
      totalAmount: 350000,
      status: 'Accepted',
    ),
  ];

  List<ExpenseModel> expenses = [
    ExpenseModel(
      id: '1',
      title: 'Floral Decor Vendor Payment',
      category: 'Decor',
      amount: 45000,
      date: '10 Sep 2026',
      paymentMethod: 'Bank Transfer',
    ),
    ExpenseModel(
      id: '2',
      title: 'Sound System Rental',
      category: 'Equipment',
      amount: 25000,
      date: '08 Sep 2026',
      paymentMethod: 'UPI',
    ),
  ];

  List<VendorModel> vendors = [
    VendorModel(
      id: '1',
      name: 'Royal Caterers',
      category: 'Catering',
      phone: '+91 98765 00011',
      email: 'royal@caterers.com',
      rating: '4.8 ⭐',
    ),
    VendorModel(
      id: '2',
      name: 'Pixel Perfect Studios',
      category: 'Photography',
      phone: '+91 98765 00022',
      email: 'info@pixelperfect.com',
      rating: '4.9 ⭐',
    ),
  ];

  List<VenueModel> venues = [
    VenueModel(
      id: '1',
      name: 'The Grand Palace',
      location: 'Central Avenue, Mumbai',
      capacity: 500,
      pricePerDay: 150000,
      contactPerson: 'Mr. Sharma',
    ),
    VenueModel(
      id: '2',
      name: 'Haya Convention Center',
      location: 'Tech Park, Bangalore',
      capacity: 300,
      pricePerDay: 100000,
      contactPerson: 'Ms. Anita',
    ),
  ];

  List<InventoryModel> inventory = [
    InventoryModel(
      id: '1',
      itemName: 'Gold Banquet Chairs',
      category: 'Furniture',
      quantity: 300,
      rentalPrice: 150,
    ),
    InventoryModel(
      id: '2',
      itemName: 'LED Stage Lights 500W',
      category: 'Lighting',
      quantity: 40,
      rentalPrice: 500,
    ),
  ];

  List<InvoiceModel> invoices = [
    InvoiceModel(
      invoiceNumber: 'INV-2026-001',
      customerName: 'Sneha Kapoor',
      venue: 'The Grand Palace, Mumbai',
      invoiceDate: '12 Sep 2026',
      dueDate: '25 Sep 2026',
      sections: [
        InvoiceSection(
          heading: 'Food & Catering',
          items: [
            InvoiceItem(name: 'Royal Buffet Spread', qty: 250, rate: 1200, price: 300000),
            InvoiceItem(name: 'Live Pasta Station', qty: 250, rate: 200, price: 50000),
          ],
        ),
        InvoiceSection(
          heading: 'Salads & Refreshments',
          items: [
            InvoiceItem(name: 'Exotic Salad Bar', qty: 250, rate: 100, price: 25000),
            InvoiceItem(name: 'High Tea & Mocktails', qty: 250, rate: 150, price: 37500),
          ],
        ),
      ],
      showDiscount: true,
      discountAmount: 5000,
      showTax: true,
      taxPercentage: 18,
      showAdvancePaid: true,
      advancePaid: 50000,
    ),
    InvoiceModel(
      invoiceNumber: 'INV-2026-002',
      customerName: 'ABC Technologies',
      venue: 'Haya Convention Center',
      invoiceDate: '10 Sep 2026',
      dueDate: '20 Sep 2026',
      sections: [
        InvoiceSection(
          heading: 'Corporate Catering & Audio Visual',
          items: [
            InvoiceItem(name: 'Executive Lunch Buffet', qty: 120, rate: 1500, price: 180000),
            InvoiceItem(name: 'LED Screen & Sound Rental', price: 70000),
          ],
        ),
      ],
      showDiscount: false,
      showTax: true,
      taxPercentage: 18,
      showAdvancePaid: true,
      advancePaid: 100000,
    ),
  ];

  // -----------------------------
  // Dynamic Calculated KPI Totals
  // -----------------------------

  int get totalEventsCount => events.length;

  double get totalRevenue => events.fold(0, (sum, item) => sum + item.amountReceived);

  double get totalOutstanding => events.fold(0, (sum, item) => sum + item.outstanding);

  double get totalProfit => totalRevenue - expenses.fold(0, (sum, item) => sum + item.amount);

  // -----------------------------
  // API Readiness Methods (CRUD)
  // -----------------------------

  Future<void> addEvent(EventModel item) async {
    // TODO: API Integration -> POST /api/events
    events.add(item);
    notifyListeners();
  }

  Future<void> addTask(TaskModel item) async {
    // TODO: API Integration -> POST /api/tasks
    tasks.add(item);
    notifyListeners();
  }

  Future<void> addEnquiry(EnquiryModel item) async {
    // TODO: API Integration -> POST /api/enquiries
    enquiries.add(item);
    notifyListeners();
  }

  Future<void> addCustomer(CustomerModel item) async {
    // TODO: API Integration -> POST /api/customers
    customers.add(item);
    notifyListeners();
  }

  Future<void> addPayment(PaymentModel item) async {
    // TODO: API Integration -> POST /api/payments
    payments.add(item);
    notifyListeners();
  }

  Future<void> addQuotation(QuotationModel item) async {
    // TODO: API Integration -> POST /api/quotations
    quotations.add(item);
    notifyListeners();
  }

  Future<void> addExpense(ExpenseModel item) async {
    // TODO: API Integration -> POST /api/expenses
    expenses.add(item);
    notifyListeners();
  }

  Future<void> addVendor(VendorModel item) async {
    // TODO: API Integration -> POST /api/vendors
    vendors.add(item);
    notifyListeners();
  }

  Future<void> addVenue(VenueModel item) async {
    // TODO: API Integration -> POST /api/venues
    venues.add(item);
    notifyListeners();
  }

  Future<void> addInventory(InventoryModel item) async {
    // TODO: API Integration -> POST /api/inventory
    inventory.add(item);
    notifyListeners();
  }

  Future<void> saveInvoice(InvoiceModel item) async {
    // TODO: API Integration -> POST/PUT /api/invoices
    final index = invoices.indexWhere((i) => i.invoiceNumber == item.invoiceNumber);
    if (index >= 0) {
      invoices[index] = item;
    } else {
      invoices.add(item);
    }
    notifyListeners();
  }

  Future<void> deleteInvoice(String invoiceNumber) async {
    // TODO: API Integration -> DELETE /api/invoices/:id
    invoices.removeWhere((i) => i.invoiceNumber == invoiceNumber);
    notifyListeners();
  }
}
