# Technical Debt Template

`docs/development/tech-debt.md` uses a fixed shape.

## Purpose

Catalogs internal debt: infrastructure friction, tooling gaps, missing abstractions. Things developers trip over but real users never see. Distinct from user-facing bugs and third-party feedback - see the split below.

## Why

An agent can pick up an entry and start the work from it.

## Bug / Debt / Feedback Split

- User-facing symptom -> [Bugs Template](bugs-template.md).
- Third-party library limitation (even with a workaround) -> [Library Feedback](../docs/library-feedback.md).
- Anything else internal to our code or infrastructure -> the debt list.

## Sections

- Title: `# Technical Debt`.
- Overview list: flat dash list, one bullet per item, formatted as ``- <description>`` or ``- <description> (`<severity>`)`` when severity applies. Always present. Sorted by severity, highest first (blockers at the top). Items without a severity sit below.
- Per item: `##` subheading with the title, then the body shape.

## Item Shape

- Subheading: `## <concise title>`.
- Optional severity line right after the title: `Severity: <level>`. Use sparingly: `Blocker` for items actively blocking other work. Other levels (`high`, `medium`, `low`) are optional and used when meaningful.
- Body: *just enough* to start the work. State what's broken and what success looks like. Brief - one short paragraph, often two sentences.
- Affected use cases or features can be mentioned briefly when they sharpen the impact. Don't enumerate exhaustively. Readers can follow the spec docs.

## What Doesn't Belong

- Code-level prescriptions (e.g. "introduce a single SCSS map with names X, Y, Z"). The code is written when the work begins, while a strategy at the entry's focus level may stand in a line.
- Detailed mechanism (which classes, which methods, which file). Same reason.
- Bug-style reproduction steps. If something reproduces with concrete user steps, it's a bug.

## Related

- [Bugs Template](bugs-template.md)
- [Library Feedback](../docs/library-feedback.md)
- [Workspace Template](../docs/workspace-template.md)
- [Documentation Philosophy](../docs/documentation-philosophy.md)
- [No Faux Headers In Lists](../docs/no-faux-headers-in-lists.md)
