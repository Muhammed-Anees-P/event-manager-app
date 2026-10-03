import 'package:flutter/material.dart';
import '../data/app_data_repository.dart';
import '../models/event_model.dart';
import '../models/task_model.dart';
import '../models/invoice_model.dart';
import '../services/invoice_pdf_service.dart';
import '../theme/app_theme.dart';
import 'create_invoice_screen.dart';
import 'tasks_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventModel event;
  final VoidCallback onBack;

  const EventDetailsScreen({
    super.key,
    required this.event,
    required this.onBack,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final repository = AppDataRepository.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    repository.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    repository.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  void _showEditEventDialog(BuildContext context, EventModel event) {
    final titleController = TextEditingController(text: event.title);
    final venueController = TextEditingController(text: event.venue);
    final dateController = TextEditingController(text: event.date);
    final contractController = TextEditingController(text: event.contractValue.toStringAsFixed(0));
    final receivedController = TextEditingController(text: event.amountReceived.toStringAsFixed(0));
    EventStatus status = event.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Edit Event Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Event Title')),
                  const SizedBox(height: 12),
                  TextField(controller: venueController, decoration: const InputDecoration(labelText: 'Venue')),
                  const SizedBox(height: 12),
                  TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Date')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(controller: contractController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Contract Value (₹)')),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(controller: receivedController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Received (₹)')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<EventStatus>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: EventStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName))).toList(),
                    onChanged: (v) => setStateModal(() => status = v!),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final updated = EventModel(
                          id: event.id,
                          code: event.code,
                          title: titleController.text.trim(),
                          date: dateController.text.trim(),
                          time: event.time,
                          venue: venueController.text.trim(),
                          guests: event.guests,
                          manager: event.manager,
                          status: status,
                          contractValue: double.tryParse(contractController.text.trim()) ?? event.contractValue,
                          amountReceived: double.tryParse(receivedController.text.trim()) ?? event.amountReceived,
                          services: event.services,
                        );
                        await repository.updateEvent(updated);
                        if (ctx.mounted) Navigator.pop(ctx);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteEvent(BuildContext context, EventModel event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete ${event.title}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await repository.deleteEvent(event.id);
              if (ctx.mounted) Navigator.pop(ctx);
              widget.onBack();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context, TaskModel task) {
    final titleController = TextEditingController(text: task.title);
    TaskPriority selectedPriority = task.priority;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) {
          return AlertDialog(
            title: const Text('Edit Task Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Task Description *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TaskPriority>(
                  value: selectedPriority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: TaskPriority.values
                      .map((p) => DropdownMenuItem(value: p, child: Text(p.displayName)))
                      .toList(),
                  onChanged: (v) => setStateModal(() => selectedPriority = v!),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.trim().isNotEmpty) {
                    setState(() {
                      task.title = titleController.text.trim();
                      task.priority = selectedPriority;
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Save Task'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditServiceDialog(BuildContext context, EventModel event, int index, String currentService) {
    final controller = TextEditingController(text: currentService);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Assigned Service'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Service Name / Description (e.g. Royal Caterers)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  event.services[index] = controller.text.trim();
                });
                await repository.updateEvent(event);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Save Service'),
          ),
        ],
      ),
    );
  }

  void _showAddServiceDialog(BuildContext context, EventModel event) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Service / Vendor'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Service Name / Description (e.g. DJ & Lighting)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  event.services.add(controller.text.trim());
                });
                await repository.updateEvent(event);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Add Service'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'Event Details',
          style: TextStyle(color: Color(0xFF1F2937), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
            tooltip: 'Edit Event',
            onPressed: () => _showEditEventDialog(context, event),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete Event',
            onPressed: () => _confirmDeleteEvent(context, event),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Banner Image
                  Stack(
                    children: [
                      Image.asset(
                        'assets/images/login_bg.png',
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 180,
                          color: const Color(0xFF3B2D20),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _buildStatusBadge(event.status),
                      ),
                    ],
                  ),
                  // Title & Code
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Code: ${event.code} • Customer: ${event.manager}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 1),
                  // Sub Tabs
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primary,
                      unselectedLabelColor: const Color(0xFF6B7280),
                      indicatorColor: AppTheme.primary,
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Tasks'),
                        Tab(text: 'Services'),
                        Tab(text: 'Invoices'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tab Content View
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Overview Tab
                        _buildOverviewTab(event),
                        // Tasks Tab
                        _buildEventTasksTab(event),
                        // Services Tab
                        _buildEventServicesTab(event),
                        // Invoices Tab
                        _buildEventInvoicesTab(event),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sticky Bottom Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _showEditEventDialog(context, event),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Event Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(EventModel event) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                _buildDetailRow(Icons.calendar_today_outlined, 'Date', event.date),
                const Divider(height: 16),
                _buildDetailRow(Icons.access_time, 'Time', event.time),
                const Divider(height: 16),
                _buildDetailRow(Icons.location_on_outlined, 'Venue', event.venue),
                const Divider(height: 16),
                _buildDetailRow(Icons.people_outline, 'Guests', '${event.guests}'),
                const Divider(height: 16),
                _buildDetailRow(Icons.person_outline, 'Customer / Manager', event.manager),
                const Divider(height: 16),
                _buildDetailRow(Icons.info_outline, 'Status', event.status.displayName, isStatus: true, status: event.status),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Financial Summary Card
          Container(
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
                    const Text('Contract Value', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                    Text('₹${event.contractValue.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount Received', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                    Text('₹${event.amountReceived.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Outstanding', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                    Text('₹${event.outstanding.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: event.paymentProgress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${event.paymentPercentage}% Paid',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTasksTab(EventModel event) {
    final eventTasks = repository.tasks.where((t) => t.eventTitle.contains(event.title) || event.title.contains(t.eventTitle)).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tasks (${eventTasks.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ElevatedButton.icon(
                onPressed: () => TasksScreen.showCreateDialog(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+ Add Event Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size(0, 36),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: eventTasks.isEmpty
                ? const Center(child: Text('No tasks created for this event yet.'))
                : ListView.builder(
                    itemCount: eventTasks.length,
                    itemBuilder: (context, idx) {
                      final task = eventTasks[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: task.isCompleted,
                              activeColor: AppTheme.primary,
                              onChanged: (val) {
                                setState(() {
                                  task.isCompleted = val ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                task.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  color: task.isCompleted ? Colors.grey : const Color(0xFF111827),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Color(0xFF4B5563), size: 18),
                              tooltip: 'Edit Task',
                              onPressed: () => _showEditTaskDialog(context, task),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                              tooltip: 'Delete Task',
                              onPressed: () {
                                setState(() {
                                  repository.tasks.removeWhere((t) => t.id == task.id);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventServicesTab(EventModel event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Assigned Services (${event.services.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ElevatedButton.icon(
                onPressed: () => _showAddServiceDialog(context, event),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+ Assign Service'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size(0, 36),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: event.services.isEmpty
                ? const Center(child: Text('No services assigned to this event yet.'))
                : ListView.builder(
                    itemCount: event.services.length,
                    itemBuilder: (context, idx) {
                      final service = event.services[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(service, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF4B5563), size: 18),
                                  tooltip: 'Edit Service',
                                  onPressed: () => _showEditServiceDialog(context, event, idx, service),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                  tooltip: 'Delete Service',
                                  onPressed: () async {
                                    setState(() {
                                      event.services.removeAt(idx);
                                    });
                                    await repository.updateEvent(event);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventInvoicesTab(EventModel event) {
    final eventInvoices = repository.invoices.where((i) => i.customerName.contains(event.manager) || event.title.contains(i.customerName)).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Invoices (${eventInvoices.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateInvoiceScreen(
                        initialEvent: event,
                        onBack: () => Navigator.pop(context),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+ Create Invoice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size(0, 36),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: eventInvoices.isEmpty
                ? const Center(child: Text('No invoices created for this event yet.'))
                : ListView.builder(
                    itemCount: eventInvoices.length,
                    itemBuilder: (context, idx) {
                      final inv = eventInvoices[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('#${inv.invoiceNumber} • ${inv.customerName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('Due: ${inv.dueDate}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                              ],
                            ),
                            Row(
                              children: [
                                Text('₹${inv.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.print_outlined, color: AppTheme.primary, size: 18),
                                  onPressed: () async {
                                    await InvoicePdfService.printInvoice(inv);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isStatus = false, EventStatus? status}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        ),
        Expanded(
          child: isStatus && status != null
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: _buildStatusBadge(status),
                )
              : Text(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        status.displayName,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
