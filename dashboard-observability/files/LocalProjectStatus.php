<?php

namespace App\Support;

use App\Models\Project;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Cache;

final class LocalProjectStatus
{
    private const RELATIONS = [
        'applications',
        'services.applications',
        'services.databases',
        'postgresqls',
        'redis',
        'keydbs',
        'dragonflies',
        'clickhouses',
        'mongodbs',
        'mysqls',
        'mariadbs',
    ];

    public static function forProjects(Collection $projects): array
    {
        if ($projects->isEmpty()) {
            return [];
        }

        $cacheKey = 'local-project-status:v2:'.md5($projects->pluck('id')->sort()->values()->implode(','));
        $cached = Cache::get($cacheKey);
        if (is_array($cached)) {
            return $cached;
        }

        $loaded = Project::query()
            ->whereIn('id', $projects->pluck('id'))
            ->with(self::RELATIONS)
            ->get();

        $result = $loaded->mapWithKeys(function (Project $project): array {
            return [$project->uuid => self::forLoadedProject($project)];
        })->all();

        Cache::put($cacheKey, $result, 5);

        return $result;
    }

    private static function forLoadedProject(Project $project): array
    {
        $statuses = collect();

        foreach (['applications', 'postgresqls', 'redis', 'keydbs', 'dragonflies', 'clickhouses', 'mongodbs', 'mysqls', 'mariadbs'] as $relation) {
            foreach ($project->{$relation} as $resource) {
                self::pushStatus($statuses, data_get($resource, 'status'));
            }
        }

        foreach ($project->services as $service) {
            self::pushStatus($statuses, $service->status);
        }

        if ($statuses->isEmpty()) {
            return ['label' => 'Empty', 'type' => 'neutral'];
        }

        if ($statuses->contains(function (string $status): bool {
            return str_starts_with($status, 'degraded')
                || (str_starts_with($status, 'running') && str_contains($status, 'unhealthy'));
        })) {
            return ['label' => 'Unhealthy', 'type' => 'error'];
        }

        if ($statuses->contains(function (string $status): bool {
            return str_starts_with($status, 'starting')
                || str_starts_with($status, 'restarting')
                || str_starts_with($status, 'queued');
        })) {
            return ['label' => 'Starting', 'type' => 'warning'];
        }

        if ($statuses->contains(fn (string $status): bool => str_starts_with($status, 'running'))) {
            return ['label' => 'Running', 'type' => 'success'];
        }

        return ['label' => 'Stopped', 'type' => 'neutral'];
    }

    private static function pushStatus(Collection $statuses, mixed $value): void
    {
        $status = strtolower(trim((string) $value));
        if ($status !== '') {
            $statuses->push($status);
        }
    }
}
