package io.github.ccch1mneyyy.dsh_app.runtime

/**
 * 省电策略（重置版）。
 *
 * 设计参照 DSHA 的 `PowerPolicy`：**只决定要不要占住 CPU，从不暂停/结束引擎进程**。
 * 之前那版省电模式会冻结引擎，结果连任务都起不来——这里从根上不做那种事。
 *
 * 规则：
 * - 省电关闭 → 一直持锁（保持现状）；
 * - 省电开启 → 只有在「真的有事」时才持锁：引擎启动中 / 屏幕亮着 / 有任务在跑 /
 *   刚结束不到 [IDLE_GRACE_MS]（给收尾留缓冲）；
 * - 其余时间放锁，交给系统 Doze；引擎进程照常存在，只是不阻止休眠。
 */
object PowerPolicy {
    /** 空闲多久之后才真正放锁：任务刚结束还会收尾、写盘、发通知。 */
    const val IDLE_GRACE_MS = 60_000L

    /** 纯函数，便于单测：返回这次是否应该占住 CPU。 */
    fun keepCpu(
        eco: Boolean,
        starting: Boolean,
        interactive: Boolean,
        busy: Boolean,
        idleSince: Long,
        now: Long,
    ): Boolean {
        if (!eco) return true
        if (starting || interactive || busy) return true
        if (idleSince <= 0L || now < idleSince) return true
        return now - idleSince < IDLE_GRACE_MS
    }

    /**
     * 维护 idleSince 的状态机：任一「有事」信号出现就清零，全部为假的第一次调用记下时间。
     * 返回更新后的 idleSince（0 表示当前不处于空闲）。
     */
    fun nextIdleSince(
        current: Long,
        starting: Boolean,
        interactive: Boolean,
        busy: Boolean,
        now: Long,
    ): Long {
        if (starting || interactive || busy) return 0L
        if (current <= 0L || now < current) return now
        return current
    }
}
