import 'package:flutter/material.dart';
import 'glass_card.dart';

class HamburgerMenu extends StatelessWidget {
  final bool open;
  final VoidCallback onClose;

  const HamburgerMenu({super.key, required this.open, required this.onClose});

  static const _items = [
    ('Daily Summary', '/daily-summary'),
    ('Calendar', '/calendar'),
    ('Tasks', '/tasks'),
    ('Reminders', '/reminders'),
    ('Weather', '/weather'),
    ('NASA Photo', '/nasa-photo'),
    ('UCF Parking', '/parking'),
  ];

  static const double _panelWidth = 300;

  @override
  Widget build(BuildContext context) {
    final pathname = ModalRoute.of(context)?.settings.name ?? '';

    return Stack(
      children: [
        // SCRIM
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !open,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: open ? 1 : 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
                child: Container(color: Colors.black54),
              ),
            ),
          ),
        ),

        // SIDEBAR PANEL
        AnimatedPositioned(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          left: open ? 0 : -_panelWidth,
          top: 0,
          bottom: 0,
          child: SafeArea(
            child: SizedBox(
              width: _panelWidth,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Padding(
                        padding: EdgeInsets.only(left: 2, bottom: 10),
                        child: Text('Toki',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            )),
                      ),

                      // Menu list (scrolls if needed)
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemBuilder: (context, i) {
                            final (label, route) = _items[i];
                            final selected = pathname == route;
                            return _MenuItem(
                              label: label,
                              selected: selected,
                              onTap: () {
                                onClose();
                                if (!selected) {
                                  Navigator.of(context).pushNamed(route);
                                }
                              },
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemCount: _items.length,
                        ),
                      ),

                      // Divider
                      Opacity(
                        opacity: 0.6,
                        child: Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),

                      // Logout button (stays inside the card)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color.fromRGBO(255, 99, 99, .35),
                            ),
                            backgroundColor: const Color.fromRGBO(255, 0, 0, .06),
                            foregroundColor: const Color(0xFFFF7B7B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 12),
                          ),
                          onPressed: () {
                            onClose();
                            Navigator.of(context).pushNamed('/login');
                          },
                          child: const Text('Logout',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MenuItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white.withOpacity(0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          // Big tap target
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
