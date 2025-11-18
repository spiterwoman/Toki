import 'package:flutter/material.dart';

import '../../core/widgets/page_shell.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/api/api.dart';

// Reuse the same Api instance pattern as elsewhere
final api = Api('https://mytoki.app');

class DailySummaryPage extends StatefulWidget {
  const DailySummaryPage({super.key});

  @override
  State<DailySummaryPage> createState() => _DailySummaryPageState();
}

class _DailySummaryPageState extends State<DailySummaryPage> {
  // Weather is still static for now
  final _weather = const {
    'emoji': '☀️',
    'condition': 'Sunny',
    'high': 82,
    'low': 68,
    'sunrise': '7:12 AM',
    'sunset': '7:45 PM',
  };

  // State from backend
  List<_Task> _tasks = [];
  List<_Event> _events = []; // today's calendar events
  List<_Reminder> _reminders = [];

  // NASA APOD for today
  String? _nasaPhotoUrl;
  String? _nasaTitle;
  String? _nasaExplanation;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ====== loaders =======================================================

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _loadTasksFromServer(),
        _loadRemindersFromServer(),
        _loadCalendarEventsFromServer(),
        _loadNasaPhotoFromServer(),
      ]);

      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ---- Tasks: /api/viewTask --------------------------------------------

  Future<void> _loadTasksFromServer() async {
    try {
      // assuming your api.dart defined: Future<Map<String,dynamic>> viewTasks({String? taskId})
      final res = await api.viewTasks(); // no taskId => all tasks

      if (res['success'] == true) {
        final list = (res['tasks'] as List?) ?? [];
        final today = DateTime.now();

        final tasks = <_Task>[];

        for (final raw in list) {
          final m = Map<String, dynamic>.from(raw as Map);

          final id = m['_id']?.toString() ?? '';
          final title = m['title'] as String? ?? '';

          // Parse dueDate if present
          DateTime? due;
          final dueRaw = m['dueDate'];
          if (dueRaw != null) {
            try {
              due = DateTime.parse(dueRaw.toString());
            } catch (_) {}
          }

          // Only show tasks due today (if dueDate is non-null)
          if (due == null || !_sameDay(due, today)) continue;

          // Build time string if due has a time component
          String timeStr = 'Today';
          if (due.hour != 0 || due.minute != 0) {
            final hour12 = (due.hour % 12 == 0) ? 12 : due.hour % 12;
            final ampm = due.hour < 12 ? 'AM' : 'PM';
            timeStr = '$hour12:${due.minute.toString().padLeft(2, '0')} $ampm';
          }

          // Priority string -> enum
          TaskPriority priority = TaskPriority.medium;
          final p = (m['priority'] as String?)?.toLowerCase();
          if (p == 'low') {
            priority = TaskPriority.low;
          } else if (p == 'high') {
            priority = TaskPriority.high;
          }

          // completed object: { isCompleted: bool, completedAt: ... }
          bool completed = false;
          final completedRaw = m['completed'];
          if (completedRaw is Map && completedRaw['isCompleted'] == true) {
            completed = true;
          }

          tasks.add(
            _Task(
              id: id,
              title: title,
              time: timeStr,
              priority: priority,
              completed: completed,
            ),
          );
        }

        if (!mounted) return;
        setState(() {
          _tasks = tasks;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _error ??= res['error']?.toString() ?? 'Failed to load tasks.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error ??= e.toString();
      });
    }
  }

  // ---- Reminders: /api/viewReminder ------------------------------------

  Future<void> _loadRemindersFromServer() async {
    try {
      final res = await api.viewReminders(); // no reminderId => all reminders

      if (res['success'] == true) {
        final list = (res['reminders'] as List?) ?? [];

        final reminders = list.map((raw) {
          final m = Map<String, dynamic>.from(raw as Map);
          return _Reminder.fromJson(m);
        }).toList();

        if (!mounted) return;
        setState(() {
          _reminders = reminders;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _error ??=
              res['error']?.toString() ?? 'Failed to load reminders.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error ??= e.toString();
      });
    }
  }

  // ---- Calendar: /api/viewCalendarEvent (today only) -------------------

  Future<void> _loadCalendarEventsFromServer() async {
    try {
      final res = await api.viewCalendarEvents(); // all events

      if (res['success'] == true) {
        final list = (res['events'] as List?) ?? [];
        final today = DateTime.now();

        final events = <_Event>[];

        for (final raw in list) {
          final m = Map<String, dynamic>.from(raw as Map);

          final id = m['_id']?.toString() ?? '';
          final title = m['title'] as String? ?? '';
          final location = m['location'] as String? ?? 'No location';

          DateTime? start;
          final startRaw = m['startDate'];
          if (startRaw != null) {
            try {
              start = DateTime.parse(startRaw.toString());
            } catch (_) {}
          }
          if (start == null) continue;

          // Only events happening today
          if (!_sameDay(start, today)) continue;

          String timeStr = 'All day';
          if (start.hour != 0 || start.minute != 0) {
            final hour12 = (start.hour % 12 == 0) ? 12 : start.hour % 12;
            final ampm = start.hour < 12 ? 'AM' : 'PM';
            timeStr =
                '$hour12:${start.minute.toString().padLeft(2, '0')} $ampm';
          }

          events.add(
            _Event(
              id: id,
              title: title,
              start: start,
              time: timeStr,
              location: location,
            ),
          );
        }

        // Sort by start time
        events.sort((a, b) => a.start.compareTo(b.start));

        if (!mounted) return;
        setState(() {
          _events = events;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _error ??=
              res['error']?.toString() ?? 'Failed to load calendar events.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error ??= e.toString();
      });
    }
  }

  // ---- NASA APOD: /api/viewAPOD ---------------------------------------

  Future<void> _loadNasaPhotoFromServer() async {
    try {
      final today = DateTime.now();
      final res = await api.viewApod(date: today);

      if (res['success'] == true) {
        final hd = res['hdurl'] as String?;
        final thumb = res['thumbnailUrl'] as String?;
        final title = res['title'] as String?;
        final explanation = res['explanation'] as String?;

        if (!mounted) return;
        setState(() {
          _nasaPhotoUrl = hd ?? thumb;
          _nasaTitle = title?.isNotEmpty == true
              ? title
              : 'NASA Astronomy Picture of the Day';
          _nasaExplanation = explanation;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _nasaPhotoUrl = null;
          _nasaTitle = 'NASA Astronomy Picture of the Day';
          _nasaExplanation =
              res['error']?.toString() ?? 'Unable to load APOD.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _nasaPhotoUrl = null;
        _nasaTitle = 'NASA Astronomy Picture of the Day';
        _nasaExplanation = e.toString();
      });
    }
  }

  // Local toggle (UI only) for the checkboxes
  void _toggleTask(String id) {
    setState(() {
      _tasks = _tasks
          .map((t) =>
              t.id == id ? t.copyWith(completed: !t.completed) : t)
          .toList();
    });
  }

  // ===== UI =============================================================

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 1024;
    final todayLabel =
        MaterialLocalizations.of(context).formatFullDate(DateTime.now());

    return PageShell(
      title: 'Good Morning, Astronaut',
      subtitle: todayLabel,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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

            // Top grid: Weather / Tasks / Events
            LayoutBuilder(
              builder: (context, constraints) {
                final small = constraints.maxWidth < 1024;
                final crossAxisCount = small ? 1 : 3;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: small ? 1.1 : 1.0,
                  children: [
                    _buildWeatherCard(context),
                    _buildTasksCard(context),
                    _buildEventsCard(context),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Bottom: Reminders + NASA photo (responsive)
            if (isSmallScreen)
              Column(
                children: [
                  _buildRemindersCard(context),
                  const SizedBox(height: 24),
                  _buildNasaPhotoCard(context),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: _buildRemindersCard(context),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: _buildNasaPhotoCard(context),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ===== cards ==========================================================

  Widget _buildWeatherCard(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud, color: Colors.lightBlue[300], size: 20),
                const SizedBox(width: 8),
                const Text(
                  "Today's Weather",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _weather['emoji'] as String,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 8),
                Text(_weather['condition'] as String),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        const Text('High'),
                        Text(
                          '${_weather['high']}°',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Column(
                      children: [
                        const Text('Low'),
                        Text(
                          '${_weather['low']}°',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DefaultTextStyle(
                  style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey) ??
                      const TextStyle(fontSize: 12, color: Colors.grey),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.wb_sunny_outlined, size: 16),
                          const SizedBox(width: 4),
                          Text(_weather['sunrise'] as String),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Row(
                        children: [
                          const Icon(Icons.nights_stay_outlined, size: 16),
                          const SizedBox(width: 4),
                          Text(_weather['sunset'] as String),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksCard(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[300], size: 20),
                const SizedBox(width: 8),
                const Text(
                  "Today's Tasks",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_tasks.isEmpty)
              Text(
                'No tasks due today.',
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
                  final titleStyle = TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration:
                        t.completed ? TextDecoration.lineThrough : null,
                    color: t.completed
                        ? Colors.white.withOpacity(0.5)
                        : Colors.white,
                  );
                  final timeStyle = TextStyle(
                    color: Colors.grey.withOpacity(t.completed ? 0.5 : 1.0),
                  );

                  return Padding(
                    key: ValueKey(t.id),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Checkbox(
                                value: t.completed,
                                onChanged: (_) => _toggleTask(t.id),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.title, style: titleStyle),
                                  const SizedBox(height: 4),
                                  Text(t.time, style: timeStyle),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _buildPriorityBadge(t.priority),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsCard(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today,
                    color: Colors.purple[200], size: 20),
                const SizedBox(width: 8),
                const Text(
                  "Today's Events",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_events.isEmpty)
              Text(
                'No events today.',
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
                children: _events.map((e) {
                  return Container(
                    key: ValueKey(e.id),
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(0.03),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          e.time,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          e.location,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersCard(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.notifications,
                    color: Colors.yellow[400], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Reminders',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_reminders.isEmpty)
              Text(
                'No reminders yet.',
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
                children: _reminders.map((r) {
                  final textStyle = TextStyle(
                    color: r.done
                        ? Colors.white.withOpacity(0.5)
                        : Colors.white,
                    decoration:
                        r.done ? TextDecoration.lineThrough : null,
                  );

                  return Padding(
                    key: ValueKey(r.id),
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.yellow[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(child: Text(r.text, style: textStyle)),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNasaPhotoCard(BuildContext context) {
    final title = _nasaTitle ??
        'NASA Astronomy Picture of the Day';
    final explanation = _nasaExplanation ??
        'A stunning view of the cosmos captured by NASA\'s telescopes.';
    final imageUrl = _nasaPhotoUrl;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wb_sunny, color: Colors.orange[300], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'NASA Photo of the Day',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl == null
                    ? Container(
                        color: Colors.white.withOpacity(0.05),
                        alignment: Alignment.center,
                        child: const Text(
                          'Image unavailable',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              explanation,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== helpers / models ==============================================

  Widget _buildPriorityBadge(TaskPriority priority) {
    Color bg;
    switch (priority) {
      case TaskPriority.high:
        bg = Colors.redAccent;
        break;
      case TaskPriority.medium:
        bg = Colors.orangeAccent;
        break;
      case TaskPriority.low:
        bg = Colors.greenAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: bg.withOpacity(0.7)),
      ),
      child: Text(
        priority.name,
        style: TextStyle(
          fontSize: 12,
          color: bg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

enum TaskPriority { high, medium, low }

class _Task {
  final String id;
  final String title;
  final String time;
  final TaskPriority priority;
  final bool completed;

  const _Task({
    required this.id,
    required this.title,
    required this.time,
    required this.priority,
    required this.completed,
  });

  _Task copyWith({bool? completed}) {
    return _Task(
      id: id,
      title: title,
      time: time,
      priority: priority,
      completed: completed ?? this.completed,
    );
  }
}

class _Event {
  final String id;
  final String title;
  final DateTime start;
  final String time;
  final String location;

  const _Event({
    required this.id,
    required this.title,
    required this.start,
    required this.time,
    required this.location,
  });
}

class _Reminder {
  final String id;
  final String text;
  final bool done;

  const _Reminder({
    required this.id,
    required this.text,
    required this.done,
  });

  factory _Reminder.fromJson(Map<String, dynamic> json) {
    final id = json['_id']?.toString() ?? '';
    final title = json['title'] as String? ?? '';

    bool done = false;
    final completed = json['completed'];
    if (completed is Map && completed['isCompleted'] == true) {
      done = true;
    }

    return _Reminder(
      id: id,
      text: title,
      done: done,
    );
  }
}
