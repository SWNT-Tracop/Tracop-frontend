import 'dart:math' as math;

import 'package:flutter/material.dart';

class LeafSplashAnimation extends StatefulWidget {
  const LeafSplashAnimation({super.key, this.size = 132});

  final double size;

  @override
  State<LeafSplashAnimation> createState() => _LeafSplashAnimationState();
}

class _LeafSplashAnimationState extends State<LeafSplashAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1270),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Isotipo TRACOP: dos hojas dibujándose',
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _LeafPainter(
                  progress: Curves.easeInOutCubic.transform(_controller.value)),
            ),
          ),
        ),
      );
}

class _LeafPainter extends CustomPainter {
  const _LeafPainter({required this.progress});

  final double progress;
  static const _forest = Color(0xFF2E7D32);
  static const _lime = Color(0xFF8CC63F);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 162, size.height / 140);
    canvas
      ..translate(
          (size.width - 162 * scale) / 2, (size.height - 140 * scale) / 2)
      ..scale(scale);

    final leftLeaf = Path()
      ..moveTo(80, 104)
      ..cubicTo(84, 68, 64, 42, 34, 37)
      ..quadraticBezierTo(27, 36, 28, 43)
      ..cubicTo(30, 76, 48, 104, 80, 104)
      ..close();
    final rightLeaf = Path()
      ..moveTo(82, 104)
      ..cubicTo(78, 68, 98, 42, 128, 37)
      ..quadraticBezierTo(135, 36, 134, 43)
      ..cubicTo(132, 76, 114, 104, 82, 104)
      ..close();

    _paintLeaf(canvas, leftLeaf, progress, .08, _forest);
    _paintLeaf(canvas, rightLeaf, progress, .22, _lime);
  }

  void _paintLeaf(
    Canvas canvas,
    Path path,
    double progress,
    double delaySeconds,
    Color color,
  ) {
    const totalSeconds = 1.27;
    const leafDurationSeconds = 1.05;
    final localProgress = ((progress - delaySeconds / totalSeconds) /
            (leafDurationSeconds / totalSeconds))
        .clamp(0.0, 1.0);
    final outlineProgress = (localProgress / .66).clamp(0.0, 1.0);
    _drawProgress(canvas, path, outlineProgress, color, width: 2.5);

    final fillProgress = ((localProgress - .66) / .34).clamp(0.0, 1.0);
    if (fillProgress > 0) {
      canvas.drawPath(
        path,
        Paint()..color = color.withValues(alpha: fillProgress),
      );
    }
  }

  void _drawProgress(
    Canvas canvas,
    Path path,
    double progress,
    Color color, {
    required double width,
  }) {
    if (progress <= 0) return;
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _LeafPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
