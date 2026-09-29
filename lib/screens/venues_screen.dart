import 'package:flutter/material.dart';
import '../data/app_data_repository.dart';
import '../models/venue_model.dart';
import '../theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final venues = repository.venues;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: venues.isEmpty
          ? const Center(child: Text('No venues added yet. Tap + to add.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: venues.length,
              itemBuilder: (context, index) {
                final v = venues[index];
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
                      Text('₹${v.pricePerDay.toStringAsFixed(0)}/day', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                    ],
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

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    capacityController.dispose();
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
              decoration: const InputDecoration(labelText: 'Venue Name'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter venue name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: locationController,
              decoration: const InputDecoration(labelText: 'Location / Address'),
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
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter capacity' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Rate / Day (₹)'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter rate' : null,
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
                    final venue = VenueModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text.trim(),
                      location: locationController.text.trim(),
                      capacity: int.tryParse(capacityController.text.trim()) ?? 100,
                      pricePerDay: double.tryParse(priceController.text.trim()) ?? 50000,
                      contactPerson: 'Manager',
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
