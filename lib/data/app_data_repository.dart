import 'package:flutter/foundation.dart';

import '../models/app_notification_model.dart';
import '../models/customer_model.dart';
import '../models/enquiry_model.dart';
import '../models/event_model.dart';
import '../models/expense_model.dart';
import '../models/inventory_model.dart';
import '../models/invoice_model.dart';
import '../models/payment_model.dart';
import '../models/quotation_model.dart';
import '../models/system_user_model.dart';
import '../models/task_model.dart';
import '../models/vendor_model.dart';
import '../models/venue_model.dart';
import '../services/supabase_service.dart';

class AppDataRepository extends ChangeNotifier {
  static final AppDataRepository instance = AppDataRepository._internal();

  AppDataRepository._internal() {
    fetchAllFromSupabase();
  }

  bool get isOnline => SupabaseService.instance.isConfigured;

  // Active Logged-In User State
  String currentUserName = 'Anees';
  String currentUserEmail = 'anees@hayaevents.com';
  String currentUserAvatar = 'avatar_1';

  void setCurrentUser(String name, String email, {String avatar = 'avatar_1'}) {
    currentUserName = name;
    currentUserEmail = email;
    currentUserAvatar = avatar;
    notifyListeners();
  }

  // Company Settings State
  String companyName = 'Haya Event Management';
  String companyPhone = '+91 9747451938';
  String companyEmail = 'admin@hayaevents.com';
  String companyAddress = 'Central Avenue, Tech Park, Mumbai';
  String companyGstin = '27ABCDE1234F1Z5';

