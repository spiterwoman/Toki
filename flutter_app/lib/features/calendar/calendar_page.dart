import 'package:flutter/material.dart';

import '../../core/widgets/page_shell.dart';
import '../../core/widgets/glass_card.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late int _year;
  late int _month; // 1–12
  late DateTime _selectedDate;

  final List<_UiEvent> _events = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _selectedDate = now;
  }

  // ===== utilities (fmt / parse / buildMonth) ==========================

  String _fmt(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  DateTime _parseKey(String key) {
    final parts = key.split('-');
    final y = int.tryParse(parts[0]) ?? 1970;
    final m = int.tryParse(parts[1]) ?? 1;
    final d = int.tryParse(parts[2]) ?? 1;
    return DateTime(y, m, d);
  }

  List<DateTime> _buildMonth(int year, int month) {
    // month is 1–12; first day of that month
    final first = DateTime(year, month, 1);
    // Start on Monday like the JS version (6 weeks total: 6x7 = 42 days)
    final weekday = first.weekday; // 1=Mon ... 7=Sun
    final daysBefore = (weekday + 6) % 7; // 0 if Monday, 6 if Sunday
    final start = first.subtract(Duration(days: daysBefore));

    return List<DateTime>.generate(
      42,
      (i) => start.add(Duration(days: i)),
    );
  }

  // ===== derived data ==================================================

  List<_UiEvent> get _eventsToday =>
      _events.where((e) => _sameDate(e.date, _selectedDate)).toList();

  List<_UiEvent> get _upcoming {
    final copy = [..._events];
    copy.sort((a, b) => a.date.compareTo(b.date));
    return copy;
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String get _monthLabel =>
      DateTime(_year, _month, 1).toLocal().toString(); // replaced below

  String get _monthLabelPretty {
    final d = DateTime(_year, _month, 1);
    return '${_fmt(d)}';
  }

  static final _monthYearFormat =
      MaterialLocalizations.of; // we’ll not actually use this, see build.

  String get _selectedLabel =>
      MaterialLocalizations.of(context).formatFullDate(_selectedDate);

  void _go(int deltaMonths) {
    final d = DateTime(_year, _month + deltaMonths, 1);
    setState(() {
      _year = d.year;
      _month = d.month;
    });
  }

  void _addEvent(_UiEvent ev) {
    setState(() {
      _events.insert(0, ev);
    });
  }

  void _removeEvent(String id) {
    setState(() {
      _events.removeWhere((e) => e.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = _buildMonth(_year, _month);
    final monthLabel = MaterialLocalizations.of(context)
        .formatMonthYear(DateTime(_year, _month, 1));
    final selectedLabel = MaterialLocalizations.of(context)
        .formatFullDate(_selectedDate);

    return PageShell(
      title: 'Calendar',
      subtitle: 'Plan your cosmic journey',
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // left: month grid
                    Expanded(
                      flex: 6,
                      child: GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: const [
                                      Text('📅',
                                          style: TextStyle(fontSize: 20)),
                                      SizedBox(width: 10),
                                      Text(
                                        'Select Date',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      _SmallGlassButton(
                                        onPressed: () => _go(-1),
                                        child: const Text('<'),
                                      ),
                                      const SizedBox(width: 8),
                                      _SmallGlassButton(
                                        onPressed: () => _go(1),
                                        child: const Text('>'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                monthLabel,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color
                                      ?.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 6),
                              GridView.count(
                                crossAxisCount: 7,
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                children: [
                                  // weekday labels
                                  ...['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                                      .map(
                                    (d) => Center(
                                      child: Text(
                                        d,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.color
                                              ?.withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // days
                                  ...days.map((d) {
                                    final inMonth = d.month == _month;
                                    final isSelected =
                                        _sameDate(d, _selectedDate);
                                    final hasEvent = _events.any(
                                        (e) => _sameDate(e.date, d));

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedDate = d;
                                        });
                                      },
                                      child: Container(
                                        height: 60,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: isSelected
                                              ? Border.all(
                                                  color: const Color.fromRGBO(
                                                    174,
                                                    70,
                                                    255,
                                                    0.45,
                                                  ),
                                                  width: 2,
                                                )
                                              : null,
                                          color: Colors.white
                                              .withOpacity(0.03),
                                        ),
                                        child: Stack(
                                          children: [
                                            Align(
                                              alignment:
                                                  Alignment.topRight,
                                              child: Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  gradient: isSelected
                                                      ? const LinearGradient(
                                                          colors: [
                                                            Color(
                                                                0xFFA855F7),
                                                            Color(
                                                                0xFFEC4899),
                                                          ],
                                                        )
                                                      : null,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '${d.day}',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: isSelected
                                                          ? Colors.white
                                                          : Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (hasEvent)
                                              Positioned(
                                                left: 8,
                                                bottom: 8,
                                                child: Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration:
                                                      const BoxDecoration(
                                                    shape:
                                                        BoxShape.circle,
                                                    color:
                                                        Color(0xFF38BDF8),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 24),

                    // right: events for selected day
                    Expanded(
                      flex: 5,
                      child: GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('📅',
                                      style: TextStyle(fontSize: 20)),
                                  const SizedBox(width: 10),
                                  Text(
                                    selectedLabel,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (_eventsToday.isEmpty)
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
                                  children: _eventsToday.map((ev) {
                                    return Container(
                                      margin:
                                          const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        color: Colors.white
                                            .withOpacity(0.03),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                ev.title,
                                                style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                ev.time ?? 'All day',
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
                                          _SmallGlassButton(
                                            onPressed: () =>
                                                _removeEvent(ev.id),
                                            child: const Text('Delete'),
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
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Upcoming events
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upcoming Events',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (_upcoming.isEmpty)
                          Text(
                            'Add anticipated events to see them on your calendar.',
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
                            children: _upcoming.map((ev) {
                              final grad = _themeGradient(ev.theme);
                              return Container(
                                margin:
                                    const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  gradient: grad,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ev.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatUpcomingLine(ev),
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color
                                                ?.withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                    _SmallGlassButton(
                                      onPressed: () =>
                                          _removeEvent(ev.id),
                                      child: const Text('Delete'),
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
              ],
            ),
          ),

          // floating + button
          Positioned(
            right: 26,
            bottom: 26,
            child: _FloatingAddButton(
              onPressed: () async {
                final newEvent = await showDialog<_UiEvent>(
                  context: context,
                  builder: (ctx) => _AddEventDialog(
                    initialDate: _selectedDate,
                  ),
                );
                if (newEvent != null) {
                  _addEvent(newEvent);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatUpcomingLine(_UiEvent ev) {
    final dateStr = MaterialLocalizations.of(context)
        .formatShortMonthDay(ev.date);
    if (ev.time == null || ev.time!.trim().isEmpty) {
      return dateStr;
    }
    return '$dateStr at ${ev.time}';
  }

  Gradient? _themeGradient(EventTheme theme) {
    switch (theme) {
      case EventTheme.purple:
        return const LinearGradient(
          colors: [
            Color.fromRGBO(168, 85, 247, .18),
            Color.fromRGBO(236, 72, 153, .12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case EventTheme.pink:
        return const LinearGradient(
          colors: [
            Color.fromRGBO(244, 114, 182, .18),
            Color.fromRGBO(251, 113, 133, .12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case EventTheme.blue:
        return const LinearGradient(
          colors: [
            Color.fromRGBO(59, 130, 246, .18),
            Color.fromRGBO(99, 102, 241, .12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}

// ===== models ==========================================================

enum EventTheme { purple, pink, blue }

class _UiEvent {
  final String id;
  final String title;
  final DateTime date;
  final String? time;
  final EventTheme theme;

  _UiEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.theme,
    this.time,
  });
}

// ===== small widgets ===================================================

class _SmallGlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;

  const _SmallGlassButton({
    required this.child,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withOpacity(0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
            color: Colors.white.withOpacity(0.18),
          ),
        ),
      ),
      onPressed: onPressed,
      child: child,
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
          border:
              Border.all(color: Colors.white.withOpacity(0.18)),
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

// ===== add-event dialog ================================================

class _AddEventDialog extends StatefulWidget {
  final DateTime initialDate;

  const _AddEventDialog({required this.initialDate});

  @override
  State<_AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<_AddEventDialog> {
  late DateTime _date;
  final _titleCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  EventTheme _theme = EventTheme.purple;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    final ev = _UiEvent(
      id: UniqueKey().toString(),
      title: title,
      date: _date,
      time: _timeCtrl.text.trim().isEmpty ? null : _timeCtrl.text.trim(),
      theme: _theme,
    );

    Navigator.of(context).pop(ev);
  }

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);

    return AlertDialog(
      title: const Text('Add New Event'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule a new event with a title, date, time, and color theme.',
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
                labelText: 'Event Title',
              ),
            ),
            const SizedBox(height: 8),
            Text('Date',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            OutlinedButton(
              onPressed: _pickDate,
              child: Text(loc.formatShortDate(_date)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _timeCtrl,
              decoration: const InputDecoration(
                labelText: 'Time',
                hintText: 'e.g., 9:00 AM',
              ),
            ),
            const SizedBox(height: 8),
            Text('Color Theme',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            DropdownButton<EventTheme>(
              value: _theme,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: EventTheme.purple,
                  child: Text('Purple'),
                ),
                DropdownMenuItem(
                  value: EventTheme.pink,
                  child: Text('Pink'),
                ),
                DropdownMenuItem(
                  value: EventTheme.blue,
                  child: Text('Blue'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _theme = value;
                  });
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
          child: const Text('Add Event'),
        ),
      ],
    );
  }
}