import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 「思考中」的状态图形：原子核式结构（静止，不动画）。
///
/// 中间一个核，外面三条椭圆轨道交叉成经典原子符号的样子。线条按 [size]
/// 等比缩放，所以 14–22 之间都清晰；描边不依赖主题，只用传入的颜色。
class AtomGlyph extends StatelessWidget {
  const AtomGlyph({super.key, required this.color, this.size = 18, this.strokeWidth = 1.1});

  final Color color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _AtomPainter(color: color, stroke: strokeWidth),
        ),
      );
}

class _AtomPainter extends CustomPainter {
  const _AtomPainter({required this.color, required this.stroke});

  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    // 轨道半径留出描边余量，避免被裁掉。
    final r = size.shortestSide / 2 - stroke;
    final rect = Rect.fromCircle(center: center, radius: r);

    final orbit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.75);

    // 三条轨道：0° / 60° / 120°，宽度压扁成椭圆。
    for (final angle in const [0.0, 60.0, 120.0]) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle * math.pi / 180);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rect.width, height: rect.height * 0.42),
        orbit,
      );
      canvas.restore();
    }

    // 核：实心圆 + 一圈淡边，和轨道区分开。
    final nucleus = Paint()..color = color;
    canvas.drawCircle(center, size.shortestSide * 0.11, nucleus);
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
  bool shouldRepaint(_AtomPainter old) => old.color != color || old.stroke != stroke;
}
