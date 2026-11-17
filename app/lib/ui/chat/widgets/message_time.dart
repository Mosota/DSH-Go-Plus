import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// 每条消息下面的时间戳：同一天只显示 `HH:mm`，跨天带上 `MM-DD`。
class MessageTime extends StatelessWidget {
  const MessageTime({super.key, required this.time, this.align = TextAlign.right});

  final DateTime time;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final local = time.toLocal();
    final sameDay = now.year == local.year && now.month == local.month && now.day == local.day;
    final clock = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    final text = sameDay ? clock : '${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $clock';
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
      child: Text(
        text,
        textAlign: align,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DshColors.of(context).textTertiary),
      ),
    );
  }
}
