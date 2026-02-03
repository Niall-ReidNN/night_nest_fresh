import 'dart:math';

import 'package:flutter/material.dart';

/// Flat "globe" (disc) screen with many small glowing yellow dots.
/// This is a stylized, original UI effect and does not use copyrighted assets.
class GlobeScreen extends StatefulWidget {
  const GlobeScreen({super.key});

  @override
  State<GlobeScreen> createState() => _GlobeScreenState();
}

class _GlobeScreenState extends State<GlobeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<_DotSpec> _dots = [];

  @override
  void initState() {
    super.initState();

    // Create a deterministic set of dot positions for a stable visual
    final rnd = Random(12345);
    for (var i = 0; i < 64; i++) {
      _dots.add(
        _DotSpec(
          angle: rnd.nextDouble() * pi * 2,
          radiusFraction: 0.1 + rnd.nextDouble() * 0.85,
          phase: rnd.nextDouble() * pi * 2,
        ),
      );
    }

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community Globe')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            SizedBox(
              width: 340,
              height: 340,
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, child) {
                  final t = _ctrl.value * 2 * pi;
                  return CustomPaint(painter: _FlatGlobePainter(_dots, t));
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Parents nearby — visual effect',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotSpec {
  final double angle;
  final double radiusFraction;
  final double phase;

  _DotSpec({
    required this.angle,
    required this.radiusFraction,
    required this.phase,
  });
}

class _FlatGlobePainter extends CustomPainter {
  final List<_DotSpec> dots;
  final double rotation;

  _FlatGlobePainter(this.dots, this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;

    // Disc background (flat earth look)
    final rect = Rect.fromCircle(center: center, radius: radius);
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF071A1D), const Color(0xFF001011)],
        stops: const [0.0, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, radius, bgPaint);

    // Stylized rings / subtle grid
    final ringPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withAlpha(18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final r = radius * (0.6 + i * 0.07);
      canvas.drawCircle(center, r, ringPaint);
    }

    // Subtle equator
    final eqPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withAlpha(28)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      center - Offset(radius, 0),
      center + Offset(radius, 0),
      eqPaint,
    );

    // Yellow dots with glow/pulse
    for (final d in dots) {
      final angle = d.angle + rotation;
      final r = radius * d.radiusFraction;
      final pos = center + Offset(cos(angle) * r, sin(angle) * r);

      // pulsing
      final scale = 0.6 + 0.4 * (0.5 + 0.5 * sin(rotation * 1.5 + d.phase));
      final dotRadius = 2.5 * scale;

      // glow behind
      final glowPaint = Paint()
        ..color = const Color(0xFFFFD54F).withAlpha(70)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(pos, dotRadius * 3.2, glowPaint);

      // core
      final corePaint = Paint()..color = const Color(0xFFFFEB3B);
      canvas.drawCircle(pos, dotRadius, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FlatGlobePainter old) =>
      old.rotation != rotation || old.dots != dots;
}
