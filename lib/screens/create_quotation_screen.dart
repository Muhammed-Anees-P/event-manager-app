import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/app_data_repository.dart';
import '../models/quotation_model.dart';
import '../models/invoice_model.dart';
import '../models/customer_model.dart';
import '../services/quotation_pdf_service.dart';
import '../theme/app_theme.dart';
import 'create_invoice_screen.dart';

class CreateQuotationScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final QuotationModel? initialQuotation;

  const CreateQuotationScreen({
    super.key,
    this.onBack,
    this.initialQuotation,
  });

  @override
  State<CreateQuotationScreen> createState() => _CreateQuotationScreenState();
}

class _CreateQuotationScreenState extends State<CreateQuotationScreen> {
  int _mainTab = 0; // 0 = All Quotations, 1 = Quotation Form & Template Customization
  int _formSubTab = 0; // 0 = Edit Form, 1 = Template Preview

  final repository = AppDataRepository.instance;

  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _quotationDateController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _quoteNumberController = TextEditingController();

  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _advanceController = TextEditingController();

  bool _showDiscount = false;
  bool _showTax = true;
  bool _showAdvancePaid = false;

  late List<InvoiceSection> _sections;

  @override
  void initState() {
    super.initState();
    repository.addListener(_onDataChanged);
    if (widget.initialQuotation != null) {
      _loadQuotationForEdit(widget.initialQuotation!);
    } else {
      _resetFormToNew();
    }
  }

