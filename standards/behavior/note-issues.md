# Note Issues

When you encounter a problem during other work (bug, code smell, lint suppression, deprecated pattern, missing test, broken doc), write it down where the project's workflow says - never silently absorb it - without letting it block the work in front of you.

## Why

Every finding is kept, so all debt stays visible.

## Where To Note

The project's workflow names the home of each kind of finding: [The Simple Workflow](../simple-workflow/the-simple-workflow.md#where-a-finding-goes) or Work Workflow.

- Friction with a library -> surfaced to the director in the report ([Library Feedback](../docs/library-feedback.md)).

## How To Apply

- Stop briefly, add a short entry to the right doc, return to current work. One line is enough most of the time, with supporting context only when necessary.
- Never just suppress (eslint-disable, ts-ignore, swallowed error) without a matching note.
- Filing means writing it to a doc. Mentioning it in chat, or asking "want me to file this?", is not filing: the mention scrolls away. If you flag it at all, write it down the same turn.
- When unsure whether it's worth tracking or where it belongs, file it as debt, or as a question when it is functional, rather than drop it.

## Related

- [The Simple Workflow](../simple-workflow/the-simple-workflow.md)
- [Library Feedback](../docs/library-feedback.md)
