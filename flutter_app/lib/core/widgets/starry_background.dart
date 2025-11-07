import 'dart:math';
import 'package:flutter/material.dart';

class StarryBackground extends StatefulWidget {
  const StarryBackground({super.key});

  @override
  State<StarryBackground> createState() => _StarryBackgroundState();
}

class _StarryBackgroundState extends State<StarryBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _rand = Random();
  late List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController.unbounded(vsync: this)
      ..addListener(() => setState(() {}))
      ..repeat(min: 0, max: 1, period: const Duration(milliseconds: 16));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _makeStars(MediaQuery.sizeOf(context));
    });
  }

  void _makeStars(Size size) {
    const count = 200;
    _stars = List.generate(count, (_) {
      final r = _rand.nextDouble() * 1.5 + 0.5;
      final a = _rand.nextDouble() * 0.7 + 0.3;
      final da = (_rand.nextDouble() * 0.6 + 0.2) * (_rand.nextBool() ? -1 : 1);
      return _Star(
        x: _rand.nextDouble() * size.width,
        y: _rand.nextDouble() * size.height,
        r: r,
        a: a,
        da: da,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _makeStars(MediaQuery.sizeOf(context));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // radial “nebula” gradients (like the TSX)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.8, -1.0),
                    radius: 1.2,
                    colors: const [Color(0xFF1B2142), Color(0x000B1020)],
                    stops: const [0.0, 0.6],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-1.1, 1.0),
                    radius: 1.0,
                    colors: const [Color(0xFF221A2A), Color(0x000F1730)],
                    stops: const [0.0, 0.6],
                  ),
                ),
              ),
            ),
            // stars
            CustomPaint(size: size, painter: _StarsPainter(_stars)),
            // “planets”
            Positioned(
              top: 80,
              right: 80,
              child: _Planet(diameter: 128, c1: const Color(0xFF8B7DD8), c2: const Color(0xFF5A4A9A)),
            ),
            Positioned(
              bottom: 160,
              left: 40,
              child: _Planet(diameter: 96, c1: const Color(0xFFD88B7D), c2: const Color(0xFF9A5A4A)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Star {
  double x, y, r, a, da;
  _Star({required this.x, required this.y, required this.r, required this.a, required this.da});
}

class _StarsPainter extends CustomPainter {
  final List<_Star> stars;
  _StarsPainter(this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (final s in stars) {
      paint.color = Colors.white.withOpacity(s.a.clamp(0.25, 1.0));
      canvas.drawCircle(Offset(s.x, s.y), s.r, paint);
      // twinkle
      s.a += s.da * 0.01;
      if (s.a > 1) { s.a = 1; s.da *= -1; }
      if (s.a < 0.25) { s.a = 0.25; s.da *= -1; }
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) => true;
}

class _Planet extends StatelessWidget {
  final double diameter;
  final Color c1, c2;
  const _Planet({required this.diameter, required this.c1, required this.c2});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.18,
      child: ClipOval(
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.4, -0.4),
              colors: [c1, c2],
            ),
          ),
        ),
      ),
    );
  }
}
