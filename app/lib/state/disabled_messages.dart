import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 「禁用这条消息」：被禁用的消息不进入模型上下文（引擎侧的读时过滤器负责剔除），
/// 界面上只把它变灰，不动会话存储。
///
/// 存储：SharedPreferences 里 key = sessionId，value = 逗号分隔的 seq。
/// App 启动引擎时会把这些值写成 `/root/.dsh/disabled.json` 供引擎读取。
class DisabledMessages {
  const DisabledMessages(this._prefs);

  final SharedPreferences _prefs;

  static String _key(String sessionId) => 'disabled:$sessionId';

  Set<int> of(String sessionId) {
    final raw = _prefs.getString(_key(sessionId));
    if (raw == null || raw.isEmpty) return const {};
    return {
      for (final part in raw.split(','))
        if (int.tryParse(part.trim()) case final seq?) seq,
    };
  }

  Future<Set<int>> toggle(String sessionId, int seq) async {
    final next = {...of(sessionId)};
    if (!next.remove(seq)) next.add(seq);
    await _prefs.setString(_key(sessionId), (next.toList()..sort()).join(','));
    return next;
  }
}

/// 当前会话被禁用的消息（revision 变更时重建列表）。
final disabledMessagesProvider =
    FutureProvider.family<Set<int>, String>((ref, sessionId) async {
  final prefs = await SharedPreferences.getInstance();
  return DisabledMessages(prefs).of(sessionId);
});

/// 开关一次并刷新该会话的 provider。
Future<void> toggleDisabledMessage(Ref ref, String sessionId, int seq) async {
  final prefs = await SharedPreferences.getInstance();
  await DisabledMessages(prefs).toggle(sessionId, seq);
  ref.invalidate(disabledMessagesProvider(sessionId));
}
