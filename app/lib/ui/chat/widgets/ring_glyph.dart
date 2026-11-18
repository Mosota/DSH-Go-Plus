import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 底部活动条的图形：一圈细环，外环带一段缺口，缓慢自转。
///
/// 和思考胶囊的星芒、回合行的原子核都不重样；缺口让它在静止时也像"在转"，
/// 动画只是让缺口慢慢移动，不做闪烁。
class RingGlyph extends StatefulWidget {
  const RingGlyph({
    super.key,
    required this.color,
    this.size = 18,
    this.animated = false,
    this.period = const Duration(milliseconds: 2400),
  });

  final Color color;
  final double size;
  final bool animated;
  final Duration period;

  @override
  State<RingGlyph> createState() => _RingGlyphState();
}

class _RingGlyphState extends State<RingGlyph> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: widget.period);

  @override
  void initState() {
    super.initState();
    if (widget.animated) _spin.repeat();
  }

  @override
  void didUpdateWidget(RingGlyph old) {
    super.didUpdateWidget(old);
    if (widget.animated && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!widget.animated && _spin.isAnimating) {
      _spin.stop();
      _spin.value = 0;
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: widget.animated
              ? AnimatedBuilder(
                  animation: _spin,
                  builder: (_, _) => CustomPaint(
                    painter: _RingPainter(color: widget.color, turns: _spin.value),
                  ),
                )
              : CustomPaint(painter: _RingPainter(color: widget.color)),
        ),
      );
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.color, this.turns});

  final Color color;
  final double? turns;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final stroke = math.max(1.2, size.shortestSide * 0.10);
    final outerR = size.shortestSide / 2 - stroke / 2;
    final innerR = outerR * 0.52;
    final t = turns ?? 0;

    void ring(double radius, double startTurns, double sweepFraction, double alpha, double width) {
      final rect = Rect.fromCircle(center: c, radius: radius);
      canvas.drawArc(
        rect,
        startTurns * 2 * math.pi - math.pi / 2,
        2 * math.pi * sweepFraction,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: alpha),
      );
    }

    // 同心双环，方向相反：外环顺时针、内环逆时针，各留一段缺口，转动才看得出来。
    ring(outerR, t, 0.78, 0.95, stroke);
    ring(innerR, -t * 1.35, 0.66, 0.55, stroke * 0.9);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.color != color || old.turns != turns;
}
