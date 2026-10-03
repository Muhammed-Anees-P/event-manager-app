import 'package:flutter/material.dart';
import '../data/app_data_repository.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';
import '../widgets/delete_confirmation_dialog.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  static void showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _CreateTaskModal(),
    );
  }

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _selectedFilter = 'Today';
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

  void _showEditTaskModal(BuildContext context, TaskModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EditTaskModal(task: task),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<TaskModel> filteredTasks = repository.activeTasks.where((t) {
      if (_selectedFilter == 'Today') {
        return !t.isCompleted;
      } else if (_selectedFilter == 'Upcoming') {
        return !t.isCompleted;
      } else if (_selectedFilter == 'Completed') {
        return t.isCompleted;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Today', 'Upcoming', 'Completed'].map((filter) {
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide.none,
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Tasks List
          Expanded(
            child: filteredTasks.isEmpty
                ? const Center(child: Text('No tasks found.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: task.isCompleted,
                                activeColor: AppTheme.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (val) {
                                  setState(() {
                                    task.isCompleted = val ?? false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                      color: task.isCompleted ? Colors.grey : const Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    task.eventTitle,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                  ),
                                ],
                              ),
                            ),
                            _buildPriorityBadge(task.priority),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Color(0xFF4B5563), size: 18),
                              tooltip: 'Edit Task',
                              onPressed: () => _showEditTaskModal(context, task),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                              tooltip: 'Delete Task',
                              onPressed: () async {
                                final confirm = await AppDeleteConfirmationDialog.show(
                                  context,
                                  title: 'Delete Task',
                                  itemDetails: 'Task: ${task.title} (${task.eventTitle})',
                                );
                                if (confirm) {
                                  await repository.deleteTask(task.id);
                                }
                              },
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
        onPressed: () => TasksScreen.showCreateDialog(context),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPriorityBadge(TaskPriority priority) {
    Color bg;
    Color fg;
    switch (priority) {
      case TaskPriority.high:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        break;
      case TaskPriority.medium:
        bg = const Color(0xFFFFEDD5);
        fg = const Color(0xFFEA580C);
        break;
      case TaskPriority.low:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        priority.displayName,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _EditTaskModal extends StatefulWidget {
  final TaskModel task;

  const _EditTaskModal({required this.task});

  @override
  State<_EditTaskModal> createState() => _EditTaskModalState();
}

class _EditTaskModalState extends State<_EditTaskModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController titleController;
  late String selectedEvent;
  late TaskPriority selectedPriority;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.task.title);
    selectedEvent = widget.task.eventTitle;
    selectedPriority = widget.task.priority;
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeEvents = AppDataRepository.instance.activeEvents;
    final List<String> eventTitles = activeEvents.map((e) => e.title).where((t) => t.trim().isNotEmpty).toSet().toList();

    if (!eventTitles.contains(selectedEvent)) {
      eventTitles.add(selectedEvent);
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
                const Text('Edit Task Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Task Title *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter task title' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedEvent,
              decoration: const InputDecoration(labelText: 'Assigned Event'),
              items: eventTitles.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => selectedEvent = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TaskPriority>(
              value: selectedPriority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: TaskPriority.values
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.displayName)))
                  .toList(),
              onChanged: (v) => setState(() => selectedPriority = v!),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.task.title = titleController.text.trim();
                    widget.task.eventTitle = selectedEvent;
                    widget.task.priority = selectedPriority;
                    AppDataRepository.instance.notifyListeners();
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Update Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateTaskModal extends StatefulWidget {
  const _CreateTaskModal();

  @override
  State<_CreateTaskModal> createState() => _CreateTaskModalState();
}

class _CreateTaskModalState extends State<_CreateTaskModal> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  String selectedEvent = '';
  TaskPriority selectedPriority = TaskPriority.high;

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeEvents = AppDataRepository.instance.activeEvents;
    final List<String> eventTitles = activeEvents.map((e) => e.title).where((t) => t.trim().isNotEmpty).toSet().toList();

    if (eventTitles.isNotEmpty) {
      if (selectedEvent.isEmpty || !eventTitles.contains(selectedEvent)) {
        selectedEvent = eventTitles.first;
      }
    } else {
      selectedEvent = 'General Task';
      if (!eventTitles.contains('General Task')) {
        eventTitles.add('General Task');
      }
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
                const Text('Add New Task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Task Title *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter task title' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedEvent,
              decoration: const InputDecoration(labelText: 'Assigned Event'),
              items: eventTitles.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => selectedEvent = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TaskPriority>(
              value: selectedPriority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: TaskPriority.values
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.displayName)))
                  .toList(),
              onChanged: (v) => setState(() => selectedPriority = v!),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final task = TaskModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text.trim(),
                      eventTitle: selectedEvent,
                      priority: selectedPriority,
                      category: 'Today',
                    );
                    await AppDataRepository.instance.addTask(task);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Add Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
