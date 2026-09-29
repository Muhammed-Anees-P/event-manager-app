import 'package:flutter/material.dart';
import '../data/app_data_repository.dart';
import '../models/event_model.dart';
import '../theme/app_theme.dart';

class EventsScreen extends StatefulWidget {
  final Function(EventModel) onSelectEvent;

  const EventsScreen({
    super.key,
    required this.onSelectEvent,
  });

  static void showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _CreateEventModal(),
    );
  }

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
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
    List<EventModel> filteredEvents = repository.events.where((e) {
      final matchesSearch = e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.venue.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (_selectedFilter == 'Upcoming') {
        return e.status == EventStatus.confirmed || e.status == EventStatus.planning;
      } else if (_selectedFilter == 'Ongoing') {
        return e.status == EventStatus.planning;
      } else if (_selectedFilter == 'Completed') {
        return e.status == EventStatus.completed;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Search & Filter header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: TextField(
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search events...',
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
                    const SizedBox(width: 8),
                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.filter_list, color: Color(0xFF4B5563), size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Filter Tabs Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Upcoming', 'Ongoing', 'Completed'].map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedFilter = filter;
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
          // Events List
          Expanded(
            child: filteredEvents.isEmpty
                ? const Center(child: Text('No events found.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, index) {
                      final event = filteredEvents[index];
                      return _buildEventCard(event);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => EventsScreen.showCreateDialog(context),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        onTap: () => widget.onSelectEvent(event),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Preview Banner
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.asset(
                    'assets/images/login_bg.png',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120,
                      color: const Color(0xFF3B2D20),
                      child: const Center(
                        child: Icon(Icons.event, size: 40, color: Colors.white30),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _buildStatusBadge(event.status),
                ),
              ],
            ),
            // Card details
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF6B7280)),
                      const SizedBox(width: 6),
                      Text(
                        '${event.date} • ${event.time}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF6B7280)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${event.venue} • ${event.guests} Guests',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(EventStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case EventStatus.confirmed:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        break;
      case EventStatus.planning:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        break;
      case EventStatus.completed:
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF2563EB);
        break;
      case EventStatus.cancelled:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        status.displayName,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _CreateEventModal extends StatefulWidget {
  const _CreateEventModal();

  @override
  State<_CreateEventModal> createState() => _CreateEventModalState();
}

class _CreateEventModalState extends State<_CreateEventModal> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final venueController = TextEditingController();
  final guestsController = TextEditingController(text: '100');
  final contractController = TextEditingController(text: '250000');
  final receivedController = TextEditingController(text: '50000');
  EventStatus selectedStatus = EventStatus.planning;

  @override
  void dispose() {
    titleController.dispose();
    venueController.dispose();
    guestsController.dispose();
    contractController.dispose();
    receivedController.dispose();
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
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Create New Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Event Title'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter event title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: venueController,
                decoration: const InputDecoration(labelText: 'Venue Name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter venue' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: guestsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Guests Count'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<EventStatus>(
                      value: selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: EventStatus.values
                          .map((s) => DropdownMenuItem(value: s, child: Text(s.displayName)))
                          .toList(),
                      onChanged: (v) => setState(() => selectedStatus = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: contractController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Contract Value (₹)'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter contract value' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: receivedController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount Received (₹)'),
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
                      final event = EventModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        code: 'EVT-2026-00${AppDataRepository.instance.events.length + 1}',
                        title: titleController.text.trim(),
                        date: '28 Sep 2026',
                        time: '5:00 PM - 10:00 PM',
                        venue: venueController.text.trim(),
                        guests: int.tryParse(guestsController.text.trim()) ?? 100,
                        manager: 'Admin',
                        status: selectedStatus,
                        contractValue: double.tryParse(contractController.text.trim()) ?? 0,
                        amountReceived: double.tryParse(receivedController.text.trim()) ?? 0,
                      );
                      await AppDataRepository.instance.addEvent(event);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  child: const Text('Save Event'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
