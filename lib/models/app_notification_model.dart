enum NotificationType { eventReminder, paymentOverdue, enquiryAlert, general }

class AppNotificationModel {
  final String id;
  final String title;
  final String message;
  final String date;
  final NotificationType type;
  bool isRead;

  AppNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.type,
    this.isRead = false,
  });
}
