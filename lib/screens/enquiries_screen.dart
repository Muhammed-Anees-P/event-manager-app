import 'package:flutter/material.dart';
import '../data/app_data_repository.dart';
import '../models/enquiry_model.dart';
import '../theme/app_theme.dart';

class EnquiriesScreen extends StatefulWidget {
  const EnquiriesScreen({super.key});

  static void showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _CreateEnquiryModal(),
    );
  }

  @override
  State<EnquiriesScreen> createState() => _EnquiriesScreenState();
}

class _EnquiriesScreenState extends State<EnquiriesScreen> {
  final repository = AppDataRepository.instance;

  String _searchQuery = '';
  String _selectedStatusFilter = 'All';
  String _selectedDateFilter = 'All Time';

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

  void _showEnquiryDetailsModal(EnquiryModel enquiry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EnquiryDetailsModal(enquiry: enquiry),
    );
  }

  void _showEditEnquiryModal(EnquiryModel enquiry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EditEnquiryModal(enquiry: enquiry),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<EnquiryModel> filteredEnquiries = repository.enquiries.where((e) {
      final matchesSearch = e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.type.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (_selectedStatusFilter != 'All') {
        if (e.status.displayName.toLowerCase() != _selectedStatusFilter.toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Filter & Search Controls Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Input & Date Range Filter
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search enquiries by client name or event type...',
                            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                            prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF9CA3AF)),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDateFilter,
                          items: ['All Time', 'This Month', 'This Week']
                              .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12))))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedDateFilter = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'New', 'Quoted', 'Follow up', 'Contacted'].map((filter) {
                      final isSelected = _selectedStatusFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedStatusFilter = filter;
                              });
                            }
                          },
                          selectedColor: AppTheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF4B5563),
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          backgroundColor: const Color(0xFFF3F4F6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          side: BorderSide.none,
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Enquiries List
          Expanded(
            child: filteredEnquiries.isEmpty
                ? const Center(child: Text('No enquiries found.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredEnquiries.length,
                    itemBuilder: (context, index) {
                      final enquiry = filteredEnquiries[index];
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
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                                  child: Text(
                                    enquiry.name.isNotEmpty ? enquiry.name.substring(0, 1) : 'E',
                                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(enquiry.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                                      const SizedBox(height: 2),
                                      Text('${enquiry.type} • ${enquiry.totalDate}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('₹${enquiry.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                                    const SizedBox(height: 4),
                                    _buildEnquiryBadge(enquiry.status),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text('Status: ', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                                    DropdownButtonHideUnderline(
                                      child: DropdownButton<EnquiryStatus>(
                                        value: enquiry.status,
                                        isDense: true,
                                        items: EnquiryStatus.values.map((s) {
                                          return DropdownMenuItem(
                                            value: s,
                                            child: Text(s.displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          );
                                        }).toList(),
                                        onChanged: (newStatus) async {
                                          if (newStatus != null) {
                                            final updated = EnquiryModel(
                                              id: enquiry.id,
                                              name: enquiry.name,
                                              type: enquiry.type,
                                              totalDate: enquiry.totalDate,
                                              amount: enquiry.amount,
                                              status: newStatus,
                                            );
                                            await repository.updateEnquiry(updated);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility_outlined, size: 18, color: AppTheme.primary),
                                      tooltip: 'View Single Details',
                                      onPressed: () => _showEnquiryDetailsModal(enquiry),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF4B5563)),
                                      tooltip: 'Edit Enquiry',
                                      onPressed: () => _showEditEnquiryModal(enquiry),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                      tooltip: 'Delete Enquiry',
                                      onPressed: () async {
                                        await repository.deleteEnquiry(enquiry.id);
                                      },
                                    ),
                                  ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => EnquiriesScreen.showCreateDialog(context),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
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

// SINGLE ENQUIRY DETAILS MODAL
class _EnquiryDetailsModal extends StatelessWidget {
  final EnquiryModel enquiry;

  const _EnquiryDetailsModal({required this.enquiry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primary,
                    child: Text(enquiry.name.substring(0, 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(enquiry.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                      Text(enquiry.type, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    ],
                  ),
                ],
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(height: 24),

          _buildInfoRow('Event Type', enquiry.type),
          const SizedBox(height: 8),
          _buildInfoRow('Enquiry Date', enquiry.totalDate),
          const SizedBox(height: 8),
          _buildInfoRow('Estimated Budget', '₹${enquiry.amount.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _buildInfoRow('Current Status', enquiry.status.displayName),
          const SizedBox(height: 24),

          const Text('Quick Contact Actions:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Calling support hotline +91 9747451938')),
                    );
                  },
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Call Client'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening WhatsApp chat...')),
                    );
                  },
                  icon: const Icon(Icons.chat, size: 16),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
      ],
    );
  }
}

// EDIT ENQUIRY MODAL
class _EditEnquiryModal extends StatefulWidget {
  final EnquiryModel enquiry;

  const _EditEnquiryModal({required this.enquiry});

  @override
  State<_EditEnquiryModal> createState() => _EditEnquiryModalState();
}

class _EditEnquiryModalState extends State<_EditEnquiryModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController amountController;
  late String selectedType;
  late EnquiryStatus selectedStatus;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.enquiry.name);
    amountController = TextEditingController(text: widget.enquiry.amount.toStringAsFixed(0));
    selectedType = widget.enquiry.type;
    selectedStatus = widget.enquiry.status;
  }

  @override
  void dispose() {
    nameController.dispose();
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
                const Text('Edit Enquiry Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Client / Contact Name'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter name' : null,
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
              decoration: const InputDecoration(labelText: 'Estimated Budget (₹)'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter budget' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<EnquiryStatus>(
              value: selectedStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: EnquiryStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.displayName)))
                  .toList(),
              onChanged: (v) => setState(() => selectedStatus = v!),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final updated = EnquiryModel(
                      id: widget.enquiry.id,
                      name: nameController.text.trim(),
                      type: selectedType,
                      totalDate: widget.enquiry.totalDate,
                      amount: double.tryParse(amountController.text.trim()) ?? 0,
                      status: selectedStatus,
                    );
                    await AppDataRepository.instance.updateEnquiry(updated);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Update Enquiry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// CREATE ENQUIRY MODAL
class _CreateEnquiryModal extends StatefulWidget {
  const _CreateEnquiryModal();

  @override
  State<_CreateEnquiryModal> createState() => _CreateEnquiryModalState();
}

class _CreateEnquiryModalState extends State<_CreateEnquiryModal> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final amountController = TextEditingController();
  String selectedType = 'Wedding';
  EnquiryStatus selectedStatus = EnquiryStatus.newEnquiry;

  @override
  void dispose() {
    nameController.dispose();
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
                const Text('New Enquiry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Client / Contact Name'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a name' : null,
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
              decoration: const InputDecoration(labelText: 'Estimated Budget (₹)'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter budget' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<EnquiryStatus>(
              value: selectedStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: EnquiryStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.displayName)))
                  .toList(),
              onChanged: (v) => setState(() => selectedStatus = v!),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final enquiry = EnquiryModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text.trim(),
                      type: selectedType,
                      totalDate: '12 Sep 2026',
                      amount: double.tryParse(amountController.text.trim()) ?? 0,
                      status: selectedStatus,
                    );
                    await AppDataRepository.instance.addEnquiry(enquiry);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Save Enquiry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
