import 'package:flutter/material.dart';
import '../data/app_data_repository.dart';
import '../models/app_notification_model.dart';
import '../theme/app_theme.dart';

class TopHeader extends StatelessWidget {
  final String actionLabel;
  final VoidCallback? onActionButtonPressed;
  final VoidCallback? onOpenSettings;

  const TopHeader({
    super.key,
    required this.actionLabel,
    this.onActionButtonPressed,
    this.onOpenSettings,
  });

  String _getCurrentFormattedDate() {
    final now = DateTime.now();
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekday = weekdays[now.weekday - 1];
    final month = months[now.month];
    return '$weekday, ${now.day} $month ${now.year}';
  }

  void _showNotificationsDialog(BuildContext context) {
    final repository = AppDataRepository.instance;
    final notifications = repository.notifications;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          repository.markAllNotificationsAsRead();
                          setState(() {});
                        },
                        child: const Text('Mark all as read'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (notifications.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('No notifications right now.')),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: notifications.length,
                        itemBuilder: (ctx, idx) {
                          final n = notifications[idx];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: n.type == NotificationType.paymentOverdue
                                  ? const Color(0xFFFEE2E2)
                                  : const Color(0xFFEFF6FF),
                              child: Icon(
                                n.type == NotificationType.paymentOverdue
                                    ? Icons.warning_amber_outlined
                                    : Icons.event,
                                color: n.type == NotificationType.paymentOverdue ? Colors.red : AppTheme.primary,
                                size: 18,
                              ),
                            ),
                            title: Text(n.title, style: TextStyle(fontSize: 13, fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                            subtitle: Text(n.message, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                            trailing: Text(n.date, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.headset_mic, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Help & Support'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need assistance with your events or account?', style: TextStyle(fontSize: 13)),
            SizedBox(height: 12),
            Text('Support Line / WhatsApp:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
            SizedBox(height: 4),
            SelectableText(
              '+91 9747451938',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
            ),
            SizedBox(height: 8),
            Text('Email: admin@hayaevents.com', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showSearchModal(BuildContext context) {
    showSearch(context: context, delegate: _GlobalSearchDelegate());
  }

  @override
  Widget build(BuildContext context) {
    final repository = AppDataRepository.instance;
    final userName = repository.currentUserName;
    final initial = userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'A';
    final unreadCount = repository.unreadNotificationsCount;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Top Row: Search & Action Icons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    readOnly: true,
                    onTap: () => _showSearchModal(context),
                    decoration: InputDecoration(
                      hintText: 'Search events, customers, invoices...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                      prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF9CA3AF)),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Notifications badge
              Stack(
                children: [
                  IconButton(
                    onPressed: () => _showNotificationsDialog(context),
                    icon: const Icon(Icons.notifications_outlined, color: Color(0xFF4B5563)),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                onPressed: () => _showHelpDialog(context),
                icon: const Icon(Icons.help_outline, color: Color(0xFF4B5563)),
                tooltip: 'Help & Support (+91 9747451938)',
              ),
              IconButton(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings_outlined, color: Color(0xFF4B5563)),
                tooltip: 'Company Settings',
              ),
              const SizedBox(width: 12),
              // Profile
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primary,
                    child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                      ),
                      const Text(
                        'Administrator',
                        style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Sub Row: Greeting & Dynamic Section Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Good Morning, $userName ',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                      ),
                      const Text('👋', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Let\'s make more beautiful moments happen today.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    _getCurrentFormattedDate(),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 16),
                  if (onActionButtonPressed != null && actionLabel.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: onActionButtonPressed,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(actionLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlobalSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults(context);

  Widget _buildSearchResults(BuildContext context) {
    final repo = AppDataRepository.instance;
    final q = query.toLowerCase();

    final matchingEvents = repo.events.where((e) => e.title.toLowerCase().contains(q) || e.venue.toLowerCase().contains(q)).toList();
    final matchingCustomers = repo.customers.where((c) => c.name.toLowerCase().contains(q) || c.email.toLowerCase().contains(q)).toList();
    final matchingInvoices = repo.invoices.where((i) => i.customerName.toLowerCase().contains(q) || i.invoiceNumber.toLowerCase().contains(q)).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (matchingEvents.isNotEmpty) ...[
          const Text('Events', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ...matchingEvents.map((e) => ListTile(title: Text(e.title), subtitle: Text(e.venue))),
          const Divider(),
        ],
        if (matchingCustomers.isNotEmpty) ...[
          const Text('Customers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ...matchingCustomers.map((c) => ListTile(title: Text(c.name), subtitle: Text(c.email))),
          const Divider(),
        ],
        if (matchingInvoices.isNotEmpty) ...[
          const Text('Invoices', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ...matchingInvoices.map((i) => ListTile(title: Text('#${i.invoiceNumber} - ${i.customerName}'), subtitle: Text('₹${i.grandTotal.toStringAsFixed(0)}'))),
        ],
      ],
    );
  }
}
