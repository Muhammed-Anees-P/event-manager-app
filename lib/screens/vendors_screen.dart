import 'package:flutter/material.dart';
import '../data/app_data_repository.dart';
import '../models/vendor_model.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loading_overlay.dart';
import '../widgets/delete_confirmation_dialog.dart';

class VendorsScreen extends StatefulWidget {
  const VendorsScreen({super.key});

  static void showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _CreateVendorModal(),
    );
  }

  @override
  State<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends State<VendorsScreen> {
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

  void _showEditVendorModal(BuildContext context, VendorModel v) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EditVendorModal(vendor: v),
    );
  }

  void _showVendorDetail(BuildContext context, VendorModel v) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(v.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${v.category}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            Text('Phone: ${v.phone}', style: const TextStyle(color: Color(0xFF4B5563))),
            Text('Email: ${v.email}', style: const TextStyle(color: Color(0xFF4B5563))),
            Text('Rating: ${v.rating}', style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          IconButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showEditVendorModal(context, v);
            },
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF4B5563)),
            tooltip: 'Edit Vendor',
          ),
          IconButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final confirm = await AppDeleteConfirmationDialog.show(
                context,
                title: 'Delete Vendor',
                itemDetails: 'Vendor: ${v.name} (${v.category})',
              );
              if (confirm) {
                await AppLoadingOverlay.run(
                  context,
                  message: 'Deleting vendor...',
                  asyncTask: () => repository.deleteVendor(v.id),
                );
              }
            },
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete Vendor',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vendors = repository.activeVendors;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: vendors.isEmpty
          ? const Center(child: Text('No vendors added yet. Tap + to add.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vendors.length,
              itemBuilder: (context, index) {
                final v = vendors[index];
                return InkWell(
                  onTap: () => _showVendorDetail(context, v),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
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
                          child: const Icon(Icons.storefront_outlined, color: AppTheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                              const SizedBox(height: 2),
                              Text('${v.category} • ${v.phone}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                            ],
                          ),
                        ),
                        Text(v.rating, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF4B5563)),
                          tooltip: 'Edit Vendor',
                          onPressed: () => _showEditVendorModal(context, v),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          tooltip: 'Delete Vendor',
                          onPressed: () async {
                            final confirm = await AppDeleteConfirmationDialog.show(
                              context,
                              title: 'Delete Vendor',
                              itemDetails: 'Vendor: ${v.name} (${v.category})',
                            );
                            if (confirm) {
                              await AppLoadingOverlay.run(
                                context,
                                message: 'Deleting vendor...',
                                asyncTask: () => repository.deleteVendor(v.id),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => VendorsScreen.showCreateDialog(context),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _EditVendorModal extends StatefulWidget {
  final VendorModel vendor;

  const _EditVendorModal({required this.vendor});

  @override
  State<_EditVendorModal> createState() => _EditVendorModalState();
}

class _EditVendorModalState extends State<_EditVendorModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late String selectedCategory;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.vendor.name);
    phoneController = TextEditingController(text: widget.vendor.phone);
    emailController = TextEditingController(text: widget.vendor.email);
    selectedCategory = widget.vendor.category;
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['Catering', 'Photography', 'Decor', 'DJ & Audio', 'Makeup', 'Lighting'];
    if (!categories.contains(selectedCategory)) {
      categories.add(selectedCategory);
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
                const Text('Edit Vendor Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Vendor Name *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter name' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => selectedCategory = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter phone' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email Address'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final updated = VendorModel(
                      id: widget.vendor.id,
                      name: nameController.text.trim(),
                      category: selectedCategory,
                      phone: phoneController.text.trim(),
                      email: emailController.text.trim(),
                      rating: widget.vendor.rating,
                      isDeleted: widget.vendor.isDeleted,
                    );
                    final idx = AppDataRepository.instance.vendors.indexWhere((v) => v.id == widget.vendor.id);
                    if (idx >= 0) {
                      AppDataRepository.instance.vendors[idx] = updated;
                      AppDataRepository.instance.notifyListeners();
                    }
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Update Vendor'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateVendorModal extends StatefulWidget {
  const _CreateVendorModal();

  @override
  State<_CreateVendorModal> createState() => _CreateVendorModalState();
}

class _CreateVendorModalState extends State<_CreateVendorModal> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  String selectedCategory = 'Catering';

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
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
                const Text('Add Vendor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Vendor Name *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter name' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: ['Catering', 'Photography', 'Decor', 'DJ & Audio', 'Makeup', 'Lighting']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => selectedCategory = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter phone' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email Address'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final vendor = VendorModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text.trim(),
                      category: selectedCategory,
                      phone: phoneController.text.trim(),
                      email: emailController.text.trim(),
                      rating: '⭐ 4.8',
                    );
                    await AppLoadingOverlay.run(
                      context,
                      message: 'Saving vendor...',
                      asyncTask: () => AppDataRepository.instance.addVendor(vendor),
                    );
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Save Vendor'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
