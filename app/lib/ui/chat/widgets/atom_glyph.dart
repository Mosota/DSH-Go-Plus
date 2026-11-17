import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 「思考中」的状态图形：原子核式结构。
///
/// [animated] 为 true 时，三条轨道上的电子匀速绕行（这是唯一的动效，
/// 网格/对勾等其它状态仍然是静止的一帧）。旋转是单个 AnimationController，
/// 只重绘这一块，不影响外层列表。
class AtomGlyph extends StatefulWidget {
  const AtomGlyph({
    super.key,
    required this.color,
    this.size = 18,
    this.strokeWidth = 1.1,
    this.animated = false,
    this.period = const Duration(milliseconds: 3600),
  });

  final Color color;
  final double size;
  final double strokeWidth;
  final bool animated;
  final Duration period;

  @override
  State<AtomGlyph> createState() => _AtomGlyphState();
}

class _AtomGlyphState extends State<AtomGlyph> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: widget.period);

  @override
  void initState() {
    super.initState();
    if (widget.animated) _spin.repeat();
  }

  @override
  void didUpdateWidget(AtomGlyph old) {
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
                    painter: _AtomPainter(
                      color: widget.color,
                      stroke: widget.strokeWidth,
                      phase: _spin.value * 2 * math.pi,
                    ),
                  ),
                )
              : CustomPaint(
                  painter: _AtomPainter(color: widget.color, stroke: widget.strokeWidth),
                ),
        ),
      );
}

class _AtomPainter extends CustomPainter {
  const _AtomPainter({required this.color, required this.stroke, this.phase});

  final Color color;
  final double stroke;

  /// null = 静止的一帧；否则是电子的相位（弧度）。
  final double? phase;

  static const _tilts = [0.0, 60.0, 120.0];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2 - stroke;
    final rx = r;
    final ry = r * 0.42;

    final orbit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.75);
    final electron = Paint()..color = color;

    // 整个原子一起自转（慢，约 7 秒一圈），电子再沿着各自轨道绕行：
    // 只有电子动看起来像"三个点"，整体转动才像原子。
    final spin = (phase ?? 0) * 0.5;
    for (var i = 0; i < _tilts.length; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(spin + _tilts[i] * math.pi / 180);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2), orbit);
      if (phase case final p?) {
        // 每颗电子错开 120°，匀速绕行；椭圆上按参数取点。
        final angle = p + i * (2 * math.pi / 3);
        canvas.drawCircle(
          Offset(math.cos(angle) * rx, math.sin(angle) * ry),
          math.max(1.0, size.shortestSide * 0.07),
          electron,
        );
      }
      canvas.restore();
    }

    // 核：实心圆 + 一圈淡边。
    canvas.drawCircle(center, size.shortestSide * 0.11, Paint()..color = color);
    canvas.drawCircle(
      center,
      size.shortestSide * 0.20,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 0.9
        ..color = color.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(_AtomPainter old) =>
      old.color != color || old.stroke != stroke || old.phase != phase;
}
