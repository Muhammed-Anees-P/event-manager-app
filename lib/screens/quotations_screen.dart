import 'package:flutter/material.dart';
import '../data/app_data_repository.dart';
import '../models/quotation_model.dart';
import '../theme/app_theme.dart';

class QuotationsScreen extends StatefulWidget {
  const QuotationsScreen({super.key});

  static void showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _CreateQuotationModal(),
    );
  }

  @override
  State<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends State<QuotationsScreen> {
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
    final quotations = repository.quotations;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: quotations.isEmpty
          ? const Center(child: Text('No quotations yet. Tap + to create one.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: quotations.length,
              itemBuilder: (context, index) {
                final q = quotations[index];
                return Container(
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
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.description_outlined, color: AppTheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${q.quoteNumber} • ${q.customerName}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                            const SizedBox(height: 2),
                            Text('${q.eventType} • Date: ${q.date}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${q.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(q.status, style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => QuotationsScreen.showCreateDialog(context),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _CreateQuotationModal extends StatefulWidget {
  const _CreateQuotationModal();

  @override
  State<_CreateQuotationModal> createState() => _CreateQuotationModalState();
}

class _CreateQuotationModalState extends State<_CreateQuotationModal> {
  final _formKey = GlobalKey<FormState>();
  final customerController = TextEditingController();
  final amountController = TextEditingController();
  String selectedType = 'Wedding';

  @override
  void dispose() {
    customerController.dispose();
    amountController.dispose();
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
                const Text('Create Quotation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: customerController,
              decoration: const InputDecoration(labelText: 'Customer Name'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter customer' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(labelText: 'Event Type'),
              items: ['Wedding', 'Corporate', 'Engagement', 'Birthday', 'Anniversary']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => selectedType = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Total Quoted Amount (₹)'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter amount' : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final q = QuotationModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      quoteNumber: 'QT-2026-00${AppDataRepository.instance.quotations.length + 1}',
                      customerName: customerController.text.trim(),
                      eventType: selectedType,
                      date: '12 Sep 2026',
                      totalAmount: double.tryParse(amountController.text.trim()) ?? 0,
                      status: 'Sent',
                    );
                    await AppDataRepository.instance.addQuotation(q);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Save Quotation'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
