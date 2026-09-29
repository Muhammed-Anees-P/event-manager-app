import 'package:flutter/material.dart';
import '../data/app_data_repository.dart';
import '../models/event_model.dart';
import '../models/enquiry_model.dart';
import '../theme/app_theme.dart';
import '../widgets/charts/event_status_chart.dart';
import '../widgets/charts/revenue_chart.dart';
import '../widgets/kpi_card.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigateToTab;
  final Function(EventModel) onSelectEvent;

  const DashboardScreen({
    super.key,
    required this.onNavigateToTab,
    required this.onSelectEvent,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final repository = AppDataRepository.instance;

  @override
  void initState() {
    super.initState();
    repository.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    repository.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 900;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. KPI Cards Grid
              _buildKpiGrid(isDesktop),
              const SizedBox(height: 24),

              // 2. Charts Row
              if (isDesktop)
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: RevenueChart()),
                    SizedBox(width: 20),
                    Expanded(flex: 3, child: EventStatusChart()),
                  ],
                )
              else
                const Column(
                  children: [
                    RevenueChart(),
                    SizedBox(height: 16),
                    EventStatusChart(),
                  ],
                ),
              const SizedBox(height: 24),

              // 3. Upcoming Events & Tasks Due Today Row
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _buildUpcomingEvents(context)),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: _buildTasksDueToday(context)),
                  ],
                )
              else ...[
                _buildUpcomingEvents(context),
                const SizedBox(height: 24),
                _buildTasksDueToday(context),
              ],
              const SizedBox(height: 24),

              // 4. Recent Enquiries & Recent Payments
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _buildRecentEnquiries(context)),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: _buildRecentPayments(context)),
                  ],
                )
              else ...[
                _buildRecentEnquiries(context),
                const SizedBox(height: 24),
                _buildRecentPayments(context),
              ],
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // KPI GRID
  // ==========================================
  Widget _buildKpiGrid(bool isDesktop) {
    final List<Widget> cards = [
      KpiCard(
        title: 'Total Events',
        value: '${repository.totalEventsCount}',
        trend: '12% from last month',
        icon: Icons.calendar_today,
        iconBgColor: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF3B82F6),
      ),
      KpiCard(
        title: 'Total Revenue',
        value: '₹${repository.totalRevenue.toStringAsFixed(0)}',
        trend: '8% from last month',
        icon: Icons.currency_rupee,
        iconBgColor: const Color(0xFFECFDF5),
        iconColor: const Color(0xFF10B981),
      ),
      KpiCard(
        title: 'Outstanding',
        value: '₹${repository.totalOutstanding.toStringAsFixed(0)}',
        trend: '5% from last month',
        icon: Icons.receipt_long,
        iconBgColor: const Color(0xFFFEF2F2),
        iconColor: const Color(0xFFEF4444),
      ),
      KpiCard(
        title: 'Total Profit',
        value: '₹${repository.totalProfit.toStringAsFixed(0)}',
        trend: '15% from last month',
        icon: Icons.account_balance_wallet,
        iconBgColor: const Color(0xFFFFFBEB),
        iconColor: const Color(0xFFF59E0B),
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: c,
                  ),
                ))
            .toList()
          ..removeLast()
          ..add(Expanded(child: cards.last)),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cards,
    );
  }

  // ==========================================
  // UPCOMING EVENTS
  // ==========================================
  Widget _buildUpcomingEvents(BuildContext context) {
    final events = repository.events.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Events',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              TextButton(
                onPressed: () => widget.onNavigateToTab(4), // Events tab
                child: const Text('View All', style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No upcoming events.')),
            )
          else
            ...events.map((event) => _buildEventCard(context, event)),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event) {
    final dateParts = event.date.split(' ');
    final day = dateParts.isNotEmpty ? dateParts[0] : '18';
    final month = dateParts.length > 1 ? dateParts[1] : 'Sep';

    return InkWell(
      onTap: () => widget.onSelectEvent(event),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Text(
                    day,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Text(
                    month,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${event.venue} • ${event.guests} Guests',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusBadge(event.status),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TASKS DUE TODAY
  // ==========================================
  Widget _buildTasksDueToday(BuildContext context) {
    final tasks = repository.tasks.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tasks Due Today',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              TextButton(
                onPressed: () => widget.onNavigateToTab(5), // Tasks tab
                child: const Text('View All', style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No tasks due today.')),
            )
          else
            Column(
              children: tasks.map((task) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: task.isCompleted,
                          activeColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (val) {
                            setState(() {
                              task.isCompleted = val ?? false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: task.isCompleted
                                    ? Colors.grey
                                    : const Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              task.eventTitle,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // RECENT ENQUIRIES
  // ==========================================
  Widget _buildRecentEnquiries(BuildContext context) {
    final enquiries = repository.enquiries;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Enquiries',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              TextButton(
                onPressed: () => widget.onNavigateToTab(1), // Enquiries tab
                child: const Text('View All', style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (enquiries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No enquiries.')),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                headingRowHeight: 36,
                dataRowMinHeight: 42,
                dataRowMaxHeight: 46,
                columns: const [
                  DataColumn(label: Text('Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Total Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Actions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                ],
                rows: enquiries.map((enquiry) {
                  return DataRow(
                    cells: [
                      DataCell(Text(enquiry.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                      DataCell(Text(enquiry.type, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)))),
                      DataCell(Text(enquiry.totalDate, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)))),
                      DataCell(Text('₹${enquiry.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                      DataCell(_buildEnquiryBadge(enquiry.status)),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // RECENT PAYMENTS
  // ==========================================
  Widget _buildRecentPayments(BuildContext context) {
    final payments = repository.payments;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Payments',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              TextButton(
                onPressed: () => widget.onNavigateToTab(7), // Payments tab
                child: const Text('View All', style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (payments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No payment records.')),
            )
          else
            Column(
              children: payments.map((p) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(p.date, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4B5563))),
                      const SizedBox(width: 12),
                      Expanded(child: Text(p.eventType, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                      Text('₹${p.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Text(p.method, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(EventStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case EventStatus.confirmed:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        break;
      case EventStatus.planning:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        break;
      case EventStatus.completed:
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF2563EB);
        break;
      case EventStatus.cancelled:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEnquiryBadge(EnquiryStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case EnquiryStatus.newEnquiry:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        break;
      case EnquiryStatus.quoted:
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF2563EB);
        break;
      case EnquiryStatus.followUp:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        break;
      case EnquiryStatus.contacted:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        status.displayName,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
