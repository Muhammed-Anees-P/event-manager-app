import 'package:flutter/material.dart';
import '../data/app_data_repository.dart';
import '../models/event_model.dart';
import '../services/auth_session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/top_header.dart';

import 'company_settings_screen.dart';
import 'create_invoice_screen.dart';
import 'customers_screen.dart';
import 'dashboard_screen.dart';
import 'enquiries_screen.dart';
import 'event_details_screen.dart';
import 'events_screen.dart';
import 'expenses_screen.dart';
import 'inventory_screen.dart';
import 'login_screen.dart';
import 'more_screen.dart';
import 'payments_screen.dart';
import 'quotations_screen.dart';
import 'reports_screen.dart';
import 'tasks_screen.dart';
import 'users_privileges_screen.dart';
import 'vendors_screen.dart';
import 'venues_screen.dart';
import 'welcome_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _selectedIndex = 0;
  EventModel? _selectedEvent;
  bool _isCreatingInvoice = false;

  void _onNavigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
      _selectedEvent = null;
      _isCreatingInvoice = false;
    });
  }

  void _onSelectEvent(EventModel event) {
    setState(() {
      _selectedEvent = event;
    });
  }

  void _logout() async {
    await AuthSessionService.instance.clearSession();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  String _getHeaderActionLabel() {
    switch (_selectedIndex) {
      case 0:
      case 4:
        return 'Create Event';
      case 1:
        return 'New Enquiry';
      case 2:
        return 'Add Customer';
      case 3:
        return 'Create Quotation';
      case 5:
        return 'Add Task';
      case 6:
        return 'Create Invoice';
      case 7:
        return 'Record Payment';
      case 8:
        return 'Add Expense';
      case 10:
        return 'Add Vendor';
      case 11:
        return 'Add Venue';
      case 12:
        return 'Add Item';
      default:
        return '';
    }
  }

  VoidCallback? _getHeaderActionCallback() {
    switch (_selectedIndex) {
      case 0:
      case 4:
        return () => EventsScreen.showCreateDialog(context);
      case 1:
        return () => EnquiriesScreen.showCreateDialog(context);
      case 2:
        return () => CustomersScreen.showCreateDialog(context);
      case 3:
        return () => QuotationsScreen.showCreateDialog(context);
      case 5:
        return () => TasksScreen.showCreateDialog(context);
      case 6:
        return () {
          setState(() {
            _isCreatingInvoice = true;
          });
        };
      case 7:
        return () => PaymentsScreen.showCreateDialog(context);
      case 8:
        return () => ExpensesScreen.showCreateDialog(context);
      case 10:
        return () => VendorsScreen.showCreateDialog(context);
      case 11:
        return () => VenuesScreen.showCreateDialog(context);
      case 12:
        return () => InventoryScreen.showCreateDialog(context);
      default:
        return null;
    }
  }

  Widget _buildContentBody(bool isDesktop) {
    if (_selectedEvent != null) {
      return EventDetailsScreen(
        event: _selectedEvent!,
        onBack: () {
          setState(() {
            _selectedEvent = null;
          });
        },
      );
    }

    if (_isCreatingInvoice) {
      return CreateInvoiceScreen(
        onBack: () {
          setState(() {
            _isCreatingInvoice = false;
          });
        },
      );
    }

    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(
          onNavigateToTab: _onNavigateToTab,
          onSelectEvent: _onSelectEvent,
        );
      case 1:
        return const EnquiriesScreen();
      case 2:
        return const CustomersScreen();
      case 3:
        return const QuotationsScreen();
      case 4:
        return EventsScreen(onSelectEvent: _onSelectEvent);
      case 5:
        return const TasksScreen();
      case 6:
        return const CreateInvoiceScreen();
      case 7:
        return const PaymentsScreen();
      case 8:
        return const ExpensesScreen();
      case 9:
        return const ReportsScreen();
      case 10:
        return const VendorsScreen();
      case 11:
        return const VenuesScreen();
      case 12:
        return const InventoryScreen();
      case 13:
        return const CompanySettingsScreen();
      case 14:
        return const UsersPrivilegesScreen();
      case 15:
        return MoreScreen(onNavigateToTab: _onNavigateToTab);
      default:
        return DashboardScreen(
          onNavigateToTab: _onNavigateToTab,
          onSelectEvent: _onSelectEvent,
        );
    }
  }

  int _getBottomNavIndex() {
    if (_selectedIndex == 0) return 0;
    if (_selectedIndex == 4) return 1;
    if (_selectedIndex == 5) return 2;
    if (_selectedIndex == 7) return 3;
    if (_selectedIndex == 15) return 4;
    return 0;
  }

  void _onBottomNavTapped(int index) {
    switch (index) {
      case 0:
        _onNavigateToTab(0);
        break;
      case 1:
        _onNavigateToTab(4); // Events
        break;
      case 2:
        _onNavigateToTab(5); // Tasks
        break;
      case 3:
        _onNavigateToTab(7); // Payments
        break;
      case 4:
        _onNavigateToTab(15); // More
        break;
    }
  }

  String _getMobileTitle() {
    if (_selectedEvent != null) return 'Event Details';
    if (_isCreatingInvoice) return 'Create Invoice';
    switch (_selectedIndex) {
      case 0:
        return 'Haya';
      case 1:
        return 'Enquiries';
      case 2:
        return 'Customers';
      case 3:
        return 'Quotations';
      case 4:
        return 'Events';
      case 5:
        return 'Tasks';
      case 6:
        return 'Create Invoice';
      case 7:
        return 'Payments';
      case 8:
        return 'Expenses';
      case 9:
        return 'Reports';
      case 10:
        return 'Vendors';
      case 11:
        return 'Venues';
      case 12:
        return 'Inventory';
      case 13:
        return 'Company Settings';
      case 14:
        return 'Users & Privileges';
      case 15:
        return 'More';
      default:
        return 'Haya';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 900;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: Row(
              children: [
                Sidebar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: _onNavigateToTab,
                  onLogout: _logout,
                ),
                Expanded(
                  child: Column(
                    children: [
                      TopHeader(
                        actionLabel: _getHeaderActionLabel(),
                        onActionButtonPressed: _getHeaderActionCallback(),
                        onOpenSettings: () => _onNavigateToTab(13),
                      ),
                      Expanded(
                        child: _buildContentBody(true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile Layout
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: _selectedEvent == null && !_isCreatingInvoice && _selectedIndex != 6
              ? AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  title: Row(
                    children: [
                      if (_selectedIndex == 0) ...[
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primary, width: 1.5),
                          ),
                          child: const Center(
                            child: Text('H', style: TextStyle(color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Haya',
                          style: TextStyle(color: Color(0xFF111827), fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ] else
                        Text(
                          _getMobileTitle(),
                          style: const TextStyle(color: Color(0xFF111827), fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.search, color: Color(0xFF4B5563)),
                      onPressed: () {
                        showSearch(context: context, delegate: _MobileSearchDelegate());
                      },
                    ),
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppTheme.primary,
                      child: Text(
                        AppDataRepository.instance.currentUserName.isNotEmpty
                            ? AppDataRepository.instance.currentUserName.substring(0, 1).toUpperCase()
                            : 'A',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                )
              : null,
          body: _buildContentBody(false),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _getBottomNavIndex(),
            onTap: _onBottomNavTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: const Color(0xFF6B7280),
            selectedFontSize: 11,
            unselectedFontSize: 11,
            backgroundColor: Colors.white,
            elevation: 8,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Events'),
              BottomNavigationBarItem(icon: Icon(Icons.task_alt_outlined), activeIcon: Icon(Icons.task_alt), label: 'Tasks'),
              BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Payments'),
              BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), activeIcon: Icon(Icons.grid_view), label: 'More'),
            ],
          ),
        );
      },
    );
  }
}

class _MobileSearchDelegate extends SearchDelegate {
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
        ],
      ],
    );
  }
}