  @override
  void dispose() {
    repository.removeListener(_onDataChanged);
    _customerController.dispose();
    _venueController.dispose();
    _quotationDateController.dispose();
    _dueDateController.dispose();
    _quoteNumberController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _advanceController.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  String _getTodayFormatted() {
    final now = DateTime.now();
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${now.day} ${months[now.month]} ${now.year}';
  }

  void _resetFormToNew() {
    final customers = repository.customers;
    _customerController.text = customers.isNotEmpty ? customers.first.name : '';
    _venueController.text = '';
    _quotationDateController.text = _getTodayFormatted();
    _dueDateController.text = _getTodayFormatted();
    _quoteNumberController.text = 'QT-2026-00${repository.quotations.length + 1}';
    _discountController.text = '0';
    _taxController.text = '18';
    _advanceController.text = '0';

    _showDiscount = false;
    _showTax = true;
    _showAdvancePaid = false;
    _sections = [];
  }

  void _loadQuotationForEdit(QuotationModel q) {
    _customerController.text = q.customerName;
    _venueController.text = q.venue;
    _quotationDateController.text = q.quotationDate;
    _dueDateController.text = q.dueDate;
    _quoteNumberController.text = q.quoteNumber;

    _showDiscount = q.showDiscount;
    _discountController.text = q.discountAmount.toStringAsFixed(0);

    _showTax = q.showTax;
    _taxController.text = q.taxPercentage.toStringAsFixed(0);

    _showAdvancePaid = q.showAdvancePaid;
    _advanceController.text = q.advancePaid.toStringAsFixed(0);

    _sections = q.sections
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

  QuotationModel _buildCurrentQuotation() {
    return QuotationModel(
      id: widget.initialQuotation?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      quoteNumber: _quoteNumberController.text.trim().isEmpty ? 'QT-2026-001' : _quoteNumberController.text.trim(),
      customerName: _customerController.text.trim(),
      venue: _venueController.text.trim(),
      quotationDate: _quotationDateController.text.trim(),
      dueDate: _dueDateController.text.trim(),
      sections: _sections,
      showDiscount: _showDiscount,
      discountAmount: double.tryParse(_discountController.text.trim()) ?? 0.0,
      showTax: _showTax,
      taxPercentage: double.tryParse(_taxController.text.trim()) ?? 18.0,
      showAdvancePaid: _showAdvancePaid,
      advancePaid: double.tryParse(_advanceController.text.trim()) ?? 0.0,
      status: 'Sent',
    );
  }

  void _saveCurrentQuotation() async {
    final quotation = _buildCurrentQuotation();
    await repository.addQuotation(quotation);
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
          heading: 'Service Section',
          items: [
            InvoiceItem(name: 'Event Package', price: 50000),
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

  bool _hasValidCustomerPhone(QuotationModel quotation) {
    if (quotation.customerName.trim().isEmpty) return false;
    final matchingCustomer = repository.customers.firstWhere(
      (c) => c.name.toLowerCase() == quotation.customerName.trim().toLowerCase(),
      orElse: () => CustomerModel(id: '', name: '', email: '', phone: '', totalEvents: 0),
    );
    return matchingCustomer.phone.trim().isNotEmpty && matchingCustomer.phone.trim().length >= 8;
  }

  Future<void> _sendViaWhatsApp(QuotationModel quotation) async {
    final message = Uri.encodeComponent(
      "Hello ${quotation.customerName},\n\nHere is your quotation #${quotation.quoteNumber} from Haya Event Management for venue ${quotation.venue}.\nTotal Quoted Amount: ₹${quotation.grandTotal.toStringAsFixed(0)}\nValid Until: ${quotation.dueDate}\n\nThank you for choosing us!",
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.background,
      child: Column(
        children: [
          // Top Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
                  onPressed: widget.onBack ?? () => Navigator.pop(context),
                ),
                Expanded(
                  child: Row(
                    children: [
                      _buildMainTabButton(0, Icons.description_outlined, 'All Quotations (${repository.quotations.length})'),
                      const SizedBox(width: 8),
                      _buildMainTabButton(1, Icons.tune, 'Quotation Builder & Preview'),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _resetFormToNew();
                      _mainTab = 1;
                    });
                  },
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  label: const Text('+ New Quotation', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                ),
              ],
            ),
          ),
          Expanded(
            child: _mainTab == 0 ? _buildAllQuotationsTab() : _buildBuilderTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTabButton(int tabIndex, IconData icon, String title) {
    final isSelected = _mainTab == tabIndex;
    return InkWell(
      onTap: () => setState(() => _mainTab = tabIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? AppTheme.primary : const Color(0xFF6B7280)),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? AppTheme.primary : const Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }

  Widget _buildAllQuotationsTab() {
    final quotations = repository.quotations;
    return quotations.isEmpty
        ? const Center(child: Text('No quotations yet. Click "+ New Quotation" to start.'))
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
                    const Icon(Icons.description, color: AppTheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('#${q.quoteNumber} • ${q.customerName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Venue: ${q.venue} • Valid: ${q.dueDate}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${q.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _loadQuotationForEdit(q),
                              icon: const Icon(Icons.edit, size: 14),
                              label: const Text('Edit', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 30)),
                            ),
                            const SizedBox(width: 6),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CreateInvoiceScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.receipt_long, size: 14, color: Colors.white),
                              label: const Text('Convert to Invoice', style: TextStyle(fontSize: 11, color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, minimumSize: const Size(0, 30)),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              onPressed: () => repository.deleteQuotation(q.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
  }

  Widget _buildBuilderTab() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _formSubTab = 0),
                icon: Icon(Icons.edit, color: _formSubTab == 0 ? AppTheme.primary : Colors.grey),
                label: Text('Edit Form', style: TextStyle(color: _formSubTab == 0 ? AppTheme.primary : Colors.grey)),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () => setState(() => _formSubTab = 1),
                icon: Icon(Icons.preview, color: _formSubTab == 1 ? AppTheme.primary : Colors.grey),
                label: Text('Template Preview', style: TextStyle(color: _formSubTab == 1 ? AppTheme.primary : Colors.grey)),
              ),
            ],
          ),
        ),
        Expanded(
          child: _formSubTab == 0 ? _buildQuotationForm() : _buildTemplatePreview(),
        ),
      ],
    );
  }

  Widget _buildQuotationForm() {
    final customers = repository.customers;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quotation & Client Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                if (customers.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: customers.any((c) => c.name == _customerController.text) ? _customerController.text : customers.first.name,
                    decoration: const InputDecoration(labelText: 'Customer *'),
                    items: customers.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                    onChanged: (v) => setState(() => _customerController.text = v ?? ''),
                  ),
                const SizedBox(height: 12),
                TextField(controller: _venueController, decoration: const InputDecoration(labelText: 'Venue Location')),
                const SizedBox(height: 12),
                TextField(controller: _quoteNumberController, decoration: const InputDecoration(labelText: 'Quotation Number')),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Quotation Sections & Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton.icon(
                onPressed: _addSection,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+ Add Section'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._sections.asMap().entries.map((entry) {
            final sIdx = entry.key;
            final section = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E7EB))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: section.heading)..selection = TextSelection.fromPosition(TextPosition(offset: section.heading.length)),
                          onChanged: (val) => section.heading = val,
                          decoration: const InputDecoration(labelText: 'Section Heading'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => setState(() => _sections.removeAt(sIdx)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...section.items.asMap().entries.map((itemEntry) {
                    final iIdx = itemEntry.key;
                    final item = itemEntry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: TextEditingController(text: item.name)..selection = TextSelection.fromPosition(TextPosition(offset: item.name.length)),
                              onChanged: (val) => item.name = val,
                              decoration: const InputDecoration(hintText: 'Item Name / Description'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: TextEditingController(text: item.price.toStringAsFixed(0)),
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                item.price = double.tryParse(val) ?? 0;
                              },
                              decoration: const InputDecoration(hintText: 'Price (₹)'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Colors.red),
                            onPressed: () => setState(() => section.items.removeAt(iIdx)),
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => _addItemToSection(sIdx),
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('+ Add Item'),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saveCurrentQuotation,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('Save Quotation'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatePreview() {
    final quotation = _buildCurrentQuotation();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          width: 700,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(repository.companyName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown)),
                      Text(repository.companyAddress, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
                    child: const Text('QUOTATION', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                  ),
                ],
              ),
              const Divider(height: 30),
              Text('Prepared For: ${quotation.customerName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Venue: ${quotation.venue}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 20),
              ...quotation.sections.map((s) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.heading, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                      ...s.items.map((i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(i.name),
                                Text('₹${i.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )),
                      const SizedBox(height: 10),
                    ],
                  )),
              const Divider(height: 30),
              Align(
                alignment: Alignment.centerRight,
                child: Text('Total Quoted: ₹${quotation.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
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
                  if (_hasValidCustomerPhone(quotation)) ...[
                    ElevatedButton.icon(
                      onPressed: () => _sendViaWhatsApp(quotation),
                      icon: const Icon(Icons.share, size: 16, color: Colors.white),
                      label: const Text('WhatsApp', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton.icon(
                    onPressed: () => QuotationPdfService.printQuotation(quotation),
                    icon: const Icon(Icons.print, size: 16, color: Colors.white),
                    label: const Text('Print', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
