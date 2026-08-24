<div wire:poll.5s="refreshVitals"
    class="hidden xl:flex shrink-0 items-center gap-1.5 mr-2 text-[10.5px] text-neutral-600 dark:text-fg-dim"
    title="Live server resources · refreshes every 5 seconds">
    @php
        $loadCapacityPercent = $cores > 0 ? round(($load1 / $cores) * 100, 1) : 0;
        $loadBarPercent = min(100, max(2, $loadCapacityPercent));
    @endphp

    <div class="flex items-center gap-1.5 rounded-lg border px-2 py-1"
        style="border-color:rgba(16,185,129,.22);background:rgba(16,185,129,.055)">
        <span class="size-1.5 rounded-full" style="background:#10b981;box-shadow:0 0 7px rgba(16,185,129,.55)"></span>
        <span class="font-semibold tracking-wide" style="color:#047857">LIVE</span>
    </div>

    <div class="flex items-center gap-2 rounded-lg border px-2 py-1"
        style="min-width:145px;border-color:rgba(59,130,246,.20);background:rgba(59,130,246,.045)">
        <span class="font-semibold text-neutral-700 dark:text-fg">CPU</span>
        <span class="tabular-nums">{{ $cores }}C · {{ number_format($cpuPercent, 1) }}%</span>
        <span class="h-1 w-10 overflow-hidden rounded-full" style="background:rgba(59,130,246,.15)">
            <span class="block h-full rounded-full transition-all duration-500"
                style="background:#3b82f6;width:{{ max(2, min(100, $cpuPercent)) }}%"></span>
        </span>
    </div>

    <div class="flex items-center gap-2 rounded-lg border px-2 py-1"
        style="min-width:192px;border-color:rgba(168,85,247,.20);background:rgba(168,85,247,.045)">
        <span class="font-semibold text-neutral-700 dark:text-fg">RAM</span>
        <span class="tabular-nums">{{ number_format($ramUsedGiB, 1) }} / {{ number_format($ramTotalGiB, 1) }}G · {{ number_format($ramPercent, 1) }}%</span>
        <span class="h-1 w-10 overflow-hidden rounded-full" style="background:rgba(168,85,247,.15)">
            <span class="block h-full rounded-full transition-all duration-500"
                style="background:#a855f7;width:{{ max(2, min(100, $ramPercent)) }}%"></span>
        </span>
    </div>

    <div class="flex items-center gap-2 rounded-lg border px-2 py-1"
        style="min-width:185px;border-color:rgba(20,184,166,.20);background:rgba(20,184,166,.045)"
        title="1-minute server load average relative to {{ $cores }} CPU cores">
        <span class="font-semibold text-neutral-700 dark:text-fg">SERVER LOAD</span>
        <span class="tabular-nums">{{ number_format($load1, 2) }} / {{ $cores }}C · {{ number_format($loadCapacityPercent, 1) }}%</span>
        <span class="h-1 w-10 overflow-hidden rounded-full" style="background:rgba(20,184,166,.15)">
            <span class="block h-full rounded-full transition-all duration-500"
                style="background:#14b8a6;width:{{ $loadBarPercent }}%"></span>
        </span>
    </div>
</div>
