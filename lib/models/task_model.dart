enum TaskPriority { high, medium, low }

extension TaskPriorityExtension on TaskPriority {
  String get displayName {
    switch (this) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }
}

class TaskModel {
  final String id;
  String title;
  String eventTitle;
  TaskPriority priority;
  bool isCompleted;
  String category;
  bool isDeleted;

  TaskModel({
    required this.id,
    required this.title,
    required this.eventTitle,
    required this.priority,
    this.isCompleted = false,
    this.category = 'Today',
    this.isDeleted = false,
  });
}
