import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/app_data_repository.dart';
import '../models/invoice_model.dart';
import '../models/event_model.dart';
import '../models/customer_model.dart';
import '../models/payment_model.dart';
import '../services/invoice_pdf_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatter.dart';
import '../widgets/delete_confirmation_dialog.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final EventModel? initialEvent;

  const CreateInvoiceScreen({
    super.key,
    this.onBack,
    this.initialEvent,
  });

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  int _mainTab = 0; // 0 = All Invoices, 1 = Invoice Form & Template Customization
  int _formSubTab = 0; // 0 = Edit Form, 1 = Template Preview

  String _invoiceSearchQuery = '';
  String _invoiceCustomerFilter = 'All';
  String _invoiceStatusFilter = 'All';

  final repository = AppDataRepository.instance;

  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _invoiceDateController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _invoiceNumberController = TextEditingController();

  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _advanceController = TextEditingController();

  bool _showDiscount = false;
  bool _showTax = false;
  bool _showAdvancePaid = false;

  bool _manualTotalOverride = false;
  final TextEditingController _manualTotalController = TextEditingController();
  bool _showDueDate = true;

  late List<InvoiceSection> _sections;

  @override
  void initState() {
    super.initState();
    repository.addListener(_onDataChanged);
    if (widget.initialEvent != null) {
      _loadEventForInvoice(widget.initialEvent!);
    } else {
      _resetFormToNew();
    }
  }

  @override
  void dispose() {
    repository.removeListener(_onDataChanged);
    _customerController.dispose();
    _venueController.dispose();
    _invoiceDateController.dispose();
    _dueDateController.dispose();
    _invoiceNumberController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _advanceController.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  void _loadEventForInvoice(EventModel event) {
    _customerController.text = event.manager;
    _venueController.text = event.venue;
    _invoiceDateController.text = AppDateUtils.getTodayDate();
    _dueDateController.text = event.date.isNotEmpty ? event.date : AppDateUtils.getDueDate(daysFromToday: 15);
    _invoiceNumberController.text = 'INV-2026-00${repository.invoices.length + 1}';
    _discountController.text = '0';
    _taxController.text = '18';
    _advanceController.text = event.amountReceived.toStringAsFixed(0);

    _showDiscount = false;
    _showTax = false;
    _showAdvancePaid = event.amountReceived > 0;

    _sections = [
      InvoiceSection(
        heading: event.title,
        items: [
          InvoiceItem(name: 'Event Contract Package', price: event.contractValue),
          ...event.services.map((s) => InvoiceItem(name: s, price: 0)),
        ],
      ),
    ];
    _mainTab = 1;
    _formSubTab = 0;
  }

  bool _hasValidCustomerPhone(InvoiceModel invoice) {
    if (invoice.customerName.trim().isEmpty) return false;
    final matchingCustomer = repository.customers.firstWhere(
      (c) => c.name.toLowerCase() == invoice.customerName.trim().toLowerCase(),
      orElse: () => CustomerModel(id: '', name: '', email: '', phone: '', totalEvents: 0),
    );
    return matchingCustomer.phone.trim().isNotEmpty && matchingCustomer.phone.trim().length >= 8;
  }

  Future<void> _sendViaWhatsApp(InvoiceModel invoice) async {
    final message = Uri.encodeComponent(
      "Hello ${invoice.customerName},\n\nHere is your invoice #${invoice.invoiceNumber} from Haya Event Management for venue ${invoice.venue}.\nTotal Amount: ₹${invoice.grandTotal.toStringAsFixed(0)}\nDue Date: ${invoice.dueDate}\n\nThank you for choosing us!",
    );
    final url = Uri.parse("https://wa.me/?text=$message");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  void _showRecordPaymentModal(BuildContext context, InvoiceModel inv) {
    final double remainingBalance = inv.balanceDue;

    if (remainingBalance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This invoice is already fully paid!')),
      );
      return;
    }

    final amountController = TextEditingController(text: remainingBalance.toStringAsFixed(0));
    String selectedMethod = 'UPI';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) => AlertDialog(
          title: Text('Record Payment - Invoice #${inv.invoiceNumber}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Client: ${inv.customerName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('Grand Total: ₹${inv.grandTotal.toStringAsFixed(0)} • Remaining Balance: ₹${remainingBalance.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Payment Amount (Max: ₹${remainingBalance.toStringAsFixed(0)}) *',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedMethod,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: ['UPI', 'Bank Transfer', 'Cash', 'Credit Card']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setStateModal(() => selectedMethod = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                if (amt <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid payment amount.')),
                  );
                  return;
                }
                if (amt > remainingBalance) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment amount (₹${amt.toStringAsFixed(0)}) cannot exceed remaining balance due of ₹${remainingBalance.toStringAsFixed(0)}.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final payment = PaymentModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  date: AppDateUtils.getTodayDate(),
                  eventType: 'Invoice #${inv.invoiceNumber} Payment (${inv.customerName})',
                  amount: amt,
                  method: selectedMethod,
                );
                await repository.addPayment(payment);

                inv.advancePaid = inv.advancePaid + amt;
                inv.showAdvancePaid = true;
                await repository.saveInvoice(inv);

                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('₹${amt.toStringAsFixed(0)} payment recorded for Invoice #${inv.invoiceNumber}! Remaining Balance: ₹${inv.balanceDue.toStringAsFixed(0)}')),
                  );
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              child: const Text('Convert & Save Payment'),
            ),
          ],
        ),
      ),
    );
  }

  void _resetFormToNew() {
    if (repository.draftInvoice != null) {
      final di = repository.draftInvoice!;
      _customerController.text = di.customerName;
      _venueController.text = di.venue;
      _invoiceDateController.text = di.invoiceDate;
      _dueDateController.text = di.dueDate;
      _invoiceNumberController.text = di.invoiceNumber;
      _showDueDate = di.showDueDate;
      _showDiscount = di.showDiscount;
      _discountController.text = di.discountAmount.toStringAsFixed(0);
      _showTax = di.showTax;
      _taxController.text = di.taxPercentage.toStringAsFixed(0);
      _showAdvancePaid = di.showAdvancePaid;
      _advanceController.text = di.advancePaid.toStringAsFixed(0);
      _manualTotalOverride = di.manualTotalOverride;
      _manualTotalController.text = di.manualGrandTotal.toStringAsFixed(0);
      _sections = di.sections
          .map((s) => InvoiceSection(
                heading: s.heading,
                items: s.items
                    .map((i) => InvoiceItem(name: i.name, qty: i.qty, rate: i.rate, price: i.price))
                    .toList(),
              ))
          .toList();
    } else {
      _customerController.text = '';
      _venueController.text = '';
      _invoiceDateController.text = AppDateUtils.getTodayDate();
      _dueDateController.text = AppDateUtils.getDueDate(daysFromToday: 15);
      _invoiceNumberController.text = 'INV-2026-00${repository.invoices.length + 1}';
      _discountController.text = '0';
      _taxController.text = '18';
      _advanceController.text = '0';
      _manualTotalController.text = '0';

      _showDiscount = false;
      _showTax = false;
      _showAdvancePaid = false;
      _manualTotalOverride = false;

      _sections = []; // No default dummy data filled in new invoice form
    }
  }

  void _loadInvoiceForEdit(InvoiceModel invoice) {
    _customerController.text = invoice.customerName;
    _venueController.text = invoice.venue;
    _invoiceDateController.text = invoice.invoiceDate;
    _dueDateController.text = invoice.dueDate;
    _invoiceNumberController.text = invoice.invoiceNumber;
    _showDueDate = invoice.showDueDate;

    _showDiscount = invoice.showDiscount;
    _discountController.text = invoice.discountAmount.toStringAsFixed(0);

    _showTax = invoice.showTax;
    _taxController.text = invoice.taxPercentage.toStringAsFixed(0);

    _showAdvancePaid = invoice.showAdvancePaid;
    _advanceController.text = invoice.advancePaid.toStringAsFixed(0);

    _manualTotalOverride = invoice.manualTotalOverride;
    _manualTotalController.text = invoice.manualGrandTotal.toStringAsFixed(0);

    // Deep copy sections
    _sections = invoice.sections
        .map((s) => InvoiceSection(
              heading: s.heading,
              items: s.items
                  .map((i) => InvoiceItem(
                        name: i.name,
                        qty: i.qty,
                        rate: i.rate,
                        price: i.price,
                      ))
                  .toList(),
            ))
        .toList();

    setState(() {
      _mainTab = 1;
      _formSubTab = 0;
    });
  }

  InvoiceModel _buildCurrentInvoice() {
    return InvoiceModel(
      invoiceNumber: _invoiceNumberController.text.trim().isEmpty
          ? 'INV-2026-001'
          : _invoiceNumberController.text.trim(),
      customerName: _customerController.text.trim(),
      venue: _venueController.text.trim(),
      invoiceDate: _invoiceDateController.text.trim(),
      dueDate: _dueDateController.text.trim(),
      showDueDate: _showDueDate,
      sections: _sections,
      showDiscount: _showDiscount,
      discountAmount: double.tryParse(_discountController.text.trim()) ?? 0.0,
      showTax: _showTax,
      taxPercentage: double.tryParse(_taxController.text.trim()) ?? 18.0,
      showAdvancePaid: _showAdvancePaid,
      advancePaid: double.tryParse(_advanceController.text.trim()) ?? 0.0,
      manualTotalOverride: _manualTotalOverride,
      manualGrandTotal: double.tryParse(_manualTotalController.text.trim()) ?? 0.0,
    );
  }

  void _saveCurrentInvoice() async {
    final invoice = _buildCurrentInvoice();
    await repository.saveInvoice(invoice);
    repository.clearInvoiceDraft();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice #${invoice.invoiceNumber} saved successfully!')),
      );
      setState(() {
        _mainTab = 0; // Return to All Invoices tab
      });
    }
  }

  void _addSection() {
    setState(() {
      _sections.add(
        InvoiceSection(
          heading: 'New Section Heading',
          items: [
            InvoiceItem(name: 'New Service / Item', price: 1000),
          ],
        ),
      );
    });
  }

  void _addItemToSection(int sectionIndex) {
    setState(() {
      _sections[sectionIndex].items.add(
            InvoiceItem(name: '', price: 0),
          );
    });
  }

  Future<bool> _onWillPop(BuildContext context) async {
    if (_mainTab == 0) return true;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You are editing an invoice. Do you want to save your work before going back?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'discard'), child: const Text('Discard', style: TextStyle(color: Colors.red))),
          TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, 'save'), child: const Text('Save Work')),
        ],
      ),
    );

    if (result == 'save') {
      final inv = _buildCurrentInvoice();
      repository.saveInvoiceDraft(inv);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice draft saved locally!')),
        );
      }
      return true;
    } else if (result == 'discard') {
      repository.clearInvoiceDraft();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _mainTab == 0,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop(context);
        if (shouldPop && context.mounted) {
          if (widget.onBack != null) {
            widget.onBack!();
          } else {
            Navigator.pop(context);
          }
        }
      },
      child: Material(
        color: AppTheme.background,
        child: Column(
          children: [
            // Main Navigation Bar (2 Tabs)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  if (widget.onBack != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
                      onPressed: widget.onBack,
                    ),
                  Expanded(
                    child: Row(
                      children: [
                        _buildMainTabButton(0, Icons.receipt_long, 'All Invoices (${repository.invoices.length})'),
                        const SizedBox(width: 8),
                        _buildMainTabButton(1, Icons.tune, 'Invoice Form & Customization'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _resetFormToNew();
                        _mainTab = 1;
                        _formSubTab = 0;
                      });
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('+ Create New Invoice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content View based on _mainTab
            Expanded(
              child: _mainTab == 0 ? _buildAllInvoicesTab() : _buildInvoiceCustomizationTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTabButton(int index, IconData icon, String title) {
    final bool isSelected = _mainTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _mainTab = index;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: AppTheme.primary) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? AppTheme.primaryDark : const Color(0xFF6B7280)),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primaryDark : const Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TAB 1: ALL INVOICES LIST
  // ============================================================

  Widget _buildAllInvoicesTab() {
    final customerNames = ['All', ...repository.activeCustomers.map((c) => c.name)];
    final statuses = ['All', 'Pending', 'Partially Paid', 'Paid'];

    final filteredInvoices = repository.activeInvoices.where((inv) {
      if (_invoiceCustomerFilter != 'All' && inv.customerName.toLowerCase() != _invoiceCustomerFilter.toLowerCase()) {
        return false;
      }
      if (_invoiceStatusFilter != 'All') {
        final st = inv.status.displayName.toLowerCase();
        if (st != _invoiceStatusFilter.toLowerCase()) return false;
      }
      if (_invoiceSearchQuery.isNotEmpty) {
        final q = _invoiceSearchQuery.toLowerCase();
        if (!inv.invoiceNumber.toLowerCase().contains(q) && !inv.customerName.toLowerCase().contains(q) && !inv.venue.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    return Container(
      color: AppTheme.background,
      child: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _invoiceCustomerFilter,
                        decoration: const InputDecoration(labelText: 'Customer', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        items: customerNames.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => setState(() => _invoiceCustomerFilter = v ?? 'All'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _invoiceStatusFilter,
                        decoration: const InputDecoration(labelText: 'Status', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setState(() => _invoiceStatusFilter = v ?? 'All'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (val) => setState(() => _invoiceSearchQuery = val),
                  decoration: const InputDecoration(
                    hintText: 'Search by invoice #, client, venue...',
                    prefixIcon: Icon(Icons.search, size: 18),
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredInvoices.isEmpty
                ? const Center(child: Text('No invoices match the filter.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredInvoices.length,
                    itemBuilder: (context, index) {
                      final inv = filteredInvoices[index];
                      final double balance = inv.balanceDue;

                      Color badgeBg = const Color(0xFFDCFCE7);
                      Color badgeFg = const Color(0xFF16A34A);
                      String badgeText = inv.status.displayName.toUpperCase();

                      if (inv.status == InvoiceStatus.partiallyPaid) {
                        badgeBg = const Color(0xFFFEF3C7);
                        badgeFg = const Color(0xFFD97706);
                      } else if (inv.status == InvoiceStatus.pending) {
                        badgeBg = const Color(0xFFFEE2E2);
                        badgeFg = const Color(0xFFDC2626);
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.receipt_long, color: AppTheme.primary, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(inv.customerName.isEmpty ? 'Walk-in Client' : inv.customerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                                          Text('#${inv.invoiceNumber} • Date: ${inv.invoiceDate}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(12)),
                                    child: Text(badgeText, style: TextStyle(color: badgeFg, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Venue:', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                                      Text(inv.venue.isEmpty ? 'N/A' : inv.venue, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Total: ₹${inv.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                                      if (inv.showAdvancePaid)
                                        Text('Balance Due: ₹${balance.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _showRecordPaymentModal(context, inv),
                                    icon: const Icon(Icons.account_balance_wallet_outlined, size: 14),
                                    label: const Text('Record Payment', style: TextStyle(fontSize: 11)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: Size.zero,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () => _loadInvoiceForEdit(inv),
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text('Edit'),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      await InvoicePdfService.printInvoice(inv);
                                    },
                                    icon: const Icon(Icons.print, size: 16),
                                    label: const Text('Print / PDF'),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    tooltip: 'Delete Invoice',
                                    onPressed: () async {
                                      final confirm = await AppDeleteConfirmationDialog.show(
                                        context,
                                        title: 'Delete Invoice',
                                        itemDetails: 'Invoice #${inv.invoiceNumber} - ${inv.customerName} (₹${inv.grandTotal.toStringAsFixed(0)})',
                                      );
                                      if (confirm) {
                                        await repository.deleteInvoice(inv.invoiceNumber);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 2: INVOICE FORM & CUSTOMIZATION VIEW
  // ============================================================

  Widget _buildInvoiceCustomizationTab() {
    return Column(
      children: [
        // Sub-segmented selector (Form vs Preview)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _formSubTab = 0),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _formSubTab == 0 ? AppTheme.primary : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_document, size: 16, color: _formSubTab == 0 ? Colors.white : const Color(0xFF4B5563)),
                        const SizedBox(width: 6),
                        Text('1. Form Builder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _formSubTab == 0 ? Colors.white : const Color(0xFF4B5563))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _formSubTab = 1),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _formSubTab == 1 ? AppTheme.primary : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.preview_outlined, size: 16, color: _formSubTab == 1 ? Colors.white : const Color(0xFF4B5563)),
                        const SizedBox(width: 6),
                        Text('2. Template Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _formSubTab == 1 ? Colors.white : const Color(0xFF4B5563))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Body
        Expanded(
          child: _formSubTab == 0 ? _buildInvoiceFormBuilder() : _buildInvoiceTemplatePreview(),
        ),
      ],
    );
  }

  // FORM BUILDER
  Widget _buildInvoiceFormBuilder() {
    final invoice = _buildCurrentInvoice();
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Details Card
          _buildFormCard(
            title: '1. Customer & Event Details',
            icon: Icons.person_outline,
            child: Column(
              children: [
                if (isMobile) ...[
                  TextField(
                    controller: _customerController,
                    decoration: const InputDecoration(labelText: 'Customer Name (Optional)'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _venueController,
                    decoration: const InputDecoration(labelText: 'Venue Location *'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _invoiceNumberController,
                    decoration: const InputDecoration(labelText: 'Invoice Number'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _invoiceDateController,
                    decoration: const InputDecoration(labelText: 'Invoice Date'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _dueDateController,
                    decoration: const InputDecoration(labelText: 'Due Date'),
                    onChanged: (_) => setState(() {}),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customerController,
                          decoration: const InputDecoration(labelText: 'Customer Name (Optional)'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _venueController,
                          decoration: const InputDecoration(labelText: 'Venue Location *'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _invoiceNumberController,
                          decoration: const InputDecoration(labelText: 'Invoice Number'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _invoiceDateController,
                          decoration: const InputDecoration(labelText: 'Invoice Date'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _dueDateController,
                          decoration: const InputDecoration(labelText: 'Due Date'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Grouped Sections & Items Header Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('2. Invoice Sections & Tables', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                      SizedBox(height: 2),
                      Text('Group items under custom headings (e.g. Food, Salads, Tea, Decor)', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addSection,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('+ Create Section Heading'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // List of Section Editors
          ...List.generate(_sections.length, (sIdx) {
            final section = _sections[sIdx];
            return _InvoiceSectionEditor(
              key: ObjectKey(section),
              section: section,
              isMobile: isMobile,
              onChanged: () => setState(() {}),
              onDeleteSection: () {
                setState(() {
                  _sections.removeAt(sIdx);
                });
              },
              onAddItem: () => _addItemToSection(sIdx),
            );
          }),

          const SizedBox(height: 12),

          // Add Section Heading CTA Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _addSection,
              icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryDark),
              label: const Text(
                '+ Add Another Section Heading (e.g. Beverages, Dessert)',
                style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: Totals & Optional Toggles Card
          _buildFormCard(
            title: '3. Calculations & Optional Print Toggles',
            icon: Icons.calculate_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    title: const Text('Apply Discount (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Enable to enter discount amount and print on invoice'),
                    value: _showDiscount,
                    activeColor: AppTheme.primary,
                    onChanged: (val) => setState(() => _showDiscount = val),
                  ),
                ),
                if (_showDiscount)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: TextField(
                      controller: _discountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Discount Amount (₹)'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),

                const Divider(),

                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    title: const Text('Apply Tax / GST (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Enable to include tax percentage on invoice'),
                    value: _showTax,
                    activeColor: AppTheme.primary,
                    onChanged: (val) => setState(() => _showTax = val),
                  ),
                ),
                if (_showTax)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: TextField(
                      controller: _taxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tax Percentage (%)'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),

                const Divider(),

                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    title: const Text('Advance Paid (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Enable to deduct advance paid and show Balance Due'),
                    value: _showAdvancePaid,
                    activeColor: AppTheme.primary,
                    onChanged: (val) => setState(() => _showAdvancePaid = val),
                  ),
                ),
                if (_showAdvancePaid)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: TextField(
                      controller: _advanceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Advance Amount Received (₹)'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),

                const Divider(),

                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    title: const Text('Manual Total Amount Override (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Enable to directly edit/control the total amount without itemizing'),
                    value: _manualTotalOverride,
                    activeColor: AppTheme.primary,
                    onChanged: (val) => setState(() => _manualTotalOverride = val),
                  ),
                ),
                if (_manualTotalOverride)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: TextField(
                      controller: _manualTotalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Custom Total Amount (₹)'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),

                const Divider(),

                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    title: const Text('Show Due Date on PDF (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Enable to display Due Date on PDF and template preview'),
                    value: _showDueDate,
                    activeColor: AppTheme.primary,
                    onChanged: (val) => setState(() => _showDueDate = val),
                  ),
                ),

                const SizedBox(height: 16),

                // Calculation Summary Display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('Raw Subtotal', '₹${invoice.rawSubtotal.toStringAsFixed(0)}'),
                      if (_showDiscount) ...[
                        const SizedBox(height: 6),
                        _buildSummaryRow('Discount', '- ₹${invoice.calculatedDiscount.toStringAsFixed(0)}', isNegative: true),
                      ],
                      if (_showTax) ...[
                        const SizedBox(height: 6),
                        _buildSummaryRow('Tax (${invoice.taxPercentage.toStringAsFixed(0)}%)', '+ ₹${invoice.calculatedTax.toStringAsFixed(0)}'),
                      ],
                      const Divider(height: 16),
                      _buildSummaryRow('Grand Total', '₹${invoice.grandTotal.toStringAsFixed(0)}', isBold: true),
                      if (_showAdvancePaid) ...[
                        const SizedBox(height: 6),
                        _buildSummaryRow('Advance Paid', '₹${invoice.calculatedAdvance.toStringAsFixed(0)}', color: const Color(0xFF10B981)),
                        const Divider(height: 16),
                        _buildSummaryRow('Balance Due', '₹${invoice.balanceDue.toStringAsFixed(0)}', isBold: true, color: AppTheme.primaryDark),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons: Save Invoice & Print
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _saveCurrentInvoice,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Invoice to List'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _formSubTab = 1),
                    icon: const Icon(Icons.preview_outlined),
                    label: const Text('Template Preview'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildFormCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // LIVE TEMPLATE PREVIEW
  Widget _buildInvoiceTemplatePreview() {
    final invoice = _buildCurrentInvoice();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Company Logo & Brand
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primary, width: 2),
                          ),
                          child: const Center(
                            child: Text('H', style: TextStyle(color: AppTheme.primary, fontSize: 22, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(repository.companyName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                            const Text('Making dreams into reality', style: TextStyle(fontSize: 10, color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Address: ${repository.companyAddress}', style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                            Text('Phone: ${repository.companyPhone}', style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                            Text('Email: ${repository.companyEmail}', style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('INVOICE', style: TextStyle(color: AppTheme.primaryDark, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 6),
                        Text('# ${invoice.invoiceNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Date: ${invoice.invoiceDate}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                        if (_showDueDate)
                          Text('Due Date: ${invoice.dueDate}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 30),

                // Billed To & Venue
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Billed To:', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.bold)),
                          Text(invoice.customerName.isEmpty ? 'N/A' : invoice.customerName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Event Venue:', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.bold)),
                          Text(invoice.venue.isEmpty ? 'N/A' : invoice.venue, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Sections & Tables
                ...invoice.sections.map((section) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        color: const Color(0xFF1E293B),
                        child: Text(
                          section.heading,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      Table(
                        border: TableBorder.all(color: const Color(0xFFE5E7EB)),
                        columnWidths: const {
                          0: FlexColumnWidth(3.5),
                          1: FlexColumnWidth(1.2),
                          2: FlexColumnWidth(1.5),
                          3: FlexColumnWidth(1.8),
                        },
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                            children: const [
                              Padding(padding: EdgeInsets.all(8), child: Text('Item Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                              Padding(padding: EdgeInsets.all(8), child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                              Padding(padding: EdgeInsets.all(8), child: Text('Rate', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                              Padding(padding: EdgeInsets.all(8), child: Text('Amount (₹)', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            ],
                          ),
                          ...section.items.map((item) {
                            return TableRow(
                              children: [
                                Padding(padding: const EdgeInsets.all(8), child: Text(item.name.isEmpty ? '-' : item.name, style: const TextStyle(fontSize: 12))),
                                Padding(padding: const EdgeInsets.all(8), child: Text(item.qty != null ? '${item.qty}' : '-', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                                Padding(padding: const EdgeInsets.all(8), child: Text(item.rate != null ? '₹${item.rate!.toStringAsFixed(0)}' : '-', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                                Padding(padding: const EdgeInsets.all(8), child: Text('₹${item.price.toStringAsFixed(0)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                              ],
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }),

                // Totals
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 250,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow('Subtotal', '₹${invoice.rawSubtotal.toStringAsFixed(0)}'),
                        if (invoice.showDiscount) ...[
                          const SizedBox(height: 6),
                          _buildSummaryRow('Discount', '- ₹${invoice.calculatedDiscount.toStringAsFixed(0)}', isNegative: true),
                        ],
                        if (invoice.showTax) ...[
                          const SizedBox(height: 6),
                          _buildSummaryRow('Tax (${invoice.taxPercentage.toStringAsFixed(0)}%)', '+ ₹${invoice.calculatedTax.toStringAsFixed(0)}'),
                        ],
                        const Divider(height: 16),
                        _buildSummaryRow('Grand Total', '₹${invoice.grandTotal.toStringAsFixed(0)}', isBold: true),
                        if (invoice.showAdvancePaid) ...[
                          const SizedBox(height: 6),
                          _buildSummaryRow('Advance Paid', '₹${invoice.calculatedAdvance.toStringAsFixed(0)}', color: const Color(0xFF10B981)),
                          const Divider(height: 16),
                          _buildSummaryRow('Balance Due', '₹${invoice.balanceDue.toStringAsFixed(0)}', isBold: true, color: AppTheme.primaryDark),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Footer Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Thank you for choosing Haya Event Management!', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final pdfBytes = await InvoicePdfService.generatePdfBytes(invoice);
                            await Printing.sharePdf(bytes: pdfBytes, filename: 'Invoice_${invoice.invoiceNumber}.pdf');
                          },
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Export PDF'),
                        ),
                        if (_hasValidCustomerPhone(invoice)) ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _sendViaWhatsApp(invoice),
                            icon: const Icon(Icons.share, size: 16),
                            label: const Text('WhatsApp'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              minimumSize: const Size(0, 38),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await InvoicePdfService.printInvoice(invoice);
                          },
                          icon: const Icon(Icons.print, size: 16),
                          label: const Text('Print'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            minimumSize: const Size(0, 38),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, bool isNegative = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? const Color(0xFF4B5563),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isNegative ? Colors.red : (color ?? const Color(0xFF111827)),
          ),
        ),
      ],
    );
  }
}

class _InvoiceSectionEditor extends StatefulWidget {
  final InvoiceSection section;
  final bool isMobile;
  final VoidCallback onChanged;
  final VoidCallback onDeleteSection;
  final VoidCallback onAddItem;

  const _InvoiceSectionEditor({
    required Key key,
    required this.section,
    required this.isMobile,
    required this.onChanged,
    required this.onDeleteSection,
    required this.onAddItem,
  }) : super(key: key);

  @override
  State<_InvoiceSectionEditor> createState() => _InvoiceSectionEditorState();
}

class _InvoiceSectionEditorState extends State<_InvoiceSectionEditor> {
  late TextEditingController headingController;

  @override
  void initState() {
    super.initState();
    headingController = TextEditingController(text: widget.section.heading);
  }

  @override
  void dispose() {
    headingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: headingController,
                  decoration: const InputDecoration(
                    labelText: 'Section Heading (e.g. Food & Catering, Salads, Tea)',
                    prefixIcon: Icon(Icons.title, size: 18),
                  ),
                  onChanged: (val) {
                    widget.section.heading = val;
                    widget.onChanged();
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete Section',
                onPressed: widget.onDeleteSection,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Items Table Title
          const Text(
            'Items (Name & Price are mandatory; Qty & Rate optional):',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 10),

          // List of Item Rows
          Column(
            children: List.generate(widget.section.items.length, (iIdx) {
              final item = widget.section.items[iIdx];
              return _InvoiceItemRow(
                key: ObjectKey(item),
                item: item,
                isMobile: widget.isMobile,
                onChanged: widget.onChanged,
                onDelete: () {
                  setState(() {
                    widget.section.items.removeAt(iIdx);
                  });
                  widget.onChanged();
                },
              );
            }),
          ),

          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.onAddItem,
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: Text('Add Item to ${widget.section.heading}'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceItemRow extends StatefulWidget {
  final InvoiceItem item;
  final bool isMobile;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _InvoiceItemRow({
    required Key key,
    required this.item,
    required this.isMobile,
    required this.onChanged,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<_InvoiceItemRow> createState() => _InvoiceItemRowState();
}

class _InvoiceItemRowState extends State<_InvoiceItemRow> {
  late TextEditingController nameController;
  late TextEditingController qtyController;
  late TextEditingController rateController;
  late TextEditingController priceController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item.name);
    qtyController = TextEditingController(text: widget.item.qty != null ? '${widget.item.qty}' : '');
    rateController = TextEditingController(text: widget.item.rate != null ? '${widget.item.rate}' : '');
    priceController = TextEditingController(text: '${widget.item.price.toStringAsFixed(0)}');
  }

  @override
  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    rateController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMobile) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'Item Name *',
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onChanged: (val) {
                      widget.item.name = val;
                      widget.onChanged();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'Qty (Opt)',
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (val) {
                      widget.item.qty = double.tryParse(val);
                      if (widget.item.qty != null && widget.item.rate != null) {
                        widget.item.calculatePrice();
                        priceController.text = widget.item.price.toStringAsFixed(0);
                      }
                      widget.onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: rateController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'Rate (Opt)',
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (val) {
                      widget.item.rate = double.tryParse(val);
                      if (widget.item.qty != null && widget.item.rate != null) {
                        widget.item.calculatePrice();
                        priceController.text = widget.item.price.toStringAsFixed(0);
                      }
                      widget.onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'Price *',
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (val) {
                      widget.item.price = double.tryParse(val) ?? 0.0;
                      widget.onChanged();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Item Name
          Expanded(
            flex: 3,
            child: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'Item Name *',
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (val) {
                widget.item.name = val;
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),

          // Qty
          Expanded(
            flex: 2,
            child: TextField(
              controller: qtyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'Qty (Opt)',
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (val) {
                widget.item.qty = double.tryParse(val);
                if (widget.item.qty != null && widget.item.rate != null) {
                  widget.item.calculatePrice();
                  priceController.text = widget.item.price.toStringAsFixed(0);
                }
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),

          // Rate
          Expanded(
            flex: 2,
            child: TextField(
              controller: rateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'Rate (Opt)',
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (val) {
                widget.item.rate = double.tryParse(val);
                if (widget.item.qty != null && widget.item.rate != null) {
                  widget.item.calculatePrice();
                  priceController.text = widget.item.price.toStringAsFixed(0);
                }
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),

          // Price
          Expanded(
            flex: 2,
            child: TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'Price *',
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (val) {
                widget.item.price = double.tryParse(val) ?? 0.0;
                widget.onChanged();
              },
            ),
          ),

          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }
}
