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
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../utils/date_formatter.dart';

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
  List<AppNotificationModel> notifications = [];

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

  // Raw Data Lists
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

  InvoiceModel? draftInvoice;
  QuotationModel? draftQuotation;

  void saveInvoiceDraft(InvoiceModel inv) {
    draftInvoice = inv;
    notifyListeners();
  }

  void saveQuotationDraft(QuotationModel quo) {
    draftQuotation = quo;
    notifyListeners();
  }

  void clearInvoiceDraft() {
    draftInvoice = null;
    notifyListeners();
  }

  void clearQuotationDraft() {
    draftQuotation = null;
    notifyListeners();
  }

  // Active Non-Soft-Deleted Entity Getters
  List<EventModel> get activeEvents => events.where((e) => !e.isDeleted).toList();
  List<TaskModel> get activeTasks => tasks.where((t) => !t.isDeleted).toList();
  List<EnquiryModel> get activeEnquiries => enquiries.where((e) => !e.isDeleted).toList();
  List<CustomerModel> get activeCustomers => customers.where((c) => !c.isDeleted).toList();
  List<PaymentModel> get activePayments => payments.where((p) => !p.isDeleted).toList();
  List<QuotationModel> get activeQuotations => quotations.where((q) => !q.isDeleted).toList();
  List<ExpenseModel> get activeExpenses => expenses.where((e) => !e.isDeleted).toList();
  List<VendorModel> get activeVendors => vendors.where((v) => !v.isDeleted).toList();
  List<VenueModel> get activeVenues => venues.where((v) => !v.isDeleted).toList();
  List<InventoryModel> get activeInventory => inventory.where((i) => !i.isDeleted).toList();
  List<InvoiceModel> get activeInvoices => invoices.where((i) => !i.isDeleted).toList();

  bool isLoading = false;

  // Dynamic Calculated KPI Totals
  int get totalEventsCount => activeEvents.length;

  double get totalPaymentsCollected => activePayments.fold(0.0, (sum, item) => sum + item.amount);

  double get totalRevenue {
    final double paymentsSum = totalPaymentsCollected;
    final double eventsSum = activeEvents.fold(0.0, (sum, item) => sum + item.amountReceived);
    return paymentsSum > eventsSum ? paymentsSum : eventsSum;
  }

  double get totalOutstanding => activeEvents.fold(0.0, (sum, item) => sum + item.outstanding);
  double get totalProfit => totalRevenue - activeExpenses.fold(0.0, (sum, item) => sum + item.amount);

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
          isDeleted: map['is_deleted'] ?? false,
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
          isDeleted: map['is_deleted'] ?? false,
        );
      }).toList();

      final enquiriesData = await client.from('enquiries').select().order('created_at', ascending: false);
      enquiries = (enquiriesData as List).map((map) {
        return EnquiryModel(
          id: map['id'].toString(),
          name: map['name'] ?? '',
          phone: map['phone'] ?? '',
          type: map['type'] ?? '',
          totalDate: map['total_date'] ?? '',
          amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
          status: _parseEnquiryStatus(map['status']),
          isDeleted: map['is_deleted'] ?? false,
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
          isDeleted: map['is_deleted'] ?? false,
        );
      }).toList();

      final paymentsData = await client.from('payments').select().order('created_at', ascending: false);
      final fetchedPayments = (paymentsData as List).map((map) {
        return PaymentModel(
          id: map['id'].toString(),
          date: map['date'] ?? '',
          eventType: map['event_type'] ?? '',
          amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
          method: map['method'] ?? 'UPI',
          isDeleted: map['is_deleted'] ?? false,
        );
      }).toList();

      for (var localP in payments) {
        if (!fetchedPayments.any((fp) => fp.id == localP.id || (fp.eventType == localP.eventType && fp.amount == localP.amount))) {
          fetchedPayments.add(localP);
        }
      }
      payments = fetchedPayments;

      final quotationsData = await client.from('quotations').select('*, quotation_sections(*, quotation_items(*))').order('created_at', ascending: false);
      quotations = (quotationsData as List).map((map) {
        final rawSections = map['quotation_sections'] as List? ?? [];
        final parsedSections = rawSections.map((secMap) {
          final rawItems = secMap['quotation_items'] as List? ?? [];
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

        final double dbTotalAmount = (map['total_amount'] as num? ?? 0).toDouble();
        if (parsedSections.isEmpty && dbTotalAmount > 0) {
          parsedSections.add(
            InvoiceSection(
              heading: 'Event Services',
              items: [
                InvoiceItem(
                  name: map['event_type'] ?? 'Quotation Package',
                  price: dbTotalAmount,
                ),
              ],
            ),
          );
        }

        final sanitizedSections = sanitizeInvoiceSections(parsedSections);

        return QuotationModel(
          id: map['id'].toString(),
          quoteNumber: map['quote_number'] ?? '',
          customerName: map['customer_name'] ?? '',
          venue: map['venue'] ?? '',
          quotationDate: map['date'] ?? '',
          dueDate: map['due_date'] ?? '25 Sep 2026',
          eventType: map['event_type'] ?? 'Wedding Event',
          sections: sanitizedSections,
          showDiscount: map['show_discount'] ?? false,
          discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
          showTax: map['show_tax'] ?? false,
          taxPercentage: (map['tax_percentage'] as num?)?.toDouble() ?? 18.0,
          showAdvancePaid: map['show_advance_paid'] ?? false,
          advancePaid: (map['advance_paid'] as num?)?.toDouble() ?? 0.0,
          manualTotalOverride: map['manual_total_override'] ?? false,
          manualGrandTotal: (map['manual_grand_total'] as num?)?.toDouble() ?? 0.0,
          status: map['status'] ?? 'Sent',
          isDeleted: map['is_deleted'] ?? false,
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
          isDeleted: map['is_deleted'] ?? false,
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
          isDeleted: map['is_deleted'] ?? false,
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
          isDeleted: map['is_deleted'] ?? false,
        );
      }).toList();

      final inventoryData = await client.from('inventory').select().order('created_at', ascending: false);
      inventory = (inventoryData as List).map((map) {
        return InventoryModel(
          id: map['id'].toString(),
          itemName: map['item_name'] ?? '',
          category: map['category'] ?? '',
          quantity: map['quantity'] ?? 0,
          rentalPrice: (map['rental_price'] as num?)?.toDouble() ?? (map['rentalPrice'] as num?)?.toDouble() ?? 0.0,
          isDeleted: map['is_deleted'] ?? false,
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

        final double dbInvoiceTotal = (invMap['total_amount'] as num? ?? 0).toDouble();
        if (parsedSections.isEmpty && dbInvoiceTotal > 0) {
          parsedSections.add(
            InvoiceSection(
              heading: 'Event Services',
              items: [
                InvoiceItem(
                  name: 'Invoice Services',
                  price: dbInvoiceTotal,
                ),
              ],
            ),
          );
        }

        final sanitizedSections = sanitizeInvoiceSections(parsedSections);

        return InvoiceModel(
          invoiceNumber: invMap['invoice_number'] ?? '',
          customerName: invMap['customer_name'] ?? '',
          venue: invMap['venue'] ?? '',
          invoiceDate: invMap['invoice_date'] ?? '',
          dueDate: invMap['due_date'] ?? '',
          showDueDate: invMap['show_due_date'] ?? true,
          sections: sanitizedSections,
          showDiscount: invMap['show_discount'] ?? false,
          discountAmount: (invMap['discount_amount'] as num?)?.toDouble() ?? 0.0,
          showTax: invMap['show_tax'] ?? true,
          taxPercentage: (invMap['tax_percentage'] as num?)?.toDouble() ?? 18.0,
          showAdvancePaid: invMap['show_advance_paid'] ?? false,
          advancePaid: (invMap['advance_paid'] as num?)?.toDouble() ?? 0.0,
          manualTotalOverride: invMap['manual_total_override'] ?? false,
          manualGrandTotal: (invMap['manual_grand_total'] as num?)?.toDouble() ?? 0.0,
          isDeleted: invMap['is_deleted'] ?? false,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Supabase API Fetch Error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
      NotificationService.instance.checkForAutomatedSystemNotifications();
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

    final notifTitle = 'New Event Scheduled';
    final notifBody = '${item.title} scheduled for ${item.date} at ${item.venue}.';
    addNotification(
      AppNotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: notifTitle,
        message: notifBody,
        date: item.date,
        type: NotificationType.eventReminder,
      ),
    );
    NotificationService.instance.showLocalPushNotification(title: notifTitle, body: notifBody);

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
          'is_deleted': false,
        });
      } catch (e) {
        if (kDebugMode) print('Supabase addEvent Error: $e');
      }
    }
  }

  Future<void> updateEvent(EventModel item) async {
    final idx = events.indexWhere((e) => e.id == item.id || e.code == item.code);
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
            'is_deleted': item.isDeleted,
          }).eq('code', item.code);
        } catch (e) {
          if (kDebugMode) print('Supabase updateEvent Error: $e');
        }
      }
    }
  }

  Future<void> deleteEvent(String id) async {
    final idx = events.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      events[idx].isDeleted = true;
      notifyListeners();

      final client = SupabaseService.instance.client;
      if (client != null) {
        try {
          await client.from('events').update({'is_deleted': true}).eq('code', events[idx].code);
        } catch (e) {
          if (kDebugMode) print('Supabase soft deleteEvent Error: $e');
        }
      }
    }
  }

  Future<void> addTask(TaskModel item) async {
    tasks.insert(0, item);

    if (item.priority == TaskPriority.high) {
      final notifTitle = 'High Priority Task Created';
      final notifBody = 'Task "${item.title}" assigned for ${item.eventTitle} requires immediate attention!';
      addNotification(
        AppNotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: notifTitle,
          message: notifBody,
          date: AppDateUtils.getTodayDate(),
          type: NotificationType.eventReminder,
        ),
      );
      NotificationService.instance.showLocalPushNotification(title: notifTitle, body: notifBody);
    }

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
          'is_deleted': false,
        });
      } catch (e) {
        if (kDebugMode) print('Supabase addTask Error: $e');
      }
    }
  }

  Future<void> deleteTask(String id) async {
    final idx = tasks.indexWhere((t) => t.id == id);
    if (idx >= 0) {
      tasks[idx].isDeleted = true;
      notifyListeners();
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
          'phone': item.phone,
          'type': item.type,
          'total_date': item.totalDate,
          'amount': item.amount,
          'status': item.status.name,
          'is_deleted': false,
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
            'phone': item.phone,
            'type': item.type,
            'total_date': item.totalDate,
            'amount': item.amount,
            'status': item.status.name,
            'is_deleted': item.isDeleted,
          }).eq('id', item.id);
        } catch (e) {
          if (kDebugMode) print('Supabase updateEnquiry Error: $e');
        }
      }
    }
  }

  Future<void> deleteEnquiry(String id) async {
    final idx = enquiries.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      enquiries[idx].isDeleted = true;
      notifyListeners();

      final client = SupabaseService.instance.client;
      if (client != null) {
        try {
          await client.from('enquiries').update({'is_deleted': true}).eq('id', id);
        } catch (e) {
          if (kDebugMode) print('Supabase soft deleteEnquiry Error: $e');
        }
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
          'is_deleted': false,
        });
      } catch (e) {
        if (kDebugMode) print('Supabase addCustomer Error: $e');
      }
    }
  }

  Future<void> updateCustomer(CustomerModel item) async {
    final idx = customers.indexWhere((c) => c.id == item.id);
    if (idx >= 0) {
      customers[idx] = item;
      notifyListeners();

      final client = SupabaseService.instance.client;
      if (client != null) {
        try {
          await client.from('customers').update({
            'name': item.name,
            'email': item.email,
            'phone': item.phone,
            'is_deleted': item.isDeleted,
          }).eq('id', item.id);
        } catch (e) {
          if (kDebugMode) print('Supabase updateCustomer Error: $e');
        }
      }
    }
  }

  Future<void> deleteCustomer(String id) async {
    final idx = customers.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      customers[idx].isDeleted = true;
      notifyListeners();

      final client = SupabaseService.instance.client;
      if (client != null) {
        try {
          await client.from('customers').update({'is_deleted': true}).eq('id', id);
        } catch (e) {
          if (kDebugMode) print('Supabase soft deleteCustomer Error: $e');
        }
      }
    }
  }

  Future<void> addPayment(PaymentModel item) async {
    payments.insert(0, item);

    final notifTitle = 'Payment Received';
    final notifBody = 'Payment of ₹${item.amount.toStringAsFixed(0)} received for ${item.eventType} via ${item.method}.';
    addNotification(
      AppNotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: notifTitle,
        message: notifBody,
        date: item.date,
        type: NotificationType.paymentOverdue,
      ),
    );
    NotificationService.instance.showLocalPushNotification(title: notifTitle, body: notifBody);

    final searchName = item.eventType.toLowerCase().trim();
    for (var event in activeEvents) {
      final mgr = event.manager.toLowerCase().trim();
      final title = event.title.toLowerCase().trim();
      if (mgr.contains(searchName) || searchName.contains(mgr) || title.contains(searchName) || searchName.contains(title)) {
        event.amountReceived += item.amount;
        if (event.amountReceived >= event.contractValue && event.contractValue > 0) {
          event.status = EventStatus.completed;
        } else if (event.amountReceived > 0 && event.status == EventStatus.planning) {
          event.status = EventStatus.confirmed;
        }
        updateEvent(event);
      }
    }

    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('payments').insert({
          'date': item.date,
          'event_type': item.eventType,
          'amount': item.amount,
          'method': item.method,
          'is_deleted': false,
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
            'is_deleted': item.isDeleted,
          }).eq('id', item.id);
        } catch (e) {
          if (kDebugMode) print('Supabase updatePayment Error: $e');
        }
      }
    }
  }

  Future<void> deletePayment(String id) async {
    final idx = payments.indexWhere((p) => p.id == id);
    if (idx >= 0) {
      payments[idx].isDeleted = true;
      notifyListeners();

      final client = SupabaseService.instance.client;
      if (client != null) {
        try {
          await client.from('payments').update({'is_deleted': true}).eq('id', id);
        } catch (e) {
          if (kDebugMode) print('Supabase soft deletePayment Error: $e');
        }
      }
    }
  }

  List<InvoiceSection> sanitizeInvoiceSections(List<InvoiceSection> rawSections) {
    if (rawSections.isEmpty) return [];

    final List<InvoiceSection> cleanedSections = [];

    for (final sec in rawSections) {
      final heading = sec.heading.trim();
      final existingSecIdx = cleanedSections.indexWhere(
        (s) => s.heading.trim().toLowerCase() == heading.toLowerCase(),
      );

      if (existingSecIdx >= 0) {
        final existingSec = cleanedSections[existingSecIdx];
        for (final item in sec.items) {
          final isDup = item.name.trim().isNotEmpty &&
              existingSec.items.any((existing) =>
                  existing.name.trim().toLowerCase() == item.name.trim().toLowerCase() &&
                  existing.price == item.price &&
                  existing.qty == item.qty &&
                  existing.rate == item.rate);

          if (!isDup) {
            existingSec.items.add(InvoiceItem(
              name: item.name,
              qty: item.qty,
              rate: item.rate,
              price: item.price,
            ));
          }
        }
      } else {
        final List<InvoiceItem> cleanedItems = [];
        for (final item in sec.items) {
          final isDup = item.name.trim().isNotEmpty &&
              cleanedItems.any((existing) =>
                  existing.name.trim().toLowerCase() == item.name.trim().toLowerCase() &&
                  existing.price == item.price &&
                  existing.qty == item.qty &&
                  existing.rate == item.rate);

          if (!isDup) {
            cleanedItems.add(InvoiceItem(
              name: item.name,
              qty: item.qty,
              rate: item.rate,
              price: item.price,
            ));
          }
        }

        cleanedSections.add(InvoiceSection(
          heading: heading.isNotEmpty ? heading : 'Event Services',
          items: cleanedItems,
        ));
      }
    }

    return cleanedSections;
  }

  Future<void> saveQuotation(QuotationModel item) async {
    item.sections = sanitizeInvoiceSections(item.sections);
    final idx = quotations.indexWhere((q) => q.id == item.id || q.quoteNumber == item.quoteNumber);
    if (idx >= 0) {
      quotations[idx] = item;
    } else {
      quotations.insert(0, item);
    }
    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        final Map<String, dynamic> payload = {
          'quote_number': item.quoteNumber,
          'customer_name': item.customerName,
          'venue': item.venue,
          'date': item.date,
          'due_date': item.dueDate,
          'event_type': item.eventType,
          'show_discount': item.showDiscount,
          'discount_amount': item.discountAmount,
          'show_tax': item.showTax,
          'tax_percentage': item.taxPercentage,
          'show_advance_paid': item.showAdvancePaid,
          'advance_paid': item.advancePaid,
          'manual_total_override': item.manualTotalOverride,
          'manual_grand_total': item.manualGrandTotal,
          'total_amount': item.totalAmount,
          'status': item.status,
          'is_deleted': item.isDeleted,
        };

        bool quotationUpsertSucceeded = false;
        try {
          await client.from('quotations').upsert(payload, onConflict: 'quote_number');
          quotationUpsertSucceeded = true;
        } catch (e) {
          if (kDebugMode) print('Supabase saveQuotation full payload error: $e');
          try {
            // Stage 2: Try without 'venue' in case 'venue' column is missing in user table
            final Map<String, dynamic> payloadNoVenue = Map.from(payload)..remove('venue');
            await client.from('quotations').upsert(payloadNoVenue, onConflict: 'quote_number');
            quotationUpsertSucceeded = true;
          } catch (e2) {
            if (kDebugMode) print('Supabase saveQuotation payload without venue error: $e2');
            try {
              // Stage 3: Minimal fallback satisfying mandatory NOT NULL constraints (quote_number, customer_name, event_type, date)
              await client.from('quotations').upsert({
                'quote_number': item.quoteNumber,
                'customer_name': item.customerName,
                'event_type': item.eventType.isNotEmpty ? item.eventType : 'Wedding Event',
                'date': item.date,
                'status': item.status,
              }, onConflict: 'quote_number');
              quotationUpsertSucceeded = true;
            } catch (fallbackErr) {
              if (kDebugMode) print('Supabase saveQuotation minimal fallback error: $fallbackErr');
            }
          }
        }

        if (!quotationUpsertSucceeded) {
          if (kDebugMode) print('Supabase saveQuotation: Skipping sections insert due to parent record upsert failure.');
          return;
        }

        try {
          final existingSecs = await client
              .from('quotation_sections')
              .select('id')
              .eq('quote_number', item.quoteNumber);
          if (existingSecs != null && (existingSecs as List).isNotEmpty) {
            for (final s in existingSecs as List) {
              final sid = s['id']?.toString();
              if (sid != null && sid.isNotEmpty) {
                await client.from('quotation_items').delete().eq('section_id', sid);
              }
            }
          }
        } catch (e) {
          if (kDebugMode) print('Supabase delete quotation_items error: $e');
        }

        try {
          await client.from('quotation_sections').delete().eq('quote_number', item.quoteNumber);
        } catch (e) {
          if (kDebugMode) print('Supabase delete quotation_sections error: $e');
        }

        for (int sIdx = 0; sIdx < item.sections.length; sIdx++) {
          final section = item.sections[sIdx];
          final secRes = await client.from('quotation_sections').insert({
            'quote_number': item.quoteNumber,
            'heading': section.heading,
            'section_order': sIdx,
          }).select('id').single();

          final String sectionId = secRes['id']?.toString() ?? '';
          if (sectionId.isEmpty) continue;

          final List<Map<String, dynamic>> itemsPayload = section.items.map((itemRow) {
            return {
              'section_id': sectionId,
              'name': itemRow.name,
              'qty': itemRow.qty,
              'rate': itemRow.rate,
              'price': itemRow.price,
            };
          }).toList();

          if (itemsPayload.isNotEmpty) {
            try {
              await client.from('quotation_items').insert(itemsPayload);
            } catch (itemErr) {
              if (kDebugMode) print('Supabase quotation_items insert warning: $itemErr');
            }
          }
        }
      } catch (e) {
        if (kDebugMode) print('Supabase saveQuotation Error: $e');
      }
    }
  }

  Future<void> deleteQuotation(String id) async {
    final idx = quotations.indexWhere((q) => q.id == id || q.quoteNumber == id);
    if (idx >= 0) {
      quotations[idx].isDeleted = true;
      notifyListeners();

      final client = SupabaseService.instance.client;
      if (client != null) {
        try {
          await client.from('quotations').update({'is_deleted': true}).eq('quote_number', quotations[idx].quoteNumber);
        } catch (e) {
          if (kDebugMode) print('Supabase soft deleteQuotation Error: $e');
        }
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
          'is_deleted': false,
        });
      } catch (e) {
        if (kDebugMode) print('Supabase addExpense Error: $e');
      }
    }
  }

  Future<void> deleteExpense(String id) async {
    final idx = expenses.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      expenses[idx].isDeleted = true;
      notifyListeners();
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
          'is_deleted': false,
        });
      } catch (e) {
        if (kDebugMode) print('Supabase addVendor Error: $e');
      }
    }
  }

  Future<void> deleteVendor(String id) async {
    final idx = vendors.indexWhere((v) => v.id == id);
    if (idx >= 0) {
      vendors[idx].isDeleted = true;
      notifyListeners();

      final client = SupabaseService.instance.client;
      if (client != null) {
        try {
          await client.from('vendors').update({'is_deleted': true}).eq('id', id);
        } catch (e) {
          if (kDebugMode) print('Supabase soft deleteVendor Error: $e');
        }
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
          'is_deleted': false,
        });
      } catch (e) {
        if (kDebugMode) print('Supabase addVenue Error: $e');
      }
    }
  }

  Future<void> deleteVenue(String id) async {
    final idx = venues.indexWhere((v) => v.id == id);
    if (idx >= 0) {
      venues[idx].isDeleted = true;
      notifyListeners();

      final client = SupabaseService.instance.client;
      if (client != null) {
        try {
          await client.from('venues').update({'is_deleted': true}).eq('id', id);
        } catch (e) {
          if (kDebugMode) print('Supabase soft deleteVenue Error: $e');
        }
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
          'is_deleted': false,
        });
      } catch (e) {
        try {
          await client.from('inventory').insert({
            'item_name': item.itemName,
            'category': item.category,
            'quantity': item.quantity,
            'rentalPrice': item.rentalPrice,
            'is_deleted': false,
          });
        } catch (err2) {
          if (kDebugMode) print('Supabase addInventory Error: $err2');
        }
      }
    }
  }

  Future<void> deleteInventory(String id) async {
    final idx = inventory.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      final nameToDelete = inventory[idx].itemName;
      inventory[idx].isDeleted = true;
      notifyListeners();

      final client = SupabaseService.instance.client;
      if (client != null) {
        try {
          await client.from('inventory').update({'is_deleted': true}).eq('item_name', nameToDelete);
        } catch (e) {
          if (kDebugMode) print('Supabase soft deleteInventory Error: $e');
        }
      }
    }
  }

  Future<void> saveInvoice(InvoiceModel item) async {
    item.sections = sanitizeInvoiceSections(item.sections);
    final index = invoices.indexWhere((i) => i.invoiceNumber == item.invoiceNumber);
    if (index >= 0) {
      invoices[index] = item;
    } else {
      invoices.insert(0, item);
    }

    // Auto-record Advance Payment in Payments List
    if (item.showAdvancePaid && item.advancePaid > 0) {
      final String paymentTitle = 'Invoice #${item.invoiceNumber} Advance Payment (${item.customerName})';
      final existingPaymentIndex = payments.indexWhere((p) => p.eventType.contains('Invoice #${item.invoiceNumber}'));

      if (existingPaymentIndex < 0) {
        addPayment(
          PaymentModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            date: item.invoiceDate.isNotEmpty ? item.invoiceDate : AppDateUtils.getTodayDate(),
            eventType: paymentTitle,
            amount: item.advancePaid,
            method: 'Bank Transfer / UPI',
          ),
        );
      } else {
        final existing = payments[existingPaymentIndex];
        final updatedP = PaymentModel(
          id: existing.id,
          date: item.invoiceDate.isNotEmpty ? item.invoiceDate : AppDateUtils.getTodayDate(),
          eventType: paymentTitle,
          amount: item.advancePaid,
          method: existing.method,
        );
        updatePayment(updatedP);
      }
    }

    if (item.balanceDue > 0) {
      final notifTitle = 'Payment Overdue Alert';
      final notifBody = 'Invoice #${item.invoiceNumber} for ${item.customerName} has an unpaid balance of ₹${item.balanceDue.toStringAsFixed(0)} due on ${item.dueDate}.';
      addNotification(
        AppNotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: notifTitle,
          message: notifBody,
          date: item.dueDate,
          type: NotificationType.paymentOverdue,
        ),
      );
      NotificationService.instance.showLocalPushNotification(title: notifTitle, body: notifBody);
    }

    notifyListeners();

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        final Map<String, dynamic> payload = {
          'invoice_number': item.invoiceNumber,
          'customer_name': item.customerName,
          'venue': item.venue,
          'invoice_date': item.invoiceDate,
          'due_date': item.dueDate,
          'show_due_date': item.showDueDate,
          'show_discount': item.showDiscount,
          'discount_amount': item.discountAmount,
          'show_tax': item.showTax,
          'tax_percentage': item.taxPercentage,
          'show_advance_paid': item.showAdvancePaid,
          'advance_paid': item.advancePaid,
          'manual_total_override': item.manualTotalOverride,
          'manual_grand_total': item.manualGrandTotal,
          'total_amount': item.grandTotal,
          'is_deleted': item.isDeleted,
        };

        bool invoiceUpsertSucceeded = false;
        try {
          await client.from('invoices').upsert(payload, onConflict: 'invoice_number');
          invoiceUpsertSucceeded = true;
        } catch (e) {
          if (kDebugMode) print('Supabase saveInvoice full payload error: $e');
          try {
            final Map<String, dynamic> payloadNoVenue = Map.from(payload)..remove('venue');
            await client.from('invoices').upsert(payloadNoVenue, onConflict: 'invoice_number');
            invoiceUpsertSucceeded = true;
          } catch (e2) {
            if (kDebugMode) print('Supabase saveInvoice payload without venue error: $e2');
            try {
              await client.from('invoices').upsert({
                'invoice_number': item.invoiceNumber,
                'customer_name': item.customerName,
                'invoice_date': item.invoiceDate,
              }, onConflict: 'invoice_number');
              invoiceUpsertSucceeded = true;
            } catch (fallbackErr) {
              if (kDebugMode) print('Supabase saveInvoice minimal fallback error: $fallbackErr');
            }
          }
        }

        if (!invoiceUpsertSucceeded) {
          if (kDebugMode) print('Supabase saveInvoice: Skipping sections insert due to parent record upsert failure.');
          return;
        }

        try {
          final existingSecs = await client
              .from('invoice_sections')
              .select('id')
              .eq('invoice_number', item.invoiceNumber);
          if (existingSecs != null && (existingSecs as List).isNotEmpty) {
            for (final s in existingSecs as List) {
              final sid = s['id']?.toString();
              if (sid != null && sid.isNotEmpty) {
                await client.from('invoice_items').delete().eq('section_id', sid);
              }
            }
          }
        } catch (e) {
          if (kDebugMode) print('Supabase delete invoice_items error: $e');
        }

        try {
          await client.from('invoice_sections').delete().eq('invoice_number', item.invoiceNumber);
        } catch (e) {
          if (kDebugMode) print('Supabase delete invoice_sections error: $e');
        }

        for (int sIdx = 0; sIdx < item.sections.length; sIdx++) {
          final section = item.sections[sIdx];
          final secRes = await client.from('invoice_sections').insert({
            'invoice_number': item.invoiceNumber,
            'heading': section.heading,
            'section_order': sIdx,
          }).select('id').single();

          final String sectionId = secRes['id']?.toString() ?? '';
          if (sectionId.isEmpty) continue;

          final List<Map<String, dynamic>> itemsPayload = section.items.map((itemRow) {
            return {
              'section_id': sectionId,
              'name': itemRow.name,
              'qty': itemRow.qty,
              'rate': itemRow.rate,
              'price': itemRow.price,
            };
          }).toList();

          if (itemsPayload.isNotEmpty) {
            try {
              await client.from('invoice_items').insert(itemsPayload);
            } catch (itemErr) {
              if (kDebugMode) print('Supabase invoice_items insert warning: $itemErr');
            }
          }
        }
      } catch (e) {
        if (kDebugMode) print('Supabase saveInvoice Error: $e');
      }
    }
  }

  Future<void> deleteInvoice(String invoiceNumber) async {
    final idx = invoices.indexWhere((i) => i.invoiceNumber == invoiceNumber);
    if (idx >= 0) {
      invoices[idx].isDeleted = true;
      notifyListeners();

      final client = SupabaseService.instance.client;
      if (client != null) {
        try {
          await client.from('invoices').update({'is_deleted': true}).eq('invoice_number', invoiceNumber);
        } catch (e) {
          if (kDebugMode) print('Supabase soft deleteInvoice Error: $e');
        }
      }
    }
  }
}
