import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../data/app_data_repository.dart';
import '../models/invoice_model.dart';
import '../models/quotation_model.dart';
import '../services/quotation_pdf_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatter.dart';
import '../widgets/delete_confirmation_dialog.dart';

class CreateQuotationScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const CreateQuotationScreen({
    super.key,
    this.onBack,
  });

  @override
  State<CreateQuotationScreen> createState() => _CreateQuotationScreenState();
}

class _CreateQuotationScreenState extends State<CreateQuotationScreen> {
  int _mainTab = 0; // 0 = All Quotations, 1 = Form Builder & Customizer
  int _formSubTab = 0; // 0 = Edit Form, 1 = Template Preview
  String? _editingQuotationId;

  final repository = AppDataRepository.instance;

  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _quotationDateController = TextEditingController();
  final TextEditingController _quoteNumberController = TextEditingController();
  final TextEditingController _eventTypeController = TextEditingController();

  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _advanceController = TextEditingController();
  final TextEditingController _manualTotalController = TextEditingController();

  bool _showDiscount = false;
  bool _showTax = false;
  bool _showAdvancePaid = false;
  bool _manualTotalOverride = false;

  late List<InvoiceSection> _sections;

  @override
  void initState() {
    super.initState();
    repository.addListener(_onDataChanged);
    _resetFormToNew();
  }

