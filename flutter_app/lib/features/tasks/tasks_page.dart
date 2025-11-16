import 'package:flutter/material.dart';

import '../../core/widgets/page_shell.dart';
import '../../core/widgets/glass_card.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final List<_Task> _tasks = [];

  int get _doneCount => _tasks.where((t) => t.done).length;

  void _toggle(String id) {
    setState(() {
      for (var i = 0; i < _tasks.length; i++) {
        if (_tasks[i].id == id) {
          _tasks[i] = _tasks[i].copyWith(done: !_tasks[i].done);
          break;
        }
      }
    });
  }

  void _remove(String id) {
    setState(() {
      _tasks.removeWhere((t) => t.id == id);
    });
  }

  void _clearCompleted() {
    setState(() {
      _tasks.removeWhere((t) => t.done);
    });
  }

  void _addTask(_Task task) {
    setState(() {
      _tasks.insert(0, task);
    });
  }

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
                              final subtitlePieces = [
                                if (t.time != null && t.time!.isNotEmpty)
                                  t.time!,
                                t.tag.label,
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
                                        const SizedBox(width: 8),
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
              onPressed: () async {
                final newTask = await showDialog<_Task>(
                  context: context,
                  builder: (ctx) => const _AddTaskDialog(),
                );
                if (newTask != null) {
                  _addTask(newTask);
                }
              },
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
  final String? time;
  final TaskTag tag;
  final TaskPriority priority;
  final bool done;

  _Task({
    required this.id,
    required this.title,
    required this.tag,
    required this.priority,
    this.time,
    this.done = false,
  });

  _Task copyWith({
    String? id,
    String? title,
    String? time,
    TaskTag? tag,
    TaskPriority? priority,
    bool? done,
  }) {
    return _Task(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      tag: tag ?? this.tag,
      priority: priority ?? this.priority,
      done: done ?? this.done,
    );
  }
}

// ===== widgets: badges / stats / FAB / dialog =========================

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

class _AddTaskDialog extends StatefulWidget {
  const _AddTaskDialog();

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _titleCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  TaskTag _tag = TaskTag.work;
  TaskPriority _priority = TaskPriority.medium;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    final task = _Task(
      id: UniqueKey().toString(),
      title: title,
      time: _timeCtrl.text.trim().isEmpty ? null : _timeCtrl.text.trim(),
      tag: _tag,
      priority: _priority,
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
              'Create a task with title, time, tag, and priority.',
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
              controller: _timeCtrl,
              decoration: const InputDecoration(
                labelText: 'Time',
                hintText: 'e.g., 2:30 PM',
              ),
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 4),
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