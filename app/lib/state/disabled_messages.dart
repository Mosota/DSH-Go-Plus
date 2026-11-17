import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
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

/// 引擎读的那份清单：`<rootfs>/root/.dsh/disabled.json`。
/// 开关一次就立刻落盘，不用等下次启动引擎。
Future<void> _syncToGuest(SharedPreferences prefs) async {
  try {
    final map = <String, List<int>>{};
    for (final entry in prefs.getKeys()) {
      if (!entry.startsWith('disabled:')) continue;
      final raw = prefs.getString(entry) ?? '';
      final seqs = [
        for (final part in raw.split(','))
          if (int.tryParse(part.trim()) case final seq?) seq,
      ];
      if (seqs.isEmpty) continue;
      map[entry.substring('disabled:'.length)] = seqs;
    }
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/runtime/rootfs/root/.dsh/disabled.json');
    if (!file.parent.existsSync()) file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(map));
  } catch (_) {
    // 写不进去只影响"禁用暂时不生效"，不影响对话。
  }
}

/// 开关一次并刷新该会话的 provider。
Future<void> toggleDisabledMessage(WidgetRef ref, String sessionId, int seq) async {
  final prefs = await SharedPreferences.getInstance();
  await DisabledMessages(prefs).toggle(sessionId, seq);
  await _syncToGuest(prefs);
  ref.invalidate(disabledMessagesProvider(sessionId));
}
