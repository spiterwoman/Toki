import 'package:flutter/material.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/glass_card.dart';

class DailySummaryPage extends StatefulWidget {
  const DailySummaryPage({super.key});

  @override
  State<DailySummaryPage> createState() => _DailySummaryPageState();
}

class _DailySummaryPageState extends State<DailySummaryPage> {
  final String _date = 'Thursday, October 9, 2025';

  final _weather = const {
    'emoji': '☀️',
    'condition': 'Sunny',
    'high': 82,
    'low': 68,
    'sunrise': '7:12 AM',
    'sunset': '7:45 PM',
  };

  late List<_Task> _tasks;

  final List<_Event> _events = const [
    _Event(
      id: 1,
      title: 'Product Launch',
      time: '2:00 PM',
      location: 'Conference Room A',
    ),
    _Event(
      id: 2,
      title: 'Design Review',
      time: '4:00 PM',
      location: 'Virtual',
    ),
  ];

  final List<_Reminder> _reminders = const [
    _Reminder(id: 1, text: 'Submit expense report'),
    _Reminder(id: 2, text: 'Call dentist for appointment'),
    _Reminder(id: 3, text: 'Pick up dry cleaning'),
  ];

  final String _nasaPhotoUrl =
      'https://images.unsplash.com/photo-1642635715930-b3a1eba9c99f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzcGFjZSUyMHN0YXJzJTIwbmVidWxhfGVufDF8fHx8MTc1OTk3OTAxMXww&ixlib=rb-4.1.0&q=80&w=1080';

  @override
  void initState() {
    super.initState();
    _tasks = [
      const _Task(
        id: 1,
        title: 'Team standup meeting',
        time: '9:00 AM',
        priority: TaskPriority.high,
        completed: true,
      ),
      const _Task(
        id: 2,
        title: 'Review project proposal',
        time: '11:00 AM',
        priority: TaskPriority.high,
        completed: false,
      ),
      const _Task(
        id: 3,
        title: 'Lunch with Sarah',
        time: '12:30 PM',
        priority: TaskPriority.medium,
        completed: false,
      ),
    ];
  }

  void _toggleTask(int id) {
    setState(() {
      _tasks = _tasks
          .map((t) =>
              t.id == id ? t.copyWith(completed: !t.completed) : t)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 1024;

    return PageShell(
      title: 'Good Morning, Astronaut',
      subtitle: _date,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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

  // ===== cards =========================================================

  Widget _buildWeatherCard(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // swap Icons with your lucide assets if you already wired them
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
            Column(
              children: _reminders.map((r) {
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
                      Expanded(child: Text(r.text)),
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
                child: Image.network(
                  _nasaPhotoUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "A stunning view of the cosmos captured by NASA's telescopes",
              style: TextStyle(
                fontSize: 14,
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
  final int id;
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
  final int id;
  final String title;
  final String time;
  final String location;

  const _Event({
    required this.id,
    required this.title,
    required this.time,
    required this.location,
  });
}

class _Reminder {
  final int id;
  final String text;

  const _Reminder({required this.id, required this.text});
}