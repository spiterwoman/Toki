import 'package:flutter/material.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/glass_card.dart';


class Reminder {
  final String id;
  final String title;
  final DateTime? date;
  final TimeOfDay? time;
  bool done;

  Reminder({
    required this.id,
    required this.title,
    this.date,
    this.time,
    this.done = false,
  });
}

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  final TextEditingController _titleController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late List<Reminder> _reminders;

  @override
  void initState() {
    super.initState();
    // Seed data; in real app, fetch from backend
    _reminders = [
      Reminder(id: 'r1', title: 'Submit expense report'),
      Reminder(id: 'r2', title: 'Call dentist for appointment'),
      Reminder(id: 'r3', title: 'Pick up dry cleaning'),
    ];
  }

  List<Reminder> get _activeReminders =>
      _reminders.where((r) => !r.done).toList();

  List<Reminder> get _completedReminders =>
      _reminders.where((r) => r.done).toList();

  int get _activeCount => _activeReminders.length;
  int get _doneCount => _completedReminders.length;

  void _toggleReminder(String id) {
    setState(() {
      final idx = _reminders.indexWhere((r) => r.id == id);
      if (idx != -1) {
        _reminders[idx].done = !_reminders[idx].done;
      }
    });
  }

  void _clearCompleted() {
    setState(() {
      _reminders.removeWhere((r) => r.done);
    });
  }

  Future<void> _openAddDialog() async {
    _titleController.clear();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Reminder'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Reminder',
                hintText: 'Enter reminder text...',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a reminder';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _addReminder,
              style: ElevatedButton.styleFrom(
                // approximate the orange gradient with a solid accent color
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Reminder'),
            ),
          ],
        );
      },
    );
  }

  void _addReminder() {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      _reminders = [
        Reminder(id: id, title: title, done: false),
        ..._reminders,
      ];
    });

    Navigator.of(context).pop(); // close dialog
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Reminders',
      subtitle: '${_activeCount} active reminders',
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Active reminders card
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('🔔',
                                style: TextStyle(color: Color(0xFFA0E0A0))),
                            const SizedBox(width: 8),
                            const Text(
                              'Active Reminders',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_activeReminders.isEmpty)
                          Text(
                            'No active reminders.',
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                            ),
                          )
                        else
                          Column(
                            children: _activeReminders.map((r) {
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: InkWell(
                                  onTap: () => _toggleReminder(r.id),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            border: Border.all(
                                              color: Colors.amber,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            r.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Completed card
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('🔔',
                                style: TextStyle(color: Color(0xFFA0E0A0))),
                            const SizedBox(width: 8),
                            const Text(
                              'Completed',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (_doneCount > 0)
                              TextButton(
                                onPressed: _clearCompleted,
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text('Clear Completed'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_doneCount == 0)
                          Text(
                            'No completed reminders yet.',
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                            ),
                          )
                        else
                          Column(
                            children: _completedReminders.map((r) {
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF34D399),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          r.title,
                                          style: TextStyle(
                                            decoration:
                                                TextDecoration.lineThrough,
                                            color:
                                                Theme.of(context).hintColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Stats cards grid
                Row(
                  children: [
                    Expanded(
                      child: GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Active',
                                style: TextStyle(
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_activeCount',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Completed',
                                style: TextStyle(
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const SizedBox(height: 4),
                              Text(
                                '$_doneCount',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF34D399),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 80), // bottom padding so FAB doesn’t cover content
              ],
            ),
          ),

          // Floating Action Button (bottom-right)
          Positioned(
            right: 26,
            bottom: 26,
            child: SizedBox(
              width: 60,
              height: 60,
              child: FloatingActionButton(
                onPressed: _openAddDialog,
                tooltip: 'Add reminder',
                backgroundColor: Colors.orange,
                elevation: 10,
                child: const Icon(
                  Icons.add,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}