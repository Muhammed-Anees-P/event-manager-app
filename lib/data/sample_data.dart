import '../models/customer_model.dart';
import '../models/enquiry_model.dart';
import '../models/event_model.dart';
import '../models/payment_model.dart';
import '../models/task_model.dart';

class SampleData {
  static List<EventModel> events = [
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

  static List<TaskModel> tasks = [
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

  static List<EnquiryModel> enquiries = [
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

  static List<PaymentModel> payments = [
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

  static List<CustomerModel> customers = [
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
}
