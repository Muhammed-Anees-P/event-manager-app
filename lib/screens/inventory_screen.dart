import 'package:flutter/material.dart';
import '../data/app_data_repository.dart';
import '../models/inventory_model.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loading_overlay.dart';
import '../widgets/delete_confirmation_dialog.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  static void showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _CreateInventoryModal(),
    );
  }

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
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

  void _showEditInventoryModal(BuildContext context, InventoryModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EditInventoryModal(item: item),
    );
  }

  void _showInventoryDetail(BuildContext context, InventoryModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.itemName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${item.category}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            Text('Quantity: ${item.quantity}', style: const TextStyle(color: Color(0xFF4B5563))),
            Text('Rental Price: ₹${item.rentalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark, fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          IconButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showEditInventoryModal(context, item);
            },
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF4B5563)),
            tooltip: 'Edit Item',
          ),
          IconButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final confirm = await AppDeleteConfirmationDialog.show(
                context,
                title: 'Delete Inventory Item',
                itemDetails: 'Item: ${item.itemName} (${item.category})',
              );
              if (confirm) {
                await AppLoadingOverlay.run(
                  context,
                  message: 'Deleting item...',
                  asyncTask: () => repository.deleteInventory(item.id),
                );
              }
            },
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete Item',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = repository.activeInventory;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: items.isEmpty
          ? const Center(child: Text('No inventory items yet. Tap + to add.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return InkWell(
                  onTap: () => _showInventoryDetail(context, item),
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
                          child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.itemName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                              const SizedBox(height: 2),
                              Text('${item.category} • Qty: ${item.quantity}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                            ],
                          ),
                        ),
                        Text('₹${item.rentalPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF4B5563)),
                          tooltip: 'Edit Item',
                          onPressed: () => _showEditInventoryModal(context, item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          tooltip: 'Delete Item',
                          onPressed: () async {
                            final confirm = await AppDeleteConfirmationDialog.show(
                              context,
                              title: 'Delete Inventory Item',
                              itemDetails: 'Item: ${item.itemName} (${item.category})',
                            );
                            if (confirm) {
                              await AppLoadingOverlay.run(
                                context,
                                message: 'Deleting item...',
                                asyncTask: () => repository.deleteInventory(item.id),
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
        onPressed: () => InventoryScreen.showCreateDialog(context),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _EditInventoryModal extends StatefulWidget {
  final InventoryModel item;

  const _EditInventoryModal({required this.item});

  @override
  State<_EditInventoryModal> createState() => _EditInventoryModalState();
}

class _EditInventoryModalState extends State<_EditInventoryModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController qtyController;
  late TextEditingController priceController;
  late String selectedCategory;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item.itemName);
    qtyController = TextEditingController(text: widget.item.quantity.toString());
    priceController = TextEditingController(text: widget.item.rentalPrice.toStringAsFixed(0));
    selectedCategory = widget.item.category;
  }

  @override
  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['Sound & Lighting', 'Decor & Props', 'Seating & Tables', 'Catering Equipment', 'Stage & Truss'];
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
                const Text('Edit Inventory Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Item Name *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter item name' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => selectedCategory = v!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Rental Price (₹)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final updated = InventoryModel(
                      id: widget.item.id,
                      itemName: nameController.text.trim(),
                      category: selectedCategory,
                      quantity: int.tryParse(qtyController.text.trim()) ?? widget.item.quantity,
                      rentalPrice: double.tryParse(priceController.text.trim()) ?? widget.item.rentalPrice,
                      isDeleted: widget.item.isDeleted,
                    );
                    final idx = AppDataRepository.instance.inventory.indexWhere((i) => i.id == widget.item.id);
                    if (idx >= 0) {
                      AppDataRepository.instance.inventory[idx] = updated;
                      AppDataRepository.instance.notifyListeners();
                    }
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Update Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateInventoryModal extends StatefulWidget {
  const _CreateInventoryModal();

  @override
  State<_CreateInventoryModal> createState() => _CreateInventoryModalState();
}

class _CreateInventoryModalState extends State<_CreateInventoryModal> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final qtyController = TextEditingController(text: '50');
  final priceController = TextEditingController();
  String selectedCategory = 'Sound & Lighting';

  @override
  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    priceController.dispose();
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
                const Text('Add Inventory Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Item Name *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter item name' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: ['Sound & Lighting', 'Decor & Props', 'Seating & Tables', 'Catering Equipment', 'Stage & Truss']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => selectedCategory = v!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Rental Price (₹)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final item = InventoryModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      itemName: nameController.text.trim(),
                      category: selectedCategory,
                      quantity: int.tryParse(qtyController.text.trim()) ?? 10,
                      rentalPrice: double.tryParse(priceController.text.trim()) ?? 1000,
                    );
                    await AppLoadingOverlay.run(
                      context,
                      message: 'Saving item...',
                      asyncTask: () => AppDataRepository.instance.addInventory(item),
                    );
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Save Inventory Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
