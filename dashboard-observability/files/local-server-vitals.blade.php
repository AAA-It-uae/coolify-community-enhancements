<style>
    /* Progressive disclosure keeps the fixed top bar collision-free on narrower screens. */
    @media (max-width: 1999px) {
        .local-vitals-load { display: none !important; }
    }
    @media (max-width: 1649px) {
        .local-vitals-live { display: none !important; }
    }
    @media (max-width: 1499px) {
        .local-vitals-ram-total,
        .local-vitals-disk-total { display: none !important; }
    }
</style>

<div wire:poll.15s="refreshVitals"
    class="hidden xl:flex min-w-0 shrink-0 items-center gap-1.5 mr-2 whitespace-nowrap text-[10.5px] text-neutral-600 dark:text-fg-dim"
    title="Live server resources · red = used, green = free/available · refreshes every 15 seconds">

    <div class="local-vitals-live flex shrink-0 items-center gap-1.5 rounded-lg border px-2 py-1"
        style="border-color:rgba(16,185,129,.22);background:rgba(16,185,129,.055)">
        <span class="size-1.5 rounded-full" style="background:#10b981;box-shadow:0 0 7px rgba(16,185,129,.55)"></span>
        <span class="font-semibold tracking-wide" style="color:#047857">LIVE</span>
    </div>

    <div class="flex shrink-0 items-center gap-1.5 rounded-lg border px-2 py-1"
        style="border-color:rgba(59,130,246,.20);background:rgba(59,130,246,.045)"
        title="CPU: red is used capacity, green is free capacity across {{ $cores }} logical cores">
        <span class="font-semibold text-neutral-700 dark:text-fg">CPU</span>
        <span class="tabular-nums text-neutral-500 dark:text-fg-faint">{{ $cores }}C</span>
        <span class="text-neutral-300 dark:text-white/15">·</span>
        <span class="tabular-nums font-semibold" style="color:#dc2626">{{ number_format($cpuPercent, 1) }}%</span>
        <span class="text-neutral-300 dark:text-white/15">·</span>
        <span class="tabular-nums font-semibold" style="color:#059669">{{ number_format($cpuFreePercent, 1) }}%</span>
    </div>

    <div class="flex shrink-0 items-center gap-1.5 rounded-lg border px-2 py-1"
        style="border-color:rgba(168,85,247,.20);background:rgba(168,85,247,.045)"
        title="RAM: red is used memory, green is Linux MemAvailable, gray is total RAM">
        <span class="font-semibold text-neutral-700 dark:text-fg">RAM</span>
        <span class="tabular-nums font-semibold" style="color:#dc2626">{{ number_format($ramUsedGiB, 1) }}G ({{ number_format($ramPercent, 1) }}%)</span>
        <span class="text-neutral-300 dark:text-white/15">·</span>
        <span class="tabular-nums font-semibold" style="color:#059669">{{ number_format($ramFreeGiB, 1) }}G ({{ number_format($ramFreePercent, 1) }}%)</span>
        <span class="local-vitals-ram-total text-neutral-300 dark:text-white/15">·</span>
        <span class="local-vitals-ram-total tabular-nums text-neutral-500 dark:text-fg-faint">{{ number_format($ramTotalGiB, 1) }}G</span>
    </div>

    <div class="local-vitals-disk flex shrink-0 items-center gap-1.5 rounded-lg border px-2 py-1"
        style="border-color:rgba(245,158,11,.20);background:rgba(245,158,11,.045)"
        title="Disk /: red is used storage, green is free storage, gray is total capacity">
        <span class="font-semibold text-neutral-700 dark:text-fg">DISK</span>
        <span class="tabular-nums font-semibold" style="color:#dc2626">{{ number_format($diskUsedGiB, 1) }}G ({{ number_format($diskPercent, 1) }}%)</span>
        <span class="text-neutral-300 dark:text-white/15">·</span>
        <span class="tabular-nums font-semibold" style="color:#059669">{{ number_format($diskFreeGiB, 1) }}G ({{ number_format($diskFreePercent, 1) }}%)</span>
        <span class="local-vitals-disk-total text-neutral-300 dark:text-white/15">·</span>
        <span class="local-vitals-disk-total tabular-nums text-neutral-500 dark:text-fg-faint">{{ number_format($diskTotalGiB, 1) }}G</span>
    </div>

    <div class="local-vitals-load flex shrink-0 items-center gap-1.5 rounded-lg border px-2 py-1"
        style="border-color:rgba(20,184,166,.20);background:rgba(20,184,166,.045)"
        title="Linux server load average over 1, 5 and 15 minutes">
        <span class="font-semibold text-neutral-700 dark:text-fg">SERVER LOAD</span>
        <span class="tabular-nums">1m {{ number_format($load1, 2) }}</span>
        <span class="text-neutral-300 dark:text-white/15">·</span>
        <span class="tabular-nums">5m {{ number_format($load5, 2) }}</span>
        <span class="text-neutral-300 dark:text-white/15">·</span>
        <span class="tabular-nums">15m {{ number_format($load15, 2) }}</span>
    </div>
</div>
