import 'package:flutter/material.dart';

import '../../core/widgets/page_shell.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/api/api.dart';

final api = Api('https://mytoki.app');

// ===== helpers for priority mapping =====================================

TaskPriority _priorityFromString(String raw) {
  switch (raw.toLowerCase()) {
    case 'low':
      return TaskPriority.low;
    case 'high':
      return TaskPriority.high;
    case 'medium':
    default:
      return TaskPriority.medium;
  }
}

String _priorityToString(TaskPriority p) {
  switch (p) {
    case TaskPriority.low:
      return 'low';
    case TaskPriority.medium:
      return 'medium';
    case TaskPriority.high:
      return 'high';
  }
}

// ===== page ==============================================================

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final List<_Task> _tasks = [];

  bool _loading = false;
  String? _error;

  int get _doneCount => _tasks.where((t) => t.done).length;

  @override
  void initState() {
    super.initState();
    _loadTasksFromServer();
  }

  // ---- API wiring -------------------------------------------------------

  Future<void> _loadTasksFromServer() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await api.viewTasks(); // no taskId -> all tasks
      if (res['success'] == true) {
        final list = (res['tasks'] as List?) ?? [];
        final tasks = list
            .map((e) => _Task.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        setState(() {
          _tasks
            ..clear()
            ..addAll(tasks);
          _loading = false;
        });
      } else {
        setState(() {
          _error = res['error']?.toString() ?? 'Failed to load tasks.';
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

  Future<void> _createTaskOnServer(_Task localTask) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await api.createTask(
        title: localTask.title,
        description:
            localTask.description.isEmpty ? null : localTask.description,
        status: localTask.status, // e.g. "not started"
        priority: _priorityToString(localTask.priority),
        dueDate: localTask.dueDate,
        isCompleted: localTask.done,
        completedAt: localTask.done ? DateTime.now() : null,
      );

      await _loadTasksFromServer();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggle(String id) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final current = _tasks[idx];
    final newDone = !current.done;
    final newStatus = newDone ? 'completed' : 'not started';

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await api.editTask(
        taskId: id,
        status: newStatus,
        isCompleted: newDone,
        completedAt: newDone ? DateTime.now() : null,
      );

      await _loadTasksFromServer();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _remove(String id) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await api.deleteTask(taskId: id);
      await _loadTasksFromServer();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _clearCompleted() async {
    final ids = _tasks.where((t) => t.done).map((t) => t.id).toList();
    if (ids.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      for (final id in ids) {
        await api.deleteTask(taskId: id);
      }
      await _loadTasksFromServer();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openAddTaskDialog() async {
    final newTask = await showDialog<_Task>(
      context: context,
      builder: (ctx) => const _AddTaskDialog(),
    );
    if (newTask != null) {
      await _createTaskOnServer(newTask);
    }
  }

  Future<void> _openEditTaskDialog(_Task task) async {
    final updated = await showDialog<_Task>(
      context: context,
      builder: (ctx) => _EditTaskDialog(task: task),
    );
    if (updated == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await api.editTask(
        taskId: task.id,
        title: updated.title,
        description:
            updated.description.isEmpty ? null : updated.description,
        status: updated.status,
        priority: _priorityToString(updated.priority),
        dueDate: updated.dueDate,
        isCompleted: updated.done,
        completedAt: updated.done ? DateTime.now() : null,
      );

      await _loadTasksFromServer();
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
    final subtitle = '${_doneCount} of ${_tasks.length} tasks completed';

    return PageShell(
      title: 'Tasks',
      subtitle: subtitle,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
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

                // All tasks card
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'All Tasks',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Manage your daily tasks',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withOpacity(0.7),
                              ),
                            ),
                            if (_doneCount > 0)
                              TextButton(
                                onPressed: _clearCompleted,
                                child: const Text('Clear Completed'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_tasks.isEmpty)
                          Text(
                            'No tasks yet. Use the + button to add one.',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withOpacity(0.7),
                            ),
                          )
                        else
                          Column(
                            children: _tasks.map((t) {
                              final subtitlePieces = <String>[
                                if (t.dueDateString.isNotEmpty)
                                  t.dueDateString,
                                t.tag.label,
                                t.status,
                              ];
                              final subline = subtitlePieces.join(' | ');

                              return Container(
                                key: ValueKey(t.id),
                                margin:
                                    const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white.withOpacity(0.03),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Checkbox(
                                          value: t.done,
                                          onChanged: (_) => _toggle(t.id),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              t.title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                decoration: t.done
                                                    ? TextDecoration
                                                        .lineThrough
                                                    : null,
                                              ),
                                            ),
                                            if (t.description.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 3),
                                                child: Text(
                                                  t.description,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.color
                                                        ?.withOpacity(0.7),
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(height: 4),
                                            Text(
                                              subline,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.color
                                                    ?.withOpacity(0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        _PriorityBadge(priority: t.priority),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              _openEditTaskDialog(t),
                                        ),
                                        TextButton(
                                          onPressed: () => _remove(t.id),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  ],
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
                GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StatCard(
                      label: 'Total Tasks',
                      value: _tasks.length,
                    ),
                    _StatCard(
                      label: 'Completed',
                      value: _doneCount,
                    ),
                    _StatCard(
                      label: 'Remaining',
                      value: _tasks.length - _doneCount,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Floating + button
          Positioned(
            right: 26,
            bottom: 26,
            child: _FloatingAddButton(
              onPressed: _openAddTaskDialog,
            ),
          ),
        ],
      ),
    );
  }
}

// ===== models ==========================================================

enum TaskTag { work, personal, school }

extension on TaskTag {
  String get label {
    switch (this) {
      case TaskTag.work:
        return 'Work';
      case TaskTag.personal:
        return 'Personal';
      case TaskTag.school:
        return 'School';
    }
  }
}

enum TaskPriority { low, medium, high }

class _Task {
  final String id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final TaskTag tag;
  final TaskPriority priority;
  final String status; // "not started", "in progress", "completed", etc.
  final bool done;

  _Task({
    required this.id,
    required this.title,
    required this.description,
    required this.tag,
    required this.priority,
    required this.status,
    this.dueDate,
    this.done = false,
  });

  String get dueDateString {
    if (dueDate == null) return '';
    final dt = dueDate!;
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  factory _Task.fromJson(Map<String, dynamic> json) {
    final id = json['_id']?.toString() ?? '';
    final title = json['title'] as String? ?? '';
    final description = json['description'] as String? ?? '';
    final status = json['status'] as String? ?? 'not started';

    // priority string from backend
    final priorityStr = (json['priority'] as String? ?? 'medium');
    final priority = _priorityFromString(priorityStr);

    // dueDate from backend
    DateTime? dueDate;
    final dueRaw = json['dueDate'];
    if (dueRaw != null) {
      try {
        dueDate = DateTime.parse(dueRaw.toString());
      } catch (_) {
        dueDate = null;
      }
    }

    // completed
    final completed = json['completed'];
    bool done = false;
    if (completed is Map && completed['isCompleted'] == true) {
      done = true;
    } else if (status.toLowerCase() == 'completed') {
      done = true;
    }

    return _Task(
      id: id,
      title: title,
      description: description,
      tag: TaskTag.work, // backend has no tag; local categorization only
      priority: priority,
      dueDate: dueDate,
      status: status,
      done: done,
    );
  }

  _Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskTag? tag,
    TaskPriority? priority,
    String? status,
    bool? done,
  }) {
    return _Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      tag: tag ?? this.tag,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      done: done ?? this.done,
    );
  }
}

// ===== widgets: badges / stats / FAB / dialogs =========================

class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color base;
    switch (priority) {
      case TaskPriority.high:
        base = Colors.redAccent;
        break;
      case TaskPriority.medium:
        base = Colors.orangeAccent;
        break;
      case TaskPriority.low:
        base = Colors.greenAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: base.withOpacity(0.15),
        border: Border.all(color: base.withOpacity(0.7)),
      ),
      child: Text(
        priority.name, // "low" | "medium" | "high"
        style: TextStyle(
          fontSize: 12,
          color: base,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;

  const _StatCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingAddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _FloatingAddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.18)),
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, .35),
              offset: Offset(0, 10),
              blurRadius: 30,
            ),
            BoxShadow(
              color: Color.fromRGBO(236, 72, 153, .25),
              offset: Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: const Center(
          child: Text(
            '+',
            style: TextStyle(fontSize: 28, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ---- Add dialog --------------------------------------------------------

class _AddTaskDialog extends StatefulWidget {
  const _AddTaskDialog();

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _dueDate;
  TaskTag _tag = TaskTag.work;
  TaskPriority _priority = TaskPriority.medium;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1);
    final lastDate = DateTime(now.year + 5);

    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        _dueDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    final task = _Task(
      id: UniqueKey().toString(), // temp; real ID comes from backend
      title: title,
      description: _descCtrl.text.trim(),
      dueDate: _dueDate,
      tag: _tag,
      priority: _priority,
      status: 'not started',
      done: false,
    );

    Navigator.of(context).pop(task);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Task'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create a task with title, description, due date, and priority.',
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                hintText: 'Enter task title',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Optional description',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Due date'),
              subtitle: Text(
                _dueDate == null
                    ? 'Tap to select (optional)'
                    : '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<TaskTag>(
              value: _tag,
              decoration: const InputDecoration(labelText: 'Tag'),
              items: const [
                DropdownMenuItem(
                  value: TaskTag.work,
                  child: Text('Work'),
                ),
                DropdownMenuItem(
                  value: TaskTag.personal,
                  child: Text('Personal'),
                ),
                DropdownMenuItem(
                  value: TaskTag.school,
                  child: Text('School'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _tag = value);
                }
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<TaskPriority>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: const [
                DropdownMenuItem(
                  value: TaskPriority.low,
                  child: Text('low'),
                ),
                DropdownMenuItem(
                  value: TaskPriority.medium,
                  child: Text('medium'),
                ),
                DropdownMenuItem(
                  value: TaskPriority.high,
                  child: Text('high'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _priority = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Add Task'),
        ),
      ],
    );
  }
}

// ---- Edit dialog -------------------------------------------------------

class _EditTaskDialog extends StatefulWidget {
  final _Task task;

  const _EditTaskDialog({required this.task});

  @override
  State<_EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<_EditTaskDialog> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  DateTime? _dueDate;
  late TaskPriority _priority;
  late String _status; // "not started", "in progress", "completed"
  late bool _done;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);
    _descCtrl = TextEditingController(text: widget.task.description);
    _dueDate = widget.task.dueDate;
    _priority = widget.task.priority;
    _status = widget.task.status;
    _done = widget.task.done;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1);
    final lastDate = DateTime(now.year + 5);

    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        _dueDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    // If user sets status to "completed", mark done true
    _done = _status.toLowerCase() == 'completed';

    final updated = widget.task.copyWith(
      title: title,
      description: _descCtrl.text.trim(),
      dueDate: _dueDate,
      priority: _priority,
      status: _status,
      done: _done,
    );

    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Task'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Task Title',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Due date'),
              subtitle: Text(
                _dueDate == null
                    ? 'Tap to select (optional)'
                    : '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<TaskPriority>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: const [
                DropdownMenuItem(
                  value: TaskPriority.low,
                  child: Text('low'),
                ),
                DropdownMenuItem(
                  value: TaskPriority.medium,
                  child: Text('medium'),
                ),
                DropdownMenuItem(
                  value: TaskPriority.high,
                  child: Text('high'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _priority = value);
                }
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(
                  value: 'not started',
                  child: Text('Not started'),
                ),
                DropdownMenuItem(
                  value: 'in progress',
                  child: Text('In progress'),
                ),
                DropdownMenuItem(
                  value: 'completed',
                  child: Text('Completed'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _status = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
