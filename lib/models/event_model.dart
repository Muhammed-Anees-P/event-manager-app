enum EventStatus { confirmed, planning, completed, cancelled }

extension EventStatusExtension on EventStatus {
  String get displayName {
    switch (this) {
      case EventStatus.confirmed:
        return 'Confirmed';
      case EventStatus.planning:
        return 'Planning';
      case EventStatus.completed:
        return 'Completed';
      case EventStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class EventModel {
  final String id;
  final String code;
  final String title;
  final String date;
  final String time;
  final String venue;
  final int guests;
  final String manager;
  final EventStatus status;
  final double contractValue;
  final double amountReceived;
  final String? imageUrl;
  final List<String> services;

  EventModel({
    required this.id,
    required this.code,
    required this.title,
    required this.date,
    required this.time,
    required this.venue,
    required this.guests,
    required this.manager,
    required this.status,
    required this.contractValue,
    required this.amountReceived,
    this.imageUrl,
    List<String>? services,
  }) : services = services ?? [];

  double get outstanding => contractValue - amountReceived;
  double get paymentProgress => contractValue > 0 ? (amountReceived / contractValue) : 0;
  int get paymentPercentage => (paymentProgress * 100).round();
}
