# Upstream Proposal: Dashboard Operational Visibility

## Summary

Add at-a-glance host vitals and project health to the Coolify dashboard.

## Problem

When operating multiple projects, two basic questions often require extra navigation or separate monitoring tools:

- Is the Coolify host currently under CPU, RAM, or load pressure?
- Which projects are running, starting, unhealthy, stopped, or empty?

The information already exists locally, but the main interface does not present it together as an operational overview.

## Tested Prototype

A working external prototype for Coolify 4.3.10 adds:

- live CPU usage and core count
- live RAM used / total / percentage
- 1-minute server load relative to CPU core count
- project health badges on Dashboard and Projects cards
- statuses derived from existing Coolify resource models
- a 5-second aggregate-status cache
- Livewire refresh without a new telemetry HTTP route

The external installer is intentionally defensive: source-anchor checks, timestamped backup, PHP and Blade validation, Coolify health checks, and automatic rollback.

## Evidence

The prototype was tested on one real installation with 22 projects.

For aggregate project-status calculation on that installation:

- median before short-lived cache: 315.76 ms
- median after cache prewarming: 4.10 ms

This is a measured case from one installation, not a universal benchmark.

## Upstream Question

The external container patch demonstrates the behavior, but it should not be treated as the preferred upstream architecture.

If this direction fits Coolify's product roadmap, the next step should be a native implementation aligned with the current codebase and split into focused changes for review.

The main product question is:

> Would live host vitals and project-level operational status be useful as native at-a-glance information in the Coolify dashboard?

## Public Implementation

https://github.com/AAA-It-uae/coolify-community-enhancements