  @override
  void dispose() {
    repository.removeListener(_onDataChanged);
    _customerController.dispose();
    _venueController.dispose();
    _quotationDateController.dispose();
    _quoteNumberController.dispose();
    _eventTypeController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _advanceController.dispose();
    _manualTotalController.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  void _resetFormToNew() {
    _editingQuotationId = null;
    _customerController.text = '';
    _venueController.text = '';
    _quotationDateController.text = AppDateUtils.getTodayDate();
    _quoteNumberController.text = 'QT-2026-00${repository.quotations.length + 1}';
    _eventTypeController.text = 'Wedding Event';
    _discountController.text = '0';
    _taxController.text = '18';
    _advanceController.text = '0';
    _manualTotalController.text = '0';

    _showDiscount = false;
    _showTax = false;
    _showAdvancePaid = false;
    _manualTotalOverride = false;

    _sections = [
      InvoiceSection(
        heading: 'Event Services',
        items: [
          InvoiceItem(name: 'Main Event Package', price: 0),
        ],
      ),
    ];
  }

  void _loadQuotationForEdit(QuotationModel quotation) {
    _editingQuotationId = quotation.id;
    _customerController.text = quotation.customerName;
    _venueController.text = quotation.venue;
    _quotationDateController.text = quotation.quotationDate;
    _quoteNumberController.text = quotation.quoteNumber;
    _eventTypeController.text = quotation.eventType;

    _showDiscount = quotation.showDiscount;
    _discountController.text = quotation.discountAmount.toStringAsFixed(0);

    _showTax = quotation.showTax;
    _taxController.text = quotation.taxPercentage.toStringAsFixed(0);

    _showAdvancePaid = quotation.showAdvancePaid;
    _advanceController.text = quotation.advancePaid.toStringAsFixed(0);

    _manualTotalOverride = quotation.manualTotalOverride;
    _manualTotalController.text = quotation.manualGrandTotal > 0
        ? quotation.manualGrandTotal.toStringAsFixed(0)
        : quotation.totalAmount.toStringAsFixed(0);

    _sections = quotation.sections
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

    if (_sections.isEmpty) {
      _sections = [
        InvoiceSection(
          heading: 'Event Services',
          items: [
            InvoiceItem(name: 'Main Event Package', price: quotation.totalAmount),
          ],
        ),
      ];
    }

    setState(() {
      _mainTab = 1;
      _formSubTab = 0;
    });
  }

  QuotationModel _buildCurrentQuotation() {
    return QuotationModel(
      id: _editingQuotationId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      quoteNumber: _quoteNumberController.text.trim().isEmpty
          ? 'QT-2026-001'
          : _quoteNumberController.text.trim(),
      customerName: _customerController.text.trim(),
      venue: _venueController.text.trim(),
      quotationDate: _quotationDateController.text.trim(),
      dueDate: '25 Sep 2026',
      eventType: _eventTypeController.text.trim(),
      sections: _sections,
      showDiscount: _showDiscount,
      discountAmount: double.tryParse(_discountController.text.trim()) ?? 0.0,
      showTax: _showTax,
      taxPercentage: double.tryParse(_taxController.text.trim()) ?? 18.0,
      showAdvancePaid: _showAdvancePaid,
      advancePaid: double.tryParse(_advanceController.text.trim()) ?? 0.0,
      manualTotalOverride: _manualTotalOverride,
      manualGrandTotal: double.tryParse(_manualTotalController.text.trim()) ?? 0.0,
      status: 'Sent',
    );
  }

  void _saveCurrentQuotation() async {
    final quotation = _buildCurrentQuotation();
    await repository.saveQuotation(quotation);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quotation #${quotation.quoteNumber} saved successfully!')),
      );
      setState(() {
        _mainTab = 0;
      });
    }
  }

  void _addSection() {
    setState(() {
      _sections.add(
        InvoiceSection(
          heading: 'New Section Heading (e.g. Beverages)',
          items: [
            InvoiceItem(name: 'New Item / Service', price: 1000),
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

  double _calculateItemsGrandTotal() {
    final rawSubtotal = _sections.fold(0.0, (sum, sec) => sum + sec.subtotal);
    final discount = _showDiscount ? (double.tryParse(_discountController.text.trim()) ?? 0.0) : 0.0;
    final subtotalAfterDiscount = (rawSubtotal - discount).clamp(0.0, double.infinity);
    final taxPct = _showTax ? (double.tryParse(_taxController.text.trim()) ?? 18.0) : 0.0;
    final tax = subtotalAfterDiscount * (taxPct / 100);
    return subtotalAfterDiscount + tax;
  }

  Future<void> _handleBackNavigation() async {
    if (_mainTab == 0) {
      if (widget.onBack != null) {
        widget.onBack!();
      } else if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      return;
    }

    final String? result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have entered or modified data in this quotation. What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save & Exit'),
          ),
        ],
      ),
    );

    if (result == 'save') {
      _saveCurrentQuotation();
    } else if (result == 'discard') {
      _resetFormToNew();
      if (widget.onBack != null && repository.activeQuotations.isEmpty) {
        widget.onBack!();
      } else {
        setState(() {
          _mainTab = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _mainTab == 0 && widget.onBack == null,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackNavigation();
      },
      child: Material(
        color: AppTheme.background,
        child: Column(
          children: [
            // Navigation Bar (2 Tabs)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  if (widget.onBack != null || _mainTab == 1)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
                      onPressed: _handleBackNavigation,
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildMainTabButton(0, Icons.description_outlined, 'All Quotations (${repository.quotations.length})'),
                          const SizedBox(width: 8),
                          _buildMainTabButton(1, Icons.tune, 'Quotation Form & Customization'),
                        ],
                      ),
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
                    label: LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        if (screenWidth < 600) {
                          return const Text('+ New Quote');
                        }
                        return const Text('+ Create New Quotation');
                      },
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: _mainTab == 0 ? _buildAllQuotationsTab() : _buildQuotationCustomizationTab(),
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

  // TAB 1: ALL QUOTATIONS LIST
  Widget _buildAllQuotationsTab() {
    final quotations = repository.activeQuotations;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: quotations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.description_outlined, size: 64, color: Color(0xFF9CA3AF)),
                  const SizedBox(height: 12),
                  const Text('No quotations created yet.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _resetFormToNew();
                        _mainTab = 1;
                        _formSubTab = 0;
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create First Quotation'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: quotations.length,
              itemBuilder: (context, index) {
                final q = quotations[index];

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
                                  child: const Icon(Icons.description_outlined, color: AppTheme.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(q.customerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                                    Text('#${q.quoteNumber} • Date: ${q.quotationDate}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(q.status, style: const TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.bold)),
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
                                const Text('Event / Venue:', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                                Text(q.venue.isEmpty ? q.eventType : q.venue, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Total Quoted Amount:', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                                Text('₹${q.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _loadQuotationForEdit(q),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Edit'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await QuotationPdfService.printQuotation(q);
                              },
                              icon: const Icon(Icons.print, size: 16),
                              label: const Text('Print / PDF'),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                              tooltip: 'Delete Quotation',
                              onPressed: () async {
                                final confirm = await AppDeleteConfirmationDialog.show(
                                  context,
                                  title: 'Delete Quotation',
                                  itemDetails: 'Quotation #${q.quoteNumber} - ${q.customerName} (₹${q.totalAmount.toStringAsFixed(0)})',
                                );
                                if (confirm) {
                                  await repository.deleteQuotation(q.id);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _resetFormToNew();
            _mainTab = 1;
            _formSubTab = 0;
          });
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // TAB 2: QUOTATION FORM & CUSTOMIZATION VIEW
  Widget _buildQuotationCustomizationTab() {
    return Column(
      children: [
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
        Expanded(
          child: _formSubTab == 0 ? _buildQuotationFormBuilder() : _buildQuotationTemplatePreview(),
        ),
      ],
    );
  }

  // FORM BUILDER
  Widget _buildQuotationFormBuilder() {
    final quotation = _buildCurrentQuotation();
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormCard(
            title: '1. Customer & Event Details',
            icon: Icons.person_outline,
            child: Column(
              children: [
                if (isMobile) ...[
                  TextField(
                    controller: _customerController,
                    decoration: const InputDecoration(labelText: 'Customer Name *'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _venueController,
                    decoration: const InputDecoration(labelText: 'Venue / Location *'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _quoteNumberController,
                    decoration: const InputDecoration(labelText: 'Quote Number'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _quotationDateController,
                    decoration: const InputDecoration(labelText: 'Quotation Date'),
                    onChanged: (_) => setState(() {}),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customerController,
                          decoration: const InputDecoration(labelText: 'Customer Name *'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _venueController,
                          decoration: const InputDecoration(labelText: 'Venue / Location *'),
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
                          controller: _quoteNumberController,
                          decoration: const InputDecoration(labelText: 'Quote Number'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _quotationDateController,
                          decoration: const InputDecoration(labelText: 'Quotation Date'),
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
                      Text('2. Quotation Sections & Item Tables', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                      SizedBox(height: 2),
                      Text('Group items under custom headings (e.g. Catering, Decor, Lighting)', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
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

          ...List.generate(_sections.length, (sIdx) {
            final section = _sections[sIdx];
            return _QuotationSectionEditor(
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

          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _addSection,
              icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryDark),
              label: const Text(
                '+ Add Another Section Heading (e.g. Sound, Florist)',
                style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 24),

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
                    subtitle: const Text('Enable to enter discount amount and print on quotation'),
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
                    subtitle: const Text('Enable to include tax percentage on quotation'),
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
                    onChanged: (val) {
                      setState(() {
                        _manualTotalOverride = val;
                        if (val) {
                          final calculated = _calculateItemsGrandTotal();
                          final currentManualVal = double.tryParse(_manualTotalController.text.trim()) ?? 0.0;
                          if (currentManualVal <= 0 || currentManualVal == calculated) {
                            _manualTotalController.text = calculated > 0 ? calculated.toStringAsFixed(0) : '0';
                          }
                        }
                      });
                    },
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
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Quoted Amount:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                Text('₹${quotation.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _saveCurrentQuotation,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Quotation to List'),
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
  Widget _buildQuotationTemplatePreview() {
    final quotation = _buildCurrentQuotation();

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
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Haya', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                            Text('Event Management', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
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
                          child: const Text('QUOTATION', style: TextStyle(color: AppTheme.primaryDark, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 6),
                        Text('# ${quotation.quoteNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Date: ${quotation.quotationDate}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 30),

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
                          const Text('Quotation For:', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.bold)),
                          Text(quotation.customerName.isEmpty ? 'N/A' : quotation.customerName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Event / Venue:', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.bold)),
                          Text(quotation.venue.isEmpty ? quotation.eventType : quotation.venue, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                ...quotation.sections.map((section) {
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

                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 250,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Quoted Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4B5563))),
                        Text('₹${quotation.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Thank you for choosing Haya Event Management!', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final pdfBytes = await QuotationPdfService.generatePdfBytes(quotation);
                            await Printing.sharePdf(bytes: pdfBytes, filename: 'Quotation_${quotation.quoteNumber}.pdf');
                          },
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Export PDF'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await QuotationPdfService.printQuotation(quotation);
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
}

class _QuotationSectionEditor extends StatefulWidget {
  final InvoiceSection section;
  final bool isMobile;
  final VoidCallback onChanged;
  final VoidCallback onDeleteSection;
  final VoidCallback onAddItem;

  const _QuotationSectionEditor({
    required Key key,
    required this.section,
    required this.isMobile,
    required this.onChanged,
    required this.onDeleteSection,
    required this.onAddItem,
  }) : super(key: key);

  @override
  State<_QuotationSectionEditor> createState() => _QuotationSectionEditorState();
}

class _QuotationSectionEditorState extends State<_QuotationSectionEditor> {
  late TextEditingController headingController;

  @override
  void initState() {
    super.initState();
    headingController = TextEditingController(text: widget.section.heading);
  }

  @override
  void didUpdateWidget(covariant _QuotationSectionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section || headingController.text != widget.section.heading) {
      headingController.text = widget.section.heading;
    }
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
                    labelText: 'Section Heading (e.g. Catering, Decor, Lighting)',
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

          const Text(
            'Items (Name & Price required; Qty & Rate optional):',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 10),

          Column(
            children: List.generate(widget.section.items.length, (iIdx) {
              final item = widget.section.items[iIdx];
              return _QuotationItemRow(
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

class _QuotationItemRow extends StatefulWidget {
  final InvoiceItem item;
  final bool isMobile;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _QuotationItemRow({
    required Key key,
    required this.item,
    required this.isMobile,
    required this.onChanged,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<_QuotationItemRow> createState() => _QuotationItemRowState();
}

class _QuotationItemRowState extends State<_QuotationItemRow> {
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
  void didUpdateWidget(covariant _QuotationItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      nameController.text = widget.item.name;
      qtyController.text = widget.item.qty != null ? '${widget.item.qty}' : '';
      rateController.text = widget.item.rate != null ? '${widget.item.rate}' : '';
      priceController.text = widget.item.price.toStringAsFixed(0);
    }
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
