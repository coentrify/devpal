# Roadmap Template

`docs/development/roadmap.md` uses a fixed shape.

## Purpose

Answers "what's next?" at a glance. Active surfaces the current focus. Priorities show what comes after. Blocked vs Waiting For Response splits "we'll unblock ourselves" from "we need someone else". Nice To Have holds what is wanted, for when there is time.

## Sections

- Title: `# Roadmap`.
- `## Active` - the current focus. Usually one item.
- `## Priorities` - upcoming work, top-down execution order. Top is what we do next once Active completes.
- `## Blocked` - paused on internal prerequisites (another roadmap item, an e2e harness, a tooling gap). We can unblock ourselves.
- `## Waiting For Response` - paused on external dependencies (third parties, partners, vendors). We can't unblock ourselves.
- `## Nice To Have` - decided and wanted, done only when there is time.

## Item Shape

- An item is named as Work Item Names says, in Title Case: `Create An Account`, `Fix Auth Session Redirect`.
- Flat dash list within each section.
- One-liner items. No parenthetical bloat, no trailing periods.
- Blocked / Waiting items: include the blocker inline, e.g. ``X - blocked by Y`` or ``X - waiting for Z``.
- Reference the feature doc when an item maps to one, e.g. ``[Mobile Responsive](features/responsive.md) - blocked on ...``.

## What Doesn't Belong On The Roadmap

- Specific bugs - they live in [Bugs Template](bugs-template.md).
- Debt entries - they live in the debt list ([Technical Debt Template](technical-debt-template.md)).
- "Resolve bugs" or "Fix tech debt" as roadmap items - those are continuous activities, not roadmap goals.
- Generic "Write unit tests" or "Add tests" - if testing is a priority, name it as an initiative (e.g. `Automated Testing`). Specific test backlogs live in the affected feature's spec.

## The Lists Beside It

The inbox, the todo and the plan stand beside the roadmap, each with its own job ([The Simple Workflow](the-simple-workflow.md#the-lists)). Before asking the director whether an unbuilt item is still wanted, check which of them holds it.

## Related

- [Workspace Template](../docs/workspace-template.md)
- [Documentation Philosophy](../docs/documentation-philosophy.md)
- [Bugs Template](bugs-template.md)
