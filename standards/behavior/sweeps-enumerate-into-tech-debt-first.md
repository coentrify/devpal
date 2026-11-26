# Sweeps Enumerate Into Tech-Debt First

A sweep for a pattern begins by finding every instance and listing them in one debt entry, before any fix. Where the entry goes is the project's workflow's: [The Simple Workflow](../simple-workflow/the-simple-workflow.md#where-a-finding-goes) or Work Workflow.

## Why

A sweep fixes every instance, with none missed.

## How To Apply

- First pass: scan thoroughly for every instance - watch for casing, singular/plural, and shape variants that a narrow grep misses - and list each in the debt entry.
- Then work the list, removing items as they are fixed, per [Remove Completed Items From Docs](../simple-workflow/remove-completed-items-from-docs.md).
- State the scope honestly: if the scan can miss instances, say so rather than imply full coverage.

## Related

- [Note Issues](note-issues.md)
- [Always Work From A Plan](always-work-from-a-plan.md)
- [Code Review Compounds Into Patterns And Sweeps](code-review-compounds-into-patterns-and-sweeps.md)
