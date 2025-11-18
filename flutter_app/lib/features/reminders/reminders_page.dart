import 'package:flutter/material.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/api/api.dart';

final api = Api('https://mytoki.app');

// ===== Model =============================================================

class Reminder {
  final String id;
  final String title;
  final String desc;
  final String status;   // "pending" or "completed"
  final String priority; // "low" | "medium" | "high"
  final DateTime? dueDate;
  final bool done;

  Reminder({
    required this.id,
    required this.title,
    required this.desc,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.done,
  });

  String get date {
    if (dueDate == null) return '';
    final dt = dueDate!;
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    final rawId = json['_id']?.toString() ?? '';
    final title = json['title'] as String? ?? '';
    final desc = json['desc'] as String? ?? '';
    final status = json['status'] as String? ?? 'pending';
    final priority = json['priority'] as String? ?? 'medium';

    DateTime? due;
    final dueRaw = json['dueDate'];
    if (dueRaw != null) {
      try {
        // backend may still send an ISO string; we just use the date part
        final dt = DateTime.parse(dueRaw.toString());
        due = DateTime(dt.year, dt.month, dt.day);
      } catch (_) {
        due = null;
      }
    }

    final completedField = json['completed'];
    final completedFlag = (completedField != null &&
        completedField is Map &&
        completedField['isCompleted'] == true);

    final done = (status == 'completed') || completedFlag;

    return Reminder(
      id: rawId,
      title: title,
      desc: desc,
      status: status,
      priority: priority,
      dueDate: due,
      done: done,
    );
  }
}

