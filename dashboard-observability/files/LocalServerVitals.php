<?php

namespace App\Livewire;

use Illuminate\Contracts\View\View;
use Livewire\Component;

class LocalServerVitals extends Component
{
    public int $cores = 0;
    public float $cpuPercent = 0;
    public float $cpuFreePercent = 100;
    public float $ramUsedGiB = 0;
    public float $ramFreeGiB = 0;
    public float $ramTotalGiB = 0;
    public float $ramPercent = 0;
    public float $ramFreePercent = 0;
    public float $diskUsedGiB = 0;
    public float $diskFreeGiB = 0;
    public float $diskTotalGiB = 0;
    public float $diskPercent = 0;
    public float $diskFreePercent = 0;
    public float $load1 = 0;
    public float $load5 = 0;
    public float $load15 = 0;
    public ?int $previousTotalTicks = null;
    public ?int $previousIdleTicks = null;

    public function mount(): void
    {
        $this->readVitals(false);
    }

    public function refreshVitals(): void
    {
        $this->readVitals(true);
    }

    private function readVitals(bool $calculateCpu): void
    {
        [$totalTicks, $idleTicks] = $this->cpuTicks();

        if ($calculateCpu && $this->previousTotalTicks !== null && $totalTicks > $this->previousTotalTicks) {
            $deltaTotal = $totalTicks - $this->previousTotalTicks;
            $deltaIdle = $idleTicks - (int) $this->previousIdleTicks;
            $busy = max(0, $deltaTotal - $deltaIdle);
            $this->cpuPercent = round(min(100, ($busy / $deltaTotal) * 100), 1);
        }
        $this->cpuFreePercent = round(max(0, 100 - $this->cpuPercent), 1);

        $this->previousTotalTicks = $totalTicks;
        $this->previousIdleTicks = $idleTicks;

        $cpuInfo = @file_get_contents('/proc/cpuinfo') ?: '';
        preg_match_all('/^processor\s*:/m', $cpuInfo, $matches);
        $this->cores = max(1, count($matches[0] ?? []));

        $memInfo = @file_get_contents('/proc/meminfo') ?: '';
        preg_match('/^MemTotal:\s+(\d+)\s+kB/m', $memInfo, $totalMatch);
        preg_match('/^MemAvailable:\s+(\d+)\s+kB/m', $memInfo, $availableMatch);
        $totalKb = (int) ($totalMatch[1] ?? 0);
        $availableKb = min($totalKb, max(0, (int) ($availableMatch[1] ?? 0)));
        $usedKb = max(0, $totalKb - $availableKb);

        $this->ramTotalGiB = round($totalKb / 1048576, 1);
        $this->ramUsedGiB = round($usedKb / 1048576, 1);
        $this->ramFreeGiB = round($availableKb / 1048576, 1);
        $this->ramPercent = $totalKb > 0 ? round(($usedKb / $totalKb) * 100, 1) : 0;
        $this->ramFreePercent = $totalKb > 0 ? round(($availableKb / $totalKb) * 100, 1) : 0;

        $diskTotalBytes = (float) (@disk_total_space('/') ?: 0);
        $diskFreeBytes = (float) (@disk_free_space('/') ?: 0);
        $diskFreeBytes = min($diskTotalBytes, max(0, $diskFreeBytes));
        $diskUsedBytes = max(0, $diskTotalBytes - $diskFreeBytes);

        $this->diskTotalGiB = round($diskTotalBytes / 1073741824, 1);
        $this->diskUsedGiB = round($diskUsedBytes / 1073741824, 1);
        $this->diskFreeGiB = round($diskFreeBytes / 1073741824, 1);
        $this->diskPercent = $diskTotalBytes > 0 ? round(($diskUsedBytes / $diskTotalBytes) * 100, 1) : 0;
        $this->diskFreePercent = $diskTotalBytes > 0 ? round(($diskFreeBytes / $diskTotalBytes) * 100, 1) : 0;

        $load = sys_getloadavg() ?: [0.0, 0.0, 0.0];
        $this->load1 = round((float) ($load[0] ?? 0), 2);
        $this->load5 = round((float) ($load[1] ?? 0), 2);
        $this->load15 = round((float) ($load[2] ?? 0), 2);
    }

    private function cpuTicks(): array
    {
        $lines = @file('/proc/stat', FILE_IGNORE_NEW_LINES) ?: [];
        $firstLine = $lines[0] ?? '';
        $parts = preg_split('/\s+/', trim($firstLine)) ?: [];
        if (($parts[0] ?? '') === 'cpu') {
            array_shift($parts);
        }

        $ticks = array_map('intval', array_slice($parts, 0, 8));
        $ticks = array_pad($ticks, 8, 0);

        return [array_sum($ticks), $ticks[3] + $ticks[4]];
    }

    public function render(): View
    {
        return view('livewire.local-server-vitals');
    }
}
