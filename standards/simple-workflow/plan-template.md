# Plan Template

`docs/development/plan.md` is the workspace plan: a thin parent. The detailed, in-flight items live in the per-app plans (`docs/development/<app>/plan.md`). The workspace plan stays short and points down to them. In a project with one app, `docs/development/plan.md` is the plan itself.

## Purpose

The short-horizon working doc: what's in flight right now, what's queued for immediately after. Distinct from the roadmap (longer-horizon goals) and the inbox (the unsorted dead drop).

## Workspace Plan (Parent)

- Title: `# Plan`.
- Active focus statement: a one-liner right under the title naming the current focus across the workspace.
- A flat dash list of pointers to the per-app plans that hold the detail - not the detailed items themselves.
- Keep it short. It should rarely need editing as app-level work churns.

## App Plan (`docs/development/<app>/plan.md`)

- Same shape, scoped to the app: title + active-focus one-liner, then the overview list right under the title.
- The immediate items live here, in the overview list ([Overview List](#overview-list)). Promote an item to a `##` subsection only when it needs explanation ([No Faux Headers In Lists](../docs/no-faux-headers-in-lists.md)). The subsection is titled the same as its overview entry.

## Overview List

- Open the plan, right under its title, with a flat list of every item it tracks, a table of contents that makes the whole plan scannable before any detail.
- Label the one item in flight `(active)`, at most one active at a time.
- A done item leaves the plan ([Remove Completed Items From Docs](remove-completed-items-from-docs.md)).

## Describe A Shift

- When the focus pivots away from previously-planned work (pausing an in-flight cleanup for a client-priority feature, say), name the shift in the active-focus one-liner: what it moved from, its new state (paused), and why.
- The next session should see why the active item isn't what the plan used to be about, without digging through git history.

## What Belongs

- Items in flight right now or about to be picked up next (in the app plan).
- The one-line current direction (in both, scoped accordingly).

## What Doesn't Belong

- Long-horizon goals - those live in [Roadmap Template](roadmap-template.md).
- Small unsorted follow-ups - the workspace inbox (the free-form dead drop).
- Status snapshots ("E2E harness: complete..."). They go stale fast and belong in commit history or release notes.
- Speculation about future work, restart notes, decision logs.
- Detailed immediate items in the workspace plan - those belong in the app plan.

## Related

- [Workspace Template](../docs/workspace-template.md)
- [Application Template](../docs/application-template.md)
- [Roadmap Template](roadmap-template.md)
- [Documentation Philosophy](../docs/documentation-philosophy.md)
