import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../phone/phone_channel.dart';
import '../../state/phone_state.dart';
import '../common/brief_notice.dart';
import '../common/list_page_row.dart';
import '../shell/page_frame.dart';
import '../theme/app_icons.dart';
import '../theme/theme.dart';
import 'phone_widgets.dart';

/// 后台屏的高级设置：保持通道、并行槽位、视口、使用前提。
///
/// 这些参数属于「特权通道 / 后台屏」，不属于虚拟屏的显示开关，所以放在特权通道页。
class PhoneAdvancedSettings extends ConsumerStatefulWidget {
  const PhoneAdvancedSettings({super.key});

  @override
  ConsumerState<PhoneAdvancedSettings> createState() => _PhoneAdvancedSettingsState();
}

class _PhoneAdvancedSettingsState extends ConsumerState<PhoneAdvancedSettings> {
  static const _groupMargin = EdgeInsets.fromLTRB(16, 12, 16, 12);

  bool _busy = false;

  Future<void> _run(Future<PhoneResult> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await action();
      if (!mounted) return;
      if (!result.ok) showBriefNotice(context, result.reason ?? context.l10n.phoneActionFailedLater);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _keepRow(PhonePrivilegedMode mode, PhonePrivilegedKeepStatus keep) {
    final l10n = context.l10n;
    final controller = ref.read(phoneProvider.notifier);
    void toggle(bool on) => unawaited(_run(() => controller.setBackgroundKeep(mode, on)));
    return MergeSemantics(
      child: ListPageRow(
        leading: const SizedBox(),
        title: l10n.phoneKeepTitle(mode.name),
        titleMaxLines: 2,
        subtitle: switch (mode) {
          PhonePrivilegedMode.root => l10n.phoneKeepRootDescription,
          PhonePrivilegedMode.adb => l10n.phoneKeepAdbDescription,
          _ => l10n.phoneKeepSharedDescription,
        },
        subtitleMaxLines: 8,
        onTap: _busy ? null : () => toggle(!keep.enabled),
        trailing: Switch(value: keep.enabled, onChanged: _busy ? null : toggle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = ref.watch(phoneProvider).status;
    final bg = status.background;
    final using = bg.effectiveMode;
    final controller = ref.read(phoneProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (using != PhonePrivilegedMode.off && bg.privileged != null)
          ListPageCard(margin: _groupMargin, children: [_keepRow(using, bg.keep)]),
        if (bg.parallelism case final capacity? when status.ready)
          ListPageCard(
            margin: _groupMargin,
            title: l10n.phoneBackgroundParallelTitle,
            children: [
              ListPageRow(
                title: l10n.phoneBackgroundParallelStatus(
                  capacity.configuredLimit,
                  capacity.effectiveLimit,
                  capacity.heldSlots,
                ),
                titleMaxLines: 4,
                subtitle: switch (capacity.reason) {
                  'off' => l10n.phoneBackgroundParallelOff,
                  'unsupported' => l10n.phoneBackgroundParallelUnsupported,
                  'connectionRequired' => l10n.phoneBackgroundParallelConnection,
                  'busy' => l10n.phoneBackgroundParallelBusy,
                  'transportSerial' => l10n.phoneBackgroundParallelSerial,
                  _ => l10n.phoneBackgroundParallelDescription,
                },
                subtitleMaxLines: 5,
              ),
              for (final limit in const [1, 2, 3])
                Semantics(
                  selected: capacity.configuredLimit == limit,
                  inMutuallyExclusiveGroup: true,
                  child: ListPageRow(
                    key: ValueKey('phone-background-limit-$limit'),
                    leading: Icon(capacity.configuredLimit == limit ? AppIcons.radioOn : AppIcons.radioOff),
                    title: l10n.phoneBackgroundParallelChoice(limit),
                    onTap: _busy || capacity.configuredLimit == limit
                        ? null
                        : () => unawaited(_run(() => controller.setBackgroundParallelLimit(limit))),
                  ),
                ),
            ],
          ),
        if (bg.viewport case final viewport? when bg.androidOk)
          ListPageCard(
            margin: _groupMargin,
            title: l10n.phoneViewportTitle,
            children: [
              ListPageRow(leading: const SizedBox(), title: l10n.phoneViewportDescription, titleMaxLines: 10),
              for (final preset in PhoneBackgroundViewport.values)
                Semantics(
                  selected: viewport == preset,
                  inMutuallyExclusiveGroup: true,
                  child: ListPageRow(
                    key: ValueKey('phone-viewport-${preset.name}'),
                    leading: Icon(viewport == preset ? AppIcons.radioOn : AppIcons.radioOff),
                    title: preset == PhoneBackgroundViewport.portrait
                        ? l10n.phoneViewportPortrait
                        : l10n.phoneViewportLandscape,
                    onTap: _busy || viewport == preset
                        ? null
                        : () => unawaited(_run(() => controller.setBackgroundViewport(preset))),
                  ),
                ),
            ],
          ),
        ListPageCard(
          margin: _groupMargin,
          title: l10n.phoneDndRequirements,
          children: [
            BulletLines([
              l10n.phoneDndKeepUnlocked,
              if (!bg.keep.enabled) l10n.phoneDndReactivate,
              if (using == PhonePrivilegedMode.off ||
                  using == PhonePrivilegedMode.shizuku ||
                  using == PhonePrivilegedMode.adb)
                l10n.phoneDndKeepDebugging,
            ]),
          ],
        ),
      ],
    );
  }
}
