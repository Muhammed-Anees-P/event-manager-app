import 'package:flutter/material.dart';
import '../data/app_data_repository.dart';
import '../services/auth_session_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class MoreScreen extends StatelessWidget {
  final Function(int) onNavigateToTab;

  const MoreScreen({
    super.key,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    final userName = AppDataRepository.instance.currentUserName;
    final userEmail = AppDataRepository.instance.currentUserEmail;
    final initial = userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'A';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header Card
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primary,
                      child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                        const SizedBox(height: 2),
                        Text(userEmail, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Main Features Group
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text('Main Features', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
            ),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(context, Icons.assignment_outlined, 'Enquiries', () => onNavigateToTab(1)),
                    const Divider(height: 1),
                    _buildMenuItem(context, Icons.people_outline, 'Customers', () => onNavigateToTab(2)),
                    const Divider(height: 1),
                    _buildMenuItem(context, Icons.description_outlined, 'Quotations', () => onNavigateToTab(3)),
                    const Divider(height: 1),
                    _buildMenuItem(context, Icons.calendar_today_outlined, 'Events', () => onNavigateToTab(4)),
                    const Divider(height: 1),
                    _buildMenuItem(context, Icons.task_alt_outlined, 'Tasks & Services', () => onNavigateToTab(5)),
                    const Divider(height: 1),
                    _buildMenuItem(context, Icons.receipt_long_outlined, 'Invoices', () => onNavigateToTab(6)),
                    const Divider(height: 1),
                    _buildMenuItem(context, Icons.account_balance_wallet_outlined, 'Payments', () => onNavigateToTab(7)),
                    const Divider(height: 1),
                    _buildMenuItem(context, Icons.payments_outlined, 'Expenses', () => onNavigateToTab(8)),
                    const Divider(height: 1),
                    _buildMenuItem(context, Icons.insert_chart_outlined, 'Reports', () => onNavigateToTab(9)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Management Group
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text('Management', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
            ),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(context, Icons.storefront_outlined, 'Vendors', () => onNavigateToTab(10)),
                    const Divider(height: 1),
                    _buildMenuItem(context, Icons.location_on_outlined, 'Venues', () => onNavigateToTab(11)),
                    const Divider(height: 1),
                    _buildMenuItem(context, Icons.inventory_2_outlined, 'Inventory', () => onNavigateToTab(12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Settings Group
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text('Settings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
            ),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(context, Icons.settings_outlined, 'Company Settings', () => onNavigateToTab(13)),
                    const Divider(height: 1),
                    _buildMenuItem(context, Icons.admin_panel_settings_outlined, 'Users & Privileges', () => onNavigateToTab(14)),
                    const Divider(height: 1),
                    _buildMenuItem(context, Icons.help_outline, 'Help & Support', () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Help & Support: Support line +91 9876543210')),
                      );
                    }),
                    const Divider(height: 1),
                    _buildMenuItem(
                      context,
                      Icons.logout,
                      'Logout',
                      () async {
                        await AuthSessionService.instance.clearSession();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: isDestructive ? Colors.red : const Color(0xFF4B5563), size: 20),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : const Color(0xFF111827),
        ),
      ),
      trailing: isDestructive
          ? null
          : const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 20),
    );
  }
}
