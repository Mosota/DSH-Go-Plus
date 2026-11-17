import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Claude 风格的小星芒：八条圆头射线，中心留空。
///
/// [animated] 时整体极慢地转（一圈 9 秒），转动幅度很轻，只用来表示"在想"，
/// 不会像点阵那样闪。
class SparkGlyph extends StatefulWidget {
  const SparkGlyph({
    super.key,
    required this.color,
    this.size = 18,
    this.animated = false,
    this.period = const Duration(milliseconds: 9000),
  });

  final Color color;
  final double size;
  final bool animated;
  final Duration period;

  @override
  State<SparkGlyph> createState() => _SparkGlyphState();
}

class _SparkGlyphState extends State<SparkGlyph> with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(vsync: this, duration: widget.period);

  @override
  void initState() {
    super.initState();
    if (widget.animated) _turn.repeat();
  }

  @override
  void didUpdateWidget(SparkGlyph old) {
    super.didUpdateWidget(old);
    if (widget.animated && !_turn.isAnimating) {
      _turn.repeat();
    } else if (!widget.animated && _turn.isAnimating) {
      _turn.stop();
      _turn.value = 0;
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: widget.animated
              ? AnimatedBuilder(
                  animation: _turn,
                  builder: (_, _) => CustomPaint(
                    painter: _SparkPainter(color: widget.color, turns: _turn.value),
                  ),
                )
              : CustomPaint(painter: _SparkPainter(color: widget.color)),
        ),
      );
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter({required this.color, this.turns});

  final Color color;

  /// null = 静止；否则是 0–1 的转角（一圈 360°/8 对称，实际只转 1/8 就够）。
  final double? turns;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    final inner = outer * 0.30;
    final stroke = math.max(1.1, size.shortestSide * 0.10);

    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    // 八条射线：长短交替，长短形成星芒层次（Claude 的那颗星就是这个节奏）。
    final spin = (turns ?? 0) * (2 * math.pi / 8);
    for (var i = 0; i < 8; i++) {
      final angle = spin + i * (2 * math.pi / 8);
      final long = i.isEven;
      final from = Offset(c.dx + math.cos(angle) * inner, c.dy + math.sin(angle) * inner);
      final to = Offset(
        c.dx + math.cos(angle) * (long ? outer : outer * 0.72),
        c.dy + math.sin(angle) * (long ? outer : outer * 0.72),
      );
      canvas.drawLine(from, to, paint);
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.color != color || old.turns != turns;
}
