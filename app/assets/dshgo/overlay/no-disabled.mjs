// 「禁用这条消息」的读时过滤器。
//
// 由 App 通过 NODE_OPTIONS=--import 加载；从 /root/.dsh/disabled.json 读
// { "<sessionId>": [seq, seq, ...] }。命中就跳过那条消息——不改会话存储，
// 只是不把它送进模型上下文。文件不存在/解析失败时完全放行（绝不阻断对话）。
import fs from 'node:fs';

const FILE = '/root/.dsh/disabled.json';

function load() {
  try {
    const raw = fs.readFileSync(FILE, 'utf8');
    const map = JSON.parse(raw);
    if (!map || typeof map !== 'object') return null;
    return map;
  } catch {
    return null;
  }
}

globalThis.__dshDisableFilter = function (agentOrSession, messages) {
  try {
    const map = load();
    if (!map) return messages;
    const id = agentOrSession?.session?.id ?? agentOrSession?.sessionId ?? agentOrSession?.id;
    const disabled = id ? map[id] : undefined;
    if (!Array.isArray(disabled) || disabled.length === 0) return messages;
    const drop = new Set(disabled);
    const kept = [];
    for (const item of messages ?? []) {
      const seq = item?.seq ?? item?.event?.seq;
      if (seq !== undefined && drop.has(seq)) continue;
      kept.push(item);
    }
    return kept;
  } catch {
    return messages;
  }
};
