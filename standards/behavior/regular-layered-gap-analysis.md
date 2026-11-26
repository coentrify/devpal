# Regular Layered Gap Analysis

The workspace is layered in more than one dimension, and the layers drift apart unless checked. Periodically walk them, step by step, looking for inconsistencies.

## Why

The layers stay in step, and drift is caught while it is cheap.

## How To Apply

- Walk each dimension in both directions and file the gaps as issues.
- Documentation depth: workspace -> app -> feature. Confirm each level describes the same reality.
- Build pipeline: functional doc -> spec -> e2e test -> implementation. Confirm each step lines up with the ones before and after it - every feature specced, every spec case tested, every test reflecting real behavior, nothing shipped undocumented.
- Rules against the system: the standards and conventions versus the actual codebase. Re-check that the code still meets them, and that a newly added or strengthened rule has been swept across everything that predates it.

## Related

- [Feature Workflow](feature-workflow.md)
- [Note Issues](note-issues.md)
- [Code Review Compounds Into Patterns And Sweeps](code-review-compounds-into-patterns-and-sweeps.md)
