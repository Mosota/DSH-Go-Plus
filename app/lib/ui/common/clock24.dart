/// 24 小时制的时间文本（本 App 统一用它，避免跟随系统语言变成 AM/PM）。
///
/// - [withSeconds] true 时输出 `HH:mm:ss`
/// - 跨天判断由调用方决定（消息时间戳自己加 `MM-DD`）
String clock24(DateTime time, {bool withSeconds = false}) {
  final t = time.toLocal();
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  if (!withSeconds) return '$h:$m';
  return '$h:$m:${t.second.toString().padLeft(2, '0')}';
}
