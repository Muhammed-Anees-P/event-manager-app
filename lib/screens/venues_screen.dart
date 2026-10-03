import 'package:flutter/material.dart';
import '../data/app_data_repository.dart';
import '../models/venue_model.dart';
import '../theme/app_theme.dart';
import '../widgets/delete_confirmation_dialog.dart';

class VenuesScreen extends StatefulWidget {
  const VenuesScreen({super.key});

  static void showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _CreateVenueModal(),
    );
  }

  @override
  State<VenuesScreen> createState() => _VenuesScreenState();
}

class _VenuesScreenState extends State<VenuesScreen> {
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

  void _showEditVenueModal(BuildContext context, VenueModel v) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EditVenueModal(venue: v),
    );
  }

  void _showVenueDetail(BuildContext context, VenueModel v) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(v.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: ${v.location}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            Text('Capacity: ${v.capacity} guests', style: const TextStyle(color: Color(0xFF4B5563))),
            Text('Price per Day: ₹${v.pricePerDay.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark, fontSize: 16)),
            Text('Contact Person: ${v.contactPerson}', style: const TextStyle(color: Color(0xFF4B5563))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          IconButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showEditVenueModal(context, v);
            },
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF4B5563)),
            tooltip: 'Edit Venue',
          ),
          IconButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final confirm = await AppDeleteConfirmationDialog.show(
                context,
                title: 'Delete Venue',
                itemDetails: 'Venue: ${v.name} (${v.location})',
              );
              if (confirm) {
                await repository.deleteVenue(v.id);
              }
            },
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete Venue',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final venues = repository.activeVenues;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: venues.isEmpty
          ? const Center(child: Text('No venues added yet. Tap + to add.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: venues.length,
              itemBuilder: (context, index) {
                final v = venues[index];
                return InkWell(
                  onTap: () => _showVenueDetail(context, v),
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
                          child: const Icon(Icons.location_on_outlined, color: AppTheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                              const SizedBox(height: 2),
                              Text('${v.location} • Capacity: ${v.capacity}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                            ],
                          ),
                        ),
                        Text('₹${v.pricePerDay.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF4B5563)),
                          tooltip: 'Edit Venue',
                          onPressed: () => _showEditVenueModal(context, v),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          tooltip: 'Delete Venue',
                          onPressed: () async {
                            final confirm = await AppDeleteConfirmationDialog.show(
                              context,
                              title: 'Delete Venue',
                              itemDetails: 'Venue: ${v.name} (${v.location})',
                            );
                            if (confirm) {
                              await repository.deleteVenue(v.id);
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
        onPressed: () => VenuesScreen.showCreateDialog(context),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _EditVenueModal extends StatefulWidget {
  final VenueModel venue;

  const _EditVenueModal({required this.venue});

  @override
  State<_EditVenueModal> createState() => _EditVenueModalState();
}

class _EditVenueModalState extends State<_EditVenueModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController locationController;
  late TextEditingController capacityController;
  late TextEditingController priceController;
  late TextEditingController contactController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.venue.name);
    locationController = TextEditingController(text: widget.venue.location);
    capacityController = TextEditingController(text: widget.venue.capacity.toString());
    priceController = TextEditingController(text: widget.venue.pricePerDay.toStringAsFixed(0));
    contactController = TextEditingController(text: widget.venue.contactPerson);
  }

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    capacityController.dispose();
    priceController.dispose();
    contactController.dispose();
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
                const Text('Edit Venue Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Venue Name *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: locationController,
              decoration: const InputDecoration(labelText: 'Location / Address *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter location' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: capacityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Capacity (Guests)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price / Day (₹)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: contactController,
              decoration: const InputDecoration(labelText: 'Contact Person / Phone'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final updated = VenueModel(
                      id: widget.venue.id,
                      name: nameController.text.trim(),
                      location: locationController.text.trim(),
                      capacity: int.tryParse(capacityController.text.trim()) ?? widget.venue.capacity,
                      pricePerDay: double.tryParse(priceController.text.trim()) ?? widget.venue.pricePerDay,
                      contactPerson: contactController.text.trim().isEmpty ? widget.venue.contactPerson : contactController.text.trim(),
                      isDeleted: widget.venue.isDeleted,
                    );
                    final idx = AppDataRepository.instance.venues.indexWhere((v) => v.id == widget.venue.id);
                    if (idx >= 0) {
                      AppDataRepository.instance.venues[idx] = updated;
                      AppDataRepository.instance.notifyListeners();
                    }
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Update Venue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateVenueModal extends StatefulWidget {
  const _CreateVenueModal();

  @override
  State<_CreateVenueModal> createState() => _CreateVenueModalState();
}

class _CreateVenueModalState extends State<_CreateVenueModal> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final capacityController = TextEditingController();
  final priceController = TextEditingController();
  final contactController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    capacityController.dispose();
    priceController.dispose();
    contactController.dispose();
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
                const Text('Add Venue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Venue Name *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: locationController,
              decoration: const InputDecoration(labelText: 'Location / Address *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter location' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: capacityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Capacity (Guests)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price / Day (₹)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: contactController,
              decoration: const InputDecoration(labelText: 'Contact Person / Phone'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final venue = VenueModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text.trim(),
                      location: locationController.text.trim(),
                      capacity: int.tryParse(capacityController.text.trim()) ?? 300,
                      pricePerDay: double.tryParse(priceController.text.trim()) ?? 50000,
                      contactPerson: contactController.text.trim().isEmpty ? 'Manager' : contactController.text.trim(),
                    );
                    await AppDataRepository.instance.addVenue(venue);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Save Venue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
