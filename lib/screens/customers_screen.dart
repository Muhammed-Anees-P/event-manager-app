import 'package:flutter/material.dart';
import '../data/app_data_repository.dart';
import '../models/customer_model.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loading_overlay.dart';
import '../widgets/charts/customer_revenue_chart.dart';
import '../widgets/delete_confirmation_dialog.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  static void showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _CreateCustomerModal(),
    );
  }

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
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

  void _showEditCustomerModal(CustomerModel customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EditCustomerModal(customer: customer),
    );
  }

  void _confirmDeleteCustomer(CustomerModel customer) async {
    final confirm = await AppDeleteConfirmationDialog.show(
      context,
      title: 'Delete Customer',
      itemDetails: 'Customer: ${customer.name} (${customer.phone})',
    );
    if (confirm) {
      await AppLoadingOverlay.run(
        context,
        message: 'Deleting customer...',
        asyncTask: () => repository.deleteCustomer(customer.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCustomers = repository.activeCustomers;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: activeCustomers.isEmpty
          ? const Center(child: Text('No active customers. Tap + to add.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activeCustomers.length,
              itemBuilder: (context, index) {
                final c = activeCustomers[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerDetailScreen(customer: c),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primary,
                              child: Text(
                                c.name.isNotEmpty ? c.name.substring(0, 1) : 'C',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                                  const SizedBox(height: 2),
                                  Text('${c.email.isEmpty ? "No Email" : c.email} • ${c.phone}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('View History', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF4B5563)),
                            tooltip: 'Edit Customer',
                            onPressed: () => _showEditCustomerModal(c),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            tooltip: 'Delete Customer',
                            onPressed: () => _confirmDeleteCustomer(c),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => CustomersScreen.showCreateDialog(context),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class CustomerDetailScreen extends StatelessWidget {
  final CustomerModel customer;
  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final repository = AppDataRepository.instance;
    final nameLower = customer.name.toLowerCase().trim();

    final customerEvents = repository.events.where((e) {
      final mgr = e.manager.toLowerCase().trim();
      return mgr.contains(nameLower) || nameLower.contains(mgr);
    }).toList();

    final customerInvoices = repository.invoices.where((i) {
      final name = i.customerName.toLowerCase().trim();
      return name.contains(nameLower) || nameLower.contains(name);
    }).toList();

    final customerPayments = repository.payments.where((p) {
      final type = p.eventType.toLowerCase().trim();
      return type.contains(nameLower) || nameLower.contains(type);
    }).toList();

    final double totalContractValue = customerEvents.fold(0.0, (s, e) => s + e.contractValue);
    final double totalAmountReceived = customerEvents.fold(0.0, (s, e) => s + e.amountReceived);
    final double totalOutstanding = (totalContractValue - totalAmountReceived).clamp(0.0, double.infinity);
    final double paymentProgress = totalContractValue > 0 ? (totalAmountReceived / totalContractValue).clamp(0.0, 1.0) : 0.0;
    final int paymentPercentage = (paymentProgress * 100).round();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(customer.name, style: const TextStyle(color: Color(0xFF1F2937), fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primary,
                    child: Text(customer.name.isNotEmpty ? customer.name.substring(0, 1) : 'C', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                        const SizedBox(height: 4),
                        Text('Email: ${customer.email.isEmpty ? "N/A" : customer.email}', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                        Text('Phone: ${customer.phone}', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            CustomerDynamicRevenueChart(
              events: customerEvents,
              payments: customerPayments,
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Financial Metrics',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricTile('Total Contract Value', '₹${totalContractValue.toStringAsFixed(0)}', const Color(0xFF111827)),
                      _buildMetricTile('Amount Received', '₹${totalAmountReceived.toStringAsFixed(0)}', const Color(0xFF10B981)),
                      _buildMetricTile('Outstanding Balance', '₹${totalOutstanding.toStringAsFixed(0)}', const Color(0xFFEF4444)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: paymentProgress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$paymentPercentage% Paid',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text('Events History (${customerEvents.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
            const SizedBox(height: 10),
            customerEvents.isEmpty
                ? const Text('No events recorded for this customer.', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13))
                : Column(
                    children: customerEvents.map((e) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('Venue: ${e.venue} • Date: ${e.date}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                                ],
                              ),
                              Text('₹${e.contractValue.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                            ],
                          ),
                        )).toList(),
                  ),
            const SizedBox(height: 20),

            Text('Invoices History (${customerInvoices.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
            const SizedBox(height: 10),
            customerInvoices.isEmpty
                ? const Text('No invoices recorded for this customer.', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13))
                : Column(
                    children: customerInvoices.map((i) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Invoice #${i.invoiceNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('Due: ${i.dueDate}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                                ],
                              ),
                              Text('₹${i.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                            ],
                          ),
                        )).toList(),
                  ),
            const SizedBox(height: 20),

            Text('Payments History (${customerPayments.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
            const SizedBox(height: 10),
            customerPayments.isEmpty
                ? const Text('No payments recorded for this customer.', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13))
                : Column(
                    children: customerPayments.map((p) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.eventType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('Date: ${p.date} • Method: ${p.method}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                                ],
                              ),
                              Text('+₹${p.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                            ],
                          ),
                        )).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _EditCustomerModal extends StatefulWidget {
  final CustomerModel customer;

  const _EditCustomerModal({required this.customer});

  @override
  State<_EditCustomerModal> createState() => _EditCustomerModalState();
}

class _EditCustomerModalState extends State<_EditCustomerModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.customer.name);
    emailController = TextEditingController(text: widget.customer.email);
    phoneController = TextEditingController(text: widget.customer.phone);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit Customer Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Customer Name *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email Address (Optional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter phone' : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final updated = CustomerModel(
                      id: widget.customer.id,
                      name: nameController.text.trim(),
                      email: emailController.text.trim(),
                      phone: phoneController.text.trim(),
                      totalEvents: widget.customer.totalEvents,
                      isDeleted: widget.customer.isDeleted,
                    );
                    await AppLoadingOverlay.run(
                      context,
                      message: 'Updating customer...',
                      asyncTask: () => AppDataRepository.instance.updateCustomer(updated),
                    );
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Update Customer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateCustomerModal extends StatefulWidget {
  const _CreateCustomerModal();

  @override
  State<_CreateCustomerModal> createState() => _CreateCustomerModalState();
}

class _CreateCustomerModalState extends State<_CreateCustomerModal> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Add Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Customer Name *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email Address (Optional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter phone' : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final customer = CustomerModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text.trim(),
                      email: emailController.text.trim(),
                      phone: phoneController.text.trim(),
                      totalEvents: 0,
                    );
                    await AppLoadingOverlay.run(
                      context,
                      message: 'Adding customer...',
                      asyncTask: () => AppDataRepository.instance.addCustomer(customer),
                    );
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Save Customer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
