# Plans Vs Persistent Files

A plan shrinks to empty, a persistent file is never completed, and the two never mix.

## Why

Each file stays current, so a reader can trust it.

## Plans

Hold what's being done right now: status, ordered tasks, blockers, scope-of-effort. Items get deleted as they're done. The file shrinks toward empty. Examples: `docs/development/plan.md`, the inbox, a plan file outside a project.

## Persistent

Hold knowledge, conventions, functionality, and reference. They evolve but never get "completed". Single responsibility per file: one purpose, one shape. Examples: standards, skills, architecture docs.

## How To Apply

When writing, ask: is this *how* something works (or should), or *what* we're doing right now?

- *How* -> persistent (standard, skill, doc).
- *What* -> plan.

When reviewing a plan, extract any "always X" / "never Y" text to a persistent home and replace with a one-line pointer. Keep the items' status, such as the active one and its blockers, and their order in the plan. When reviewing a persistent file, strip any time-bound status into the relevant plan.

## Related

- [Always Work From A Plan](../behavior/always-work-from-a-plan.md)
- [Plan Template](plan-template.md)
- [Remove Completed Items From Docs](remove-completed-items-from-docs.md)
- [Documentation Philosophy](../docs/documentation-philosophy.md)
