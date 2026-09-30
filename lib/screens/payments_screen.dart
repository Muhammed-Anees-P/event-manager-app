import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../data/app_data_repository.dart';
import '../models/payment_model.dart';
import '../models/app_notification_model.dart';
import '../services/cash_receipt_pdf_service.dart';
import '../theme/app_theme.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  static void showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _CreatePaymentModal(),
    );
  }

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final repository = AppDataRepository.instance;
  String _selectedCustomerFilter = 'All';
  String _selectedMethodFilter = 'All';
  String _searchQuery = '';

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

  void _showEditPaymentModal(BuildContext context, PaymentModel p) {
    final amountController = TextEditingController(text: p.amount.toStringAsFixed(0));
    final purposeController = TextEditingController(text: p.eventType);
    String selectedMethod = p.method;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: purposeController, decoration: const InputDecoration(labelText: 'Purpose / Event')),
              const SizedBox(height: 12),
              TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹)')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedMethod,
                decoration: const InputDecoration(labelText: 'Method'),
                items: ['UPI', 'Bank Transfer', 'Cash', 'Credit Card'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setStateModal(() => selectedMethod = v!),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final updated = PaymentModel(
                      id: p.id,
                      date: p.date,
                      eventType: purposeController.text.trim(),
                      amount: double.tryParse(amountController.text.trim()) ?? p.amount,
                      method: selectedMethod,
                    );
                    await repository.updatePayment(updated);
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerNames = ['All', ...repository.customers.map((c) => c.name)];
    final methods = ['All', 'UPI', 'Bank Transfer', 'Cash', 'Credit Card'];

    final filteredPayments = repository.payments.where((p) {
      if (_selectedCustomerFilter != 'All' && !p.eventType.toLowerCase().contains(_selectedCustomerFilter.toLowerCase())) {
        return false;
      }
      if (_selectedMethodFilter != 'All' && p.method != _selectedMethodFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty && !p.eventType.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Payments Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Payments Collected', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(
                        '₹${repository.totalRevenue.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.account_balance_wallet, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Filtration Header Bar
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filter Payments', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCustomerFilter,
                          decoration: const InputDecoration(labelText: 'Customer', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                          items: customerNames.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) => setState(() => _selectedCustomerFilter = v ?? 'All'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedMethodFilter,
                          decoration: const InputDecoration(labelText: 'Method', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                          items: methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                          onChanged: (v) => setState(() => _selectedMethodFilter = v ?? 'All'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: const InputDecoration(
                      hintText: 'Search by event or purpose...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Payment Transactions (${filteredPayments.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              ],
            ),
            const SizedBox(height: 12),

            filteredPayments.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No payment transactions match the filter.')))
                : Column(
                    children: filteredPayments.map((p) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.arrow_downward, color: Color(0xFF10B981), size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.eventType, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                                    const SizedBox(height: 2),
                                    Text('Date: ${p.date} • Method: ${p.method}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('+₹${p.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.print, size: 18, color: AppTheme.primary),
                                        tooltip: 'Print Cash Receipt',
                                        onPressed: () => CashReceiptPdfService.printPdf(p),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18, color: Color(0xFF4B5563)),
                                        tooltip: 'Edit Payment',
                                        onPressed: () => _showEditPaymentModal(context, p),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                        tooltip: 'Delete Payment',
                                        onPressed: () => repository.deletePayment(p.id),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )).toList(),
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => PaymentsScreen.showCreateDialog(context),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _CreatePaymentModal extends StatefulWidget {
  const _CreatePaymentModal();

  @override
  State<_CreatePaymentModal> createState() => _CreatePaymentModalState();
}

class _CreatePaymentModalState extends State<_CreatePaymentModal> {
  final _formKey = GlobalKey<FormState>();
  final eventController = TextEditingController(text: 'Event Advance');
  final amountController = TextEditingController();
  String selectedMethod = 'UPI';
  String? selectedCustomer;

  @override
  void dispose() {
    eventController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> _showReceiptOptions(BuildContext context, PaymentModel payment, String customerName) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payment Recorded Successfully!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment of ₹${payment.amount.toStringAsFixed(0)} received from $customerName via ${payment.method}.'),
            const SizedBox(height: 16),
            const Text('Download Cash Receipt PDF or share it via WhatsApp:', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              final pdfBytes = await CashReceiptPdfService.generatePdfBytes(payment, customerName: customerName);
              await Printing.sharePdf(bytes: pdfBytes, filename: 'CashReceipt_${payment.id}.pdf');
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Cash Receipt PDF'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final pdfBytes = await CashReceiptPdfService.generatePdfBytes(payment, customerName: customerName);
              await Printing.sharePdf(bytes: pdfBytes, filename: 'CashReceipt_${payment.id}.pdf');
            },
            icon: const Icon(Icons.share, size: 16, color: Colors.white),
            label: const Text('WhatsApp', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customers = AppDataRepository.instance.customers.map((c) => c.name).toList();
    if (customers.isNotEmpty && selectedCustomer == null) {
      selectedCustomer = customers.first;
    }

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
                const Text('Record Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (customers.isNotEmpty)
              DropdownButtonFormField<String>(
                value: selectedCustomer,
                decoration: const InputDecoration(labelText: 'Select Customer *'),
                items: customers.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => selectedCustomer = v!),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: eventController,
              decoration: const InputDecoration(labelText: 'Event / Payment Purpose *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter purpose' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Payment Amount (₹) *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter amount' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedMethod,
              decoration: const InputDecoration(labelText: 'Payment Method'),
              items: ['UPI', 'Bank Transfer', 'Cash', 'Credit Card']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => selectedMethod = v!),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final customerName = selectedCustomer ?? 'Walk-in Customer';
                    final payment = PaymentModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      date: '12 Sep 2026',
                      eventType: '${eventController.text.trim()} ($customerName)',
                      amount: double.tryParse(amountController.text.trim()) ?? 0,
                      method: selectedMethod,
                    );
                    await AppDataRepository.instance.addPayment(payment);

                    AppDataRepository.instance.addNotification(
                      AppNotificationModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: 'Payment Recorded',
                        message: 'Received ₹${payment.amount.toStringAsFixed(0)} from $customerName via $selectedMethod.',
                        date: '12 Sep 2026',
                        type: NotificationType.eventReminder,
                      ),
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      _showReceiptOptions(context, payment, customerName);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Save Payment & Get Receipt'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
