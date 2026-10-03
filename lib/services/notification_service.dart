import 'package:flutter/foundation.dart';
import '../data/app_data_repository.dart';
import '../models/app_notification_model.dart';
import '../utils/date_formatter.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();

  NotificationService._internal();

  Future<void> initialize() async {
    if (kDebugMode) print('✅ NotificationService initialized successfully!');
  }

  void showNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.eventReminder,
  }) {
    final repo = AppDataRepository.instance;
    final notif = AppNotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: body,
      date: AppDateUtils.getTodayDate(),
      type: type,
    );
    repo.addNotification(notif);
    if (kDebugMode) print('🔔 Notification Triggered: [$title] $body');
  }

  void showLocalPushNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.eventReminder,
  }) {
    showNotification(title: title, body: body, type: type);
  }

  /// Automatically scans invoices, tasks, events, enquiries & payments to generate notifications
  void checkForAutomatedSystemNotifications() {
    final repo = AppDataRepository.instance;
    final todayStr = AppDateUtils.getTodayDate();

    // 1. Check Unpaid Invoices Due / Overdue
    for (var inv in repo.activeInvoices) {
      if (inv.balanceDue > 0) {
        final title = 'Invoice Overdue Alert';
        final body = 'Invoice #${inv.invoiceNumber} for ${inv.customerName} has an unpaid balance of ₹${inv.balanceDue.toStringAsFixed(0)} (Due: ${inv.dueDate}).';

        if (!repo.notifications.any((n) => n.message.contains(inv.invoiceNumber))) {
          final notif = AppNotificationModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            message: body,
            date: todayStr,
            type: NotificationType.paymentOverdue,
          );
          repo.addNotification(notif);
        }
      }
    }

    // 2. Check High Priority Pending Tasks
    for (var task in repo.activeTasks) {
      if (!task.isCompleted && task.priority.name == 'high') {
        final title = 'High Priority Task Alert';
        final body = 'Task "${task.title}" assigned for ${task.eventTitle} requires immediate action!';

        if (!repo.notifications.any((n) => n.message.contains(task.title))) {
          final notif = AppNotificationModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            message: body,
            date: todayStr,
            type: NotificationType.eventReminder,
          );
          repo.addNotification(notif);
        }
      }
    }

    // 3. Check Upcoming Events
    for (var event in repo.activeEvents) {
      if (event.status.name != 'completed' && event.status.name != 'cancelled') {
        final title = 'Upcoming Event Scheduled';
        final body = 'Event "${event.title}" is scheduled for ${event.date} at ${event.venue}.';

        if (!repo.notifications.any((n) => n.message.contains(event.code))) {
          final notif = AppNotificationModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            message: body,
            date: todayStr,
            type: NotificationType.eventReminder,
          );
          repo.addNotification(notif);
        }
      }
    }
  }
}