  Future<void> updateCompanySettings({
    required String name,
    required String phone,
    required String email,
    required String address,
    required String gstin,
  }) async {
    companyName = name;
    companyPhone = phone;
    companyEmail = email;
    companyAddress = address;
    companyGstin = gstin;
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('company_settings').upsert({
          'id': 'default',
          'company_name': name,
          'company_phone': phone,
          'company_email': email,
          'company_address': address,
          'company_gstin': gstin,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'id');
        if (kDebugMode) print('✅ Supabase company_settings upsert success!');
      } catch (e) {
        if (kDebugMode) print('❌ Supabase company_settings upsert error: $e');
      }
    }
  }

  // System Users List
  List<SystemUserModel> systemUsers = [
    SystemUserModel(id: '1', username: 'Anees', email: 'anees@hayaevents.com', role: 'Admin', avatarUrl: 'avatar_1'),
    SystemUserModel(id: '2', username: 'Mubeen', email: 'mubeen@hayaevents.com', role: 'Manager', avatarUrl: 'avatar_2'),
  ];

  void updateUserProfile(String id, {required String username, required String email, required String role, required String avatarUrl}) {
    final idx = systemUsers.indexWhere((u) => u.id == id);
    if (idx >= 0) {
      systemUsers[idx].username = username;
      systemUsers[idx].email = email;
      systemUsers[idx].role = role;
      systemUsers[idx].avatarUrl = avatarUrl;

      if (id == '1' || username.toLowerCase() == currentUserName.toLowerCase()) {
        currentUserName = username;
        currentUserEmail = email;
        currentUserAvatar = avatarUrl;
      }
      notifyListeners();
    }
  }

  // App Notifications Center
  List<AppNotificationModel> notifications = [
    AppNotificationModel(
      id: '1',
      title: 'Upcoming Event Reminder',
      message: 'Wedding - Rahul & Priya is scheduled for 18 Sep 2026 at The Grand Palace.',
      date: '12 Sep 2026',
      type: NotificationType.eventReminder,
    ),
    AppNotificationModel(
      id: '2',
      title: 'Payment Overdue Alert',
      message: 'Invoice #INV-2026-001 for Sneha Kapoor has an unpaid balance of ₹1,58,000.',
      date: '11 Sep 2026',
      type: NotificationType.paymentOverdue,
    ),
  ];

  int get unreadNotificationsCount => notifications.where((n) => !n.isRead).length;

  void markAllNotificationsAsRead() {
    for (var n in notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void addNotification(AppNotificationModel n) {
    notifications.insert(0, n);
    notifyListeners();
  }

  // Data Lists
  List<EventModel> events = [];
  List<TaskModel> tasks = [];
  List<EnquiryModel> enquiries = [];
  List<PaymentModel> payments = [];
  List<CustomerModel> customers = [];
  List<QuotationModel> quotations = [];
  List<ExpenseModel> expenses = [];
  List<VendorModel> vendors = [];
  List<VenueModel> venues = [];
  List<InventoryModel> inventory = [];
  List<InvoiceModel> invoices = [];

  bool isLoading = false;

  // Dynamic Calculated KPI Totals
  int get totalEventsCount => events.length;
  double get totalRevenue => events.fold(0, (sum, item) => sum + item.amountReceived);
  double get totalOutstanding => events.fold(0, (sum, item) => sum + item.outstanding);
  double get totalProfit => totalRevenue - expenses.fold(0, (sum, item) => sum + item.amount);

  // SUPABASE FULL API FETCH
  Future<void> fetchAllFromSupabase() async {
    final client = SupabaseService.instance.client;
    if (client == null) return;

    isLoading = true;
    notifyListeners();

    try {
      try {
        final companyData = await client.from('company_settings').select().eq('id', 'default').maybeSingle();
        if (companyData != null) {
          companyName = companyData['company_name'] ?? companyName;
          companyPhone = companyData['company_phone'] ?? companyPhone;
          companyEmail = companyData['company_email'] ?? companyEmail;
          companyAddress = companyData['company_address'] ?? companyAddress;
          companyGstin = companyData['company_gstin'] ?? companyGstin;
        }
      } catch (e) {
        if (kDebugMode) print('Supabase company_settings fetch error: $e');
      }

      final eventsData = await client.from('events').select().order('created_at', ascending: false);
      events = (eventsData as List).map((map) {
        return EventModel(
          id: map['id'].toString(),
          code: map['code'] ?? 'EVT-00',
          title: map['title'] ?? '',
          date: map['date'] ?? '',
          time: map['time'] ?? '',
          venue: map['venue'] ?? '',
          guests: map['guests'] ?? 0,
          manager: map['manager'] ?? 'Admin',
          status: _parseEventStatus(map['status']),
          contractValue: (map['contract_value'] as num?)?.toDouble() ?? 0.0,
          amountReceived: (map['amount_received'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      final tasksData = await client.from('tasks').select().order('created_at', ascending: false);
      tasks = (tasksData as List).map((map) {
        return TaskModel(
          id: map['id'].toString(),
          title: map['title'] ?? '',
          eventTitle: map['event_title'] ?? '',
          priority: _parseTaskPriority(map['priority']),
          isCompleted: map['is_completed'] ?? false,
          category: map['category'] ?? 'Today',
        );
      }).toList();

      final enquiriesData = await client.from('enquiries').select().order('created_at', ascending: false);
      enquiries = (enquiriesData as List).map((map) {
        return EnquiryModel(
          id: map['id'].toString(),
          name: map['name'] ?? '',
          type: map['type'] ?? '',
          totalDate: map['total_date'] ?? '',
          amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
          status: _parseEnquiryStatus(map['status']),
        );
      }).toList();

      final customersData = await client.from('customers').select().order('created_at', ascending: false);
      customers = (customersData as List).map((map) {
        return CustomerModel(
          id: map['id'].toString(),
          name: map['name'] ?? '',
          email: map['email'] ?? '',
          phone: map['phone'] ?? '',
          totalEvents: map['total_events'] ?? 0,
        );
      }).toList();

      final paymentsData = await client.from('payments').select().order('created_at', ascending: false);
      payments = (paymentsData as List).map((map) {
        return PaymentModel(
          id: map['id'].toString(),
          date: map['date'] ?? '',
          eventType: map['event_type'] ?? '',
          amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
          method: map['method'] ?? 'UPI',
        );
      }).toList();

      final quotationsData = await client.from('quotations').select().order('created_at', ascending: false);
      quotations = (quotationsData as List).map((map) {
        return QuotationModel(
          id: map['id'].toString(),
          quoteNumber: map['quote_number'] ?? '',
          customerName: map['customer_name'] ?? '',
          venue: map['venue'] ?? '',
          quotationDate: map['date'] ?? '',
          dueDate: map['due_date'] ?? '25 Sep 2026',
          sections: [],
          status: map['status'] ?? 'Sent',
        );
      }).toList();

      final expensesData = await client.from('expenses').select().order('created_at', ascending: false);
      expenses = (expensesData as List).map((map) {
        return ExpenseModel(
          id: map['id'].toString(),
          title: map['title'] ?? '',
          category: map['category'] ?? 'Decor',
          amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
          date: map['date'] ?? '',
          paymentMethod: map['payment_method'] ?? 'UPI',
        );
      }).toList();

      final vendorsData = await client.from('vendors').select().order('created_at', ascending: false);
      vendors = (vendorsData as List).map((map) {
        return VendorModel(
          id: map['id'].toString(),
          name: map['name'] ?? '',
          category: map['category'] ?? '',
          phone: map['phone'] ?? '',
          email: map['email'] ?? '',
          rating: map['rating'] ?? '5.0 ⭐',
        );
      }).toList();

      final venuesData = await client.from('venues').select().order('created_at', ascending: false);
      venues = (venuesData as List).map((map) {
        return VenueModel(
          id: map['id'].toString(),
          name: map['name'] ?? '',
          location: map['location'] ?? '',
          capacity: map['capacity'] ?? 0,
          pricePerDay: (map['price_per_day'] as num?)?.toDouble() ?? 0.0,
          contactPerson: map['contact_person'] ?? '',
        );
      }).toList();

      final inventoryData = await client.from('inventory').select().order('created_at', ascending: false);
      inventory = (inventoryData as List).map((map) {
        return InventoryModel(
          id: map['id'].toString(),
          itemName: map['item_name'] ?? '',
          category: map['category'] ?? '',
          quantity: map['quantity'] ?? 0,
          rentalPrice: (map['rental_price'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      final invoicesData = await client.from('invoices').select('*, invoice_sections(*, invoice_items(*))').order('created_at', ascending: false);
      invoices = (invoicesData as List).map((invMap) {
        final rawSections = invMap['invoice_sections'] as List? ?? [];
        final parsedSections = rawSections.map((secMap) {
          final rawItems = secMap['invoice_items'] as List? ?? [];
          final parsedItems = rawItems.map((itemMap) {
            return InvoiceItem(
              name: itemMap['name'] ?? '',
              qty: (itemMap['qty'] as num?)?.toDouble(),
              rate: (itemMap['rate'] as num?)?.toDouble(),
              price: (itemMap['price'] as num?)?.toDouble() ?? 0.0,
            );
          }).toList();

          return InvoiceSection(
            heading: secMap['heading'] ?? '',
            items: parsedItems,
          );
        }).toList();

        return InvoiceModel(
          invoiceNumber: invMap['invoice_number'] ?? '',
          customerName: invMap['customer_name'] ?? '',
          venue: invMap['venue'] ?? '',
          invoiceDate: invMap['invoice_date'] ?? '',
          dueDate: invMap['due_date'] ?? '',
          sections: parsedSections,
          showDiscount: invMap['show_discount'] ?? false,
          discountAmount: (invMap['discount_amount'] as num?)?.toDouble() ?? 0.0,
          showTax: invMap['show_tax'] ?? true,
          taxPercentage: (invMap['tax_percentage'] as num?)?.toDouble() ?? 18.0,
          showAdvancePaid: invMap['show_advance_paid'] ?? false,
          advancePaid: (invMap['advance_paid'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Supabase API Fetch Error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Parsers
  EventStatus _parseEventStatus(String? str) {
    if (str == 'confirmed') return EventStatus.confirmed;
    if (str == 'completed') return EventStatus.completed;
    if (str == 'cancelled') return EventStatus.cancelled;
    return EventStatus.planning;
  }

  TaskPriority _parseTaskPriority(String? str) {
    if (str == 'high') return TaskPriority.high;
    if (str == 'low') return TaskPriority.low;
    return TaskPriority.medium;
  }

  EnquiryStatus _parseEnquiryStatus(String? str) {
    if (str == 'quoted') return EnquiryStatus.quoted;
    if (str == 'followUp') return EnquiryStatus.followUp;
    if (str == 'contacted') return EnquiryStatus.contacted;
    return EnquiryStatus.newEnquiry;
  }

  // REAL API MUTATIONS
  Future<void> addEvent(EventModel item) async {
    events.insert(0, item);

    addNotification(
      AppNotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'New Event Scheduled',
        message: '${item.title} scheduled for ${item.date} at ${item.venue}.',
        date: item.date,
        type: NotificationType.eventReminder,
      ),
    );

    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('events').insert({
          'code': item.code,
          'title': item.title,
          'date': item.date,
          'time': item.time,
          'venue': item.venue,
          'guests': item.guests,
          'manager': item.manager,
          'status': item.status.name,
          'contract_value': item.contractValue,
          'amount_received': item.amountReceived,
        });
      } catch (e) {
        if (kDebugMode) print('Supabase addEvent Error: $e');
      }
    }
  }

  Future<void> updateEvent(EventModel item) async {
    final idx = events.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      events[idx] = item;
      notifyListeners();

      final client = SupabaseService.instance.client;
      if (client != null) {
        try {
          await client.from('events').update({
            'title': item.title,
            'date': item.date,
            'venue': item.venue,
            'status': item.status.name,
            'contract_value': item.contractValue,
            'amount_received': item.amountReceived,
          }).eq('id', item.id);
        } catch (e) {
          if (kDebugMode) print('Supabase updateEvent Error: $e');
        }
      }
    }
  }

  Future<void> deleteEvent(String id) async {
    events.removeWhere((e) => e.id == id);
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('events').delete().eq('id', id);
      } catch (e) {
        if (kDebugMode) print('Supabase deleteEvent Error: $e');
      }
    }
  }

  Future<void> addTask(TaskModel item) async {
    tasks.insert(0, item);
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('tasks').insert({
          'title': item.title,
          'event_title': item.eventTitle,
          'priority': item.priority.name,
          'is_completed': item.isCompleted,
          'category': item.category,
        });
      } catch (e) {
        if (kDebugMode) print('Supabase addTask Error: $e');
      }
    }
  }

  Future<void> addEnquiry(EnquiryModel item) async {
    enquiries.insert(0, item);
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('enquiries').insert({
          'name': item.name,
          'type': item.type,
          'total_date': item.totalDate,
          'amount': item.amount,
          'status': item.status.name,
        });
      } catch (e) {
        if (kDebugMode) print('Supabase addEnquiry Error: $e');
      }
    }
  }

  Future<void> updateEnquiry(EnquiryModel item) async {
    final idx = enquiries.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      enquiries[idx] = item;
      notifyListeners();

      final client = SupabaseService.instance.client;
      if (client != null) {
        try {
          await client.from('enquiries').update({
            'name': item.name,
            'type': item.type,
            'total_date': item.totalDate,
            'amount': item.amount,
            'status': item.status.name,
          }).eq('id', item.id);
        } catch (e) {
          if (kDebugMode) print('Supabase updateEnquiry Error: $e');
        }
      }
    }
  }

  Future<void> deleteEnquiry(String id) async {
    enquiries.removeWhere((e) => e.id == id);
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('enquiries').delete().eq('id', id);
      } catch (e) {
        if (kDebugMode) print('Supabase deleteEnquiry Error: $e');
      }
    }
  }

  Future<void> addCustomer(CustomerModel item) async {
    customers.insert(0, item);
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('customers').insert({
          'name': item.name,
          'email': item.email,
          'phone': item.phone,
          'total_events': item.totalEvents,
        });
      } catch (e) {
        if (kDebugMode) print('Supabase addCustomer Error: $e');
      }
    }
  }

  Future<void> addPayment(PaymentModel item) async {
    payments.insert(0, item);
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('payments').insert({
          'date': item.date,
          'event_type': item.eventType,
          'amount': item.amount,
          'method': item.method,
        });
      } catch (e) {
        if (kDebugMode) print('Supabase addPayment Error: $e');
      }
    }
  }

  Future<void> updatePayment(PaymentModel item) async {
    final idx = payments.indexWhere((p) => p.id == item.id);
    if (idx >= 0) {
      payments[idx] = item;
      notifyListeners();

      final client = SupabaseService.instance.client;
      if (client != null) {
        try {
          await client.from('payments').update({
            'date': item.date,
            'event_type': item.eventType,
            'amount': item.amount,
            'method': item.method,
          }).eq('id', item.id);
        } catch (e) {
          if (kDebugMode) print('Supabase updatePayment Error: $e');
        }
      }
    }
  }

  Future<void> deletePayment(String id) async {
    payments.removeWhere((p) => p.id == id);
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('payments').delete().eq('id', id);
      } catch (e) {
        if (kDebugMode) print('Supabase deletePayment Error: $e');
      }
    }
  }

  Future<void> addQuotation(QuotationModel item) async {
    quotations.insert(0, item);
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('quotations').insert({
          'quote_number': item.quoteNumber,
          'customer_name': item.customerName,
          'event_type': item.eventType,
          'date': item.date,
          'total_amount': item.totalAmount,
          'status': item.status,
        });
      } catch (e) {
        if (kDebugMode) print('Supabase addQuotation Error: $e');
      }
    }
  }

  Future<void> addExpense(ExpenseModel item) async {
    expenses.insert(0, item);
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('expenses').insert({
          'title': item.title,
          'category': item.category,
          'amount': item.amount,
          'date': item.date,
          'payment_method': item.paymentMethod,
        });
      } catch (e) {
        if (kDebugMode) print('Supabase addExpense Error: $e');
      }
    }
  }

  Future<void> addVendor(VendorModel item) async {
    vendors.insert(0, item);
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('vendors').insert({
          'name': item.name,
          'category': item.category,
          'phone': item.phone,
          'email': item.email,
          'rating': item.rating,
        });
      } catch (e) {
        if (kDebugMode) print('Supabase addVendor Error: $e');
      }
    }
  }

  Future<void> deleteVendor(String id) async {
    vendors.removeWhere((v) => v.id == id);
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('vendors').delete().eq('id', id);
      } catch (e) {
        if (kDebugMode) print('Supabase deleteVendor Error: $e');
      }
    }
  }

  Future<void> addVenue(VenueModel item) async {
    venues.insert(0, item);
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('venues').insert({
          'name': item.name,
          'location': item.location,
          'capacity': item.capacity,
          'price_per_day': item.pricePerDay,
          'contact_person': item.contactPerson,
        });
      } catch (e) {
        if (kDebugMode) print('Supabase addVenue Error: $e');
      }
    }
  }

  Future<void> deleteVenue(String id) async {
    venues.removeWhere((v) => v.id == id);
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('venues').delete().eq('id', id);
      } catch (e) {
        if (kDebugMode) print('Supabase deleteVenue Error: $e');
      }
    }
  }

  Future<void> addInventory(InventoryModel item) async {
    inventory.insert(0, item);
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('inventory').insert({
          'item_name': item.itemName,
          'category': item.category,
          'quantity': item.quantity,
          'rental_price': item.rentalPrice,
        });
      } catch (e) {
        if (kDebugMode) print('Supabase addInventory Error: $e');
      }
    }
  }

  Future<void> deleteInventory(String id) async {
    inventory.removeWhere((i) => i.id == id);
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('inventory').delete().eq('id', id);
      } catch (e) {
        if (kDebugMode) print('Supabase deleteInventory Error: $e');
      }
    }
  }

  Future<void> saveInvoice(InvoiceModel item) async {
    final index = invoices.indexWhere((i) => i.invoiceNumber == item.invoiceNumber);
    if (index >= 0) {
      invoices[index] = item;
    } else {
      invoices.insert(0, item);
    }

    if (item.balanceDue > 0) {
      addNotification(
        AppNotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Payment Overdue Alert',
          message: 'Invoice #${item.invoiceNumber} for ${item.customerName} has an unpaid balance of ₹${item.balanceDue.toStringAsFixed(0)}.',
          date: item.dueDate,
          type: NotificationType.paymentOverdue,
        ),
      );
    }

    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('invoices').upsert({
          'invoice_number': item.invoiceNumber,
          'customer_name': item.customerName,
          'venue': item.venue,
          'invoice_date': item.invoiceDate,
          'due_date': item.dueDate,
          'show_discount': item.showDiscount,
          'discount_amount': item.discountAmount,
          'show_tax': item.showTax,
          'tax_percentage': item.taxPercentage,
          'show_advance_paid': item.showAdvancePaid,
          'advance_paid': item.advancePaid,
        }, onConflict: 'invoice_number');

        await client.from('invoice_sections').delete().eq('invoice_number', item.invoiceNumber);

        for (int sIdx = 0; sIdx < item.sections.length; sIdx++) {
          final section = item.sections[sIdx];
          final secRes = await client.from('invoice_sections').insert({
            'invoice_number': item.invoiceNumber,
            'heading': section.heading,
            'section_order': sIdx,
          }).select().single();

          final String sectionId = secRes['id'].toString();

          for (final itemRow in section.items) {
            await client.from('invoice_items').insert({
              'section_id': sectionId,
              'name': itemRow.name,
              'qty': itemRow.qty,
              'rate': itemRow.rate,
              'price': itemRow.price,
            });
          }
        }
      } catch (e) {
        if (kDebugMode) print('Supabase saveInvoice Error: $e');
      }
    }
  }

  Future<void> deleteInvoice(String invoiceNumber) async {
    invoices.removeWhere((i) => i.invoiceNumber == invoiceNumber);
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('invoices').delete().eq('invoice_number', invoiceNumber);
      } catch (e) {
        if (kDebugMode) print('Supabase deleteInvoice Error: $e');
      }
    }
  }
}
