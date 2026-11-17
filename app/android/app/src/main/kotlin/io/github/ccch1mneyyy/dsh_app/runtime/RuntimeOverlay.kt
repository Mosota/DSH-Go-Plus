package io.github.ccch1mneyyy.dsh_app.runtime

import android.content.Context
import android.util.Log
import java.io.File

/**
 * ⚠️ 运行时文件覆盖（见维护手册 §13）。
 *
 * 规则（别省任何一条）：
 * - 只覆盖**具体一个文件**，内容来自 APK 资源里我们维护的副本；
 * - 首次覆盖前把原文件备份成 `*.dsh-orig`，写失败立刻还原；
 * - 内容相同就跳过（幂等），不打补丁的版本不受影响；
 * - 目标不存在就**跳过**，绝不创建（说明运行时结构变了，宁可不修也不改坏）；
 * - 每次结果都写一行日志，便于事后判断是"生效"还是"跳过"。
 */
object RuntimeOverlay {
    private const val TAG = "DshOverlay"

    /**
     * @param asset APK 内的资源路径（如 `dshgo/direct/dns.mjs`）
     * @param relative 相对 rootfs 的目标路径（如 `opt/dsh-go/direct/dns.mjs`）
     * @return true 表示这次真的写了；false 表示跳过（已是最新/目标不存在/失败已还原）
     */
    fun apply(context: Context, rootfs: File, asset: String, relative: String, log: (String) -> Unit): Boolean {
        val target = File(rootfs, relative)
        if (!target.isFile) {
            log("[dsh-app] overlay skipped: $relative not in this runtime")
            return false
        }
        val bytes = runCatching { context.assets.open(asset).readBytes() }.getOrNull() ?: run {
            log("[dsh-app] overlay skipped: asset $asset unreadable")
            return false
        }
        val current = runCatching { target.readBytes() }.getOrNull()
        if (current != null && current.contentEquals(bytes)) return false

        val backup = File(target.parentFile, target.name + ".dsh-orig")
        if (!backup.isFile) {
            runCatching { target.copyTo(backup, overwrite = false) }
                .onFailure { Log.w(TAG, "backup failed for $relative", it) }
        }
        val ok = runCatching { target.writeBytes(bytes) }.isSuccess
        if (!ok) {
            // 写坏了就还原，绝不让引擎加载半截文件。
            runCatching { if (backup.isFile) backup.copyTo(target, overwrite = true) }
            log("[dsh-app] overlay FAILED, restored: $relative")
            return false
        }
        log("[dsh-app] overlay applied: $relative")
        return true
    }

    /**
     * 锚点式补丁（手册 §13 铁律 1）：只在原文里出现锚点时替换一次，找不到就跳过。
     * 绝不写入半截文件：写失败会还原备份。
     *
     * @param marker 补丁标记；文件里已有它说明打过，直接跳过（幂等）
     */
    fun patch(
        rootfs: File,
        relative: String,
        anchor: String,
        replacement: String,
        marker: String,
        log: (String) -> Unit,
    ): Boolean {
        val target = File(rootfs, relative)
        if (!target.isFile) {
            log("[dsh-app] patch skipped: $relative not in this runtime")
            return false
        }
        val text = runCatching { target.readText() }.getOrNull() ?: run {
            log("[dsh-app] patch skipped: $relative unreadable")
            return false
        }
        if (text.contains(marker)) return false
        if (!text.contains(anchor)) {
            // 上游结构变了：宁可这个功能退回原样，也不能改坏引擎。
            log("[dsh-app] patch skipped: anchor not found in $relative")
            return false
        }
        val patched = text.replaceFirst(anchor, replacement)
        val backup = File(target.parentFile, target.name + ".dsh-orig")
        if (!backup.isFile) runCatching { target.copyTo(backup, overwrite = false) }
        val ok = runCatching { target.writeText(patched) }.isSuccess
        if (!ok) {
            runCatching { if (backup.isFile) backup.copyTo(target, overwrite = true) }
            log("[dsh-app] patch FAILED, restored: $relative")
            return false
        }
        log("[dsh-app] patch applied: $relative")
        return true
    }
}
