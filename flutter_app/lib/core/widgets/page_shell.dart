import 'package:flutter/material.dart';
import 'hamburger_menu.dart';
import 'starry_background.dart';

class PageShell extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final bool showMenu;
  final Widget child;

  const PageShell({
    super.key,
    this.title,
    this.subtitle,
    this.showMenu = true,
    required this.child,
  });

  @override
  State<PageShell> createState() => _PageShellState();
}

class _PageShellState extends State<PageShell> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    // extra top padding so content doesn't collide with the menu button
    final double contentTopPad =
        (widget.showMenu ? 72.0 : 16.0) + MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          const StarryBackground(),

          // 1) CONTENT FIRST (so it's under the button)
          Positioned.fill(
            child: SafeArea(
              // give more room at the top so the title doesn't sit under the button
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, contentTopPad, 20, 16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.title != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            widget.title!,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      if (widget.subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            widget.subtitle!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                      widget.child,
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2) MENU BUTTON AFTER CONTENT (so it sits on top and gets taps)
          if (widget.showMenu)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 12,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,         // full box is tappable
                onTap: () => setState(() => open = !open),
                child: Container(
                  padding: const EdgeInsets.all(16),      // generous hitbox
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    open ? '×' : '☰',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
            ),

          // 3) HAMBURGER MENU OVERLAY (on very top when open)
          HamburgerMenu(open: open, onClose: () => setState(() => open = false)),
        ],
      ),
    );
  }
}
