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
    final stroke = math.max(1.2, size.shortestSide * 0.11);

    // 内环：完整、偏淡，给出"环"的形体。
    canvas.drawCircle(
      c,
      size.shortestSide * 0.24,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 0.8
        ..color = color.withValues(alpha: 0.35),
    );

    // 外环：2/3 圈，缺口跟着动画走。
    final rect = Rect.fromCircle(center: c, radius: size.shortestSide / 2 - stroke / 2);
    final start = (turns ?? 0) * 2 * math.pi - math.pi / 2;
    canvas.drawArc(
      rect,
      start,
      2 * math.pi * 0.68,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.color != color || old.turns != turns;
}
