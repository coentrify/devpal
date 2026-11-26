# Sync The Docs After Every Change

When something changed or a feature landed, check the docs for related information before calling it done: statements the change made stale, and statements about future plans the change now conflicts with.

## Why

The docs are up to date at all times.

## How To Apply

- After an item lands, grep the docs for its feature's terms (names, labels, the old behavior) and read every hit, beyond the feature's own doc.
- A statement the change made untrue gets fixed in the same commit or the next one.
- A future plan the change conflicts with (a roadmap line, a concept, a law) is filed as a question where the project's workflow says, and named in the report in one line. It is never silently rewritten.
- Prefer one source of truth: a summary doc links to the feature doc rather than repeating its status.

## Related

- [Propagate Renames And Convention Changes Everywhere](propagate-renames-and-convention-changes-everywhere.md)
- [Regular Layered Gap Analysis](regular-layered-gap-analysis.md)
- [Docs Hold Only What The Director Decided](docs-hold-only-what-the-director-decided.md)
