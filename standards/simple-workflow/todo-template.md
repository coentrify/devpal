# Todo Template

`docs/development/todo.md` uses a fixed shape.

## Purpose

What the director decided to do soon, as concrete one-liners, follow-ups and cleanups from larger work among them ([The Simple Workflow](the-simple-workflow.md#the-lists)).

## Sections

- Title: `# Todo`.
- Flat dash list of one-liner items. No overview list - the file is already an overview.

## Item Shape

- Default: a single-line task. Reference a file or doc inline with backticks or a link when useful.
- No periods on bullet items.
- Strip items as soon as they're done. Git history preserves what was there.
- When an item needs more explanation, promote it to a `## <task title>` subheading with a short paragraph or list underneath. Don't bloat one-liners with parenthetical context - if it doesn't fit on one line, give it its own section ([No Faux Headers In Lists](../docs/no-faux-headers-in-lists.md)).

## What Doesn't Belong On The Todo

- User-facing bugs - [Bugs Template](bugs-template.md).
- Roadmap items - [Roadmap Template](roadmap-template.md).
- Debt with no concrete next step - the debt list ([Technical Debt Template](technical-debt-template.md)).

## Related

- [Workspace Template](../docs/workspace-template.md)
- [Documentation Philosophy](../docs/documentation-philosophy.md)
- [No Faux Headers In Lists](../docs/no-faux-headers-in-lists.md)
