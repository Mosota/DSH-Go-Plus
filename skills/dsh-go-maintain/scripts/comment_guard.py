#!/usr/bin/env python3
"""注释吞代码检查（手册 §13 那类事故的专用哨兵）。

历史事故：一份文件的 KDoc 写了 `/** 标题` 却漏掉 `*/`，紧接着又是一个 `/**`，
于是后面的 `fun`/`class` 全被吞进注释，编译器只报"找不到符号"，
看起来像调用方写错了。

判据刻意收窄：**一个 `/**` 在遇到 `*/` 之前又遇到下一个 `/**`** → 必是漏闭合。
这样不会误报字符串里出现的 `/*`。

用法：python3 comment_guard.py <目录…>
退出码 1 = 发现问题。
"""
import sys
from pathlib import Path


def problems(text: str):
    idx = 0
    while True:
        open_at = text.find('/**', idx)
        if open_at < 0:
            return
        close_at = text.find('*/', open_at + 3)
        next_open = text.find('/**', open_at + 3)
        if next_open >= 0 and (close_at < 0 or next_open < close_at):
            line = text[:open_at].count('\n') + 1
            yield f'第 {line} 行的 KDoc 没闭合（下面又出现了一个 KDoc）'
            idx = next_open
            continue
        if close_at < 0:
            line = text[:open_at].count('\n') + 1
            yield f'第 {line} 行的 KDoc 直到文件末尾都没有闭合'
            return
        idx = close_at + 2


def main() -> int:
    roots = [Path(a) for a in (sys.argv[1:] or ['.'])]
    bad = 0
    for root in roots:
        root = root.resolve()
        for p in root.rglob('*'):
            if p.suffix not in {'.kt', '.dart'} or 'build/' in p.parts or '.dart_tool' in p.parts:
                continue
            for msg in problems(p.read_text(encoding='utf-8', errors='ignore')):
                print(f'{p}: {msg}')
                bad += 1
    print('OK' if not bad else f'{bad} problem(s)')
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
