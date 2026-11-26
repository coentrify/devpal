# Backward-Trace Missing Prerequisites

When the next step in the [Feature Workflow](feature-workflow.md) needs infrastructure that doesn't exist - no e2e harness, no spec template, no mock for the area, no tests for the affected area - file the prerequisite above the current item, and build it on its go.

## Why

A gap is closed once, for every feature after it.

## How To Apply

- File the prerequisite as work of its own, ahead of the current item, where the project's workflow says: [The Simple Workflow](../simple-workflow/the-simple-workflow.md#where-a-finding-goes) or Work Workflow.
- Recurse when the prerequisite has a missing prerequisite of its own.
- Resume only after the prerequisite is committed and verified.
- Never fold prerequisite work into the current feature's diff. Never write a throw-away bypass to get past the gap.

## Related

- [Feature Workflow](feature-workflow.md)
- [The Simple Workflow](../simple-workflow/the-simple-workflow.md)
