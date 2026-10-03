class AppDateUtils {
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static String getTodayDate() {
    final now = DateTime.now();
    return '${now.day} ${_months[now.month - 1]} ${now.year}';
  }

  static String getDueDate({int daysFromToday = 15}) {
    final due = DateTime.now().add(Duration(days: daysFromToday));
    return '${due.day} ${_months[due.month - 1]} ${due.year}';
  }
}