// ===== Page ==============================================================

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  // Add dialog
  final GlobalKey<FormState> _addFormKey = GlobalKey<FormState>();
  final TextEditingController _addTitleController = TextEditingController();
  final TextEditingController _addDescController = TextEditingController();
  DateTime? _addDueDate;
  String _addPriority = 'medium';

  // Edit dialog
  final GlobalKey<FormState> _editFormKey = GlobalKey<FormState>();
  final TextEditingController _editTitleController = TextEditingController();
  final TextEditingController _editDescController = TextEditingController();
  DateTime? _editDueDate;
  String _editPriority = 'medium';
  String _editStatus = 'pending';

  bool _loading = false;
  String? _error;
  List<Reminder> _reminders = [];

  @override
  void initState() {
    super.initState();
    _loadRemindersFromServer();
  }

  // ---- Derived lists / counts ------------------------------------------

  List<Reminder> get _activeReminders =>
      _reminders.where((r) => !r.done).toList();

  List<Reminder> get _completedReminders =>
      _reminders.where((r) => r.done).toList();

  int get _activeCount => _activeReminders.length;
  int get _doneCount => _completedReminders.length;

  // ---- API calls --------------------------------------------------------

  Future<void> _loadRemindersFromServer() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await api.viewReminders();
      if (res['success'] == true) {
        final list = (res['reminders'] as List?) ?? [];
        final reminders = list
            .map(
              (e) => Reminder.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();

        setState(() {
          _reminders = reminders;
          _loading = false;
        });
      } else {
        setState(() {
          _error = res['error']?.toString() ?? 'Failed to load reminders.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleReminder(Reminder r) async {
    // backend only supports "mark complete", not un-complete
    if (r.done) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await api.completeReminder(title: r.title);
      await _loadRemindersFromServer();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _deleteReminder(Reminder r) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await api.deleteReminder(title: r.title);
      await _loadRemindersFromServer();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _clearCompleted() async {
    if (_completedReminders.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      for (final r in _completedReminders) {
        await api.deleteReminder(title: r.title);
      }
      await _loadRemindersFromServer();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ---- Date picker helper ----------------------------------------------

  Future<DateTime?> _pickDate(BuildContext context, {DateTime? initial}) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1);
    final lastDate = DateTime(now.year + 5);

    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (date == null) return null;
    return DateTime(date.year, date.month, date.day);
  }

  // ---- Add reminder dialog ---------------------------------------------

  Future<void> _openAddDialog() async {
    _addTitleController.clear();
    _addDescController.clear();
    _addPriority = 'medium';
    _addDueDate = null;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Reminder'),
          content: Form(
            key: _addFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _addTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter reminder title...',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addDescController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Optional description...',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _addPriority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'low',
                        child: Text('Low'),
                      ),
                      DropdownMenuItem(
                        value: 'medium',
                        child: Text('Medium'),
                      ),
                      DropdownMenuItem(
                        value: 'high',
                        child: Text('High'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _addPriority = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Due date'),
                    subtitle: Text(
                      _addDueDate == null
                          ? 'Tap to select'
                          : '${_addDueDate!.year}-${_addDueDate!.month.toString().padLeft(2, '0')}-${_addDueDate!.day.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final picked =
                          await _pickDate(context, initial: _addDueDate);
                      if (picked != null) {
                        setState(() {
                          _addDueDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: _addReminder,
              child: const Text('Add Reminder'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addReminder() async {
    if (!(_addFormKey.currentState?.validate() ?? false)) return;

    if (_addDueDate == null) {
      setState(() {
        _error = 'Please select a due date.';
      });
      return;
    }

    final title = _addTitleController.text.trim();
    final desc = _addDescController.text.trim();
    final due = _addDueDate!;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await api.createReminder(
        title: title,
        desc: desc,
        status: 'pending',
        priority: _addPriority,
        dueDate: due,
      );

      Navigator.of(context).pop(); // close dialog
      await _loadRemindersFromServer();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ---- Edit reminder dialog --------------------------------------------

  Future<void> _openEditDialog(Reminder r) async {
    _editTitleController.text = r.title;
    _editDescController.text = r.desc;
    _editPriority = r.priority;
    _editStatus = r.status;
    _editDueDate = r.dueDate;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Reminder'),
          content: Form(
            key: _editFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _editTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _editDescController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _editPriority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'low',
                        child: Text('Low'),
                      ),
                      DropdownMenuItem(
                        value: 'medium',
                        child: Text('Medium'),
                      ),
                      DropdownMenuItem(
                        value: 'high',
                        child: Text('High'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _editPriority = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _editStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text('Completed'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _editStatus = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Due date'),
                    subtitle: Text(
                      _editDueDate == null
                          ? 'Tap to select'
                          : '${_editDueDate!.year}-${_editDueDate!.month.toString().padLeft(2, '0')}-${_editDueDate!.day.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final picked =
                          await _pickDate(context, initial: _editDueDate);
                      if (picked != null) {
                        setState(() {
                          _editDueDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _saveEditedReminder(r),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveEditedReminder(Reminder original) async {
    if (!(_editFormKey.currentState?.validate() ?? false)) return;

    if (_editDueDate == null) {
      setState(() {
        _error = 'Please select a due date.';
      });
      return;
    }

    final title = _editTitleController.text.trim();
    final desc = _editDescController.text.trim();
    final due = _editDueDate!;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await api.editReminder(
        title: title,
        desc: desc,
        status: _editStatus,
        priority: _editPriority,
        dueDate: due,
      );

      Navigator.of(context).pop(); // close dialog
      await _loadRemindersFromServer();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ---- UI ---------------------------------------------------------------

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
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Center(child: CircularProgressIndicator()),
                  ),

                // Active reminders
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
                                  onTap: () => _toggleReminder(r),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 12,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                r.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              if (r.desc.isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 4.0),
                                                  child: Text(
                                                    r.desc,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Theme.of(context)
                                                              .hintColor,
                                                    ),
                                                  ),
                                                ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  if (r.date.isNotEmpty)
                                                    Text(
                                                      r.date,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Theme.of(context)
                                                            .hintColor,
                                                      ),
                                                    ),
                                                  const Spacer(),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              999),
                                                      color: Colors.orange
                                                          .withOpacity(0.15),
                                                    ),
                                                    child: Text(
                                                      r.priority
                                                          .toUpperCase(),
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                                size: 20,
                                              ),
                                              onPressed: () =>
                                                  _openEditDialog(r),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                size: 20,
                                              ),
                                              onPressed: () =>
                                                  _deleteReminder(r),
                                            ),
                                          ],
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

                // Completed reminders
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
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              r.title,
                                              style: TextStyle(
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                color:
                                                    Theme.of(context).hintColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (r.date.isNotEmpty)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.only(
                                                        top: 2.0),
                                                child: Text(
                                                  r.date,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Theme.of(context)
                                                        .hintColor,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                        ),
                                        onPressed: () => _deleteReminder(r),
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

                // Stats cards
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

                const SizedBox(height: 80),
              ],
            ),
          ),

          // FAB
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
    _addTitleController.dispose();
    _addDescController.dispose();
    _editTitleController.dispose();
    _editDescController.dispose();
    super.dispose();
  }
}