# Code Review Compounds Into Patterns And Sweeps

A code-review finding is rarely a one-off. When something surfaces in review, check whether it is a pattern - it usually is - and turn the single catch into a durable defense across the codebase.

## Why

A pattern captured once protects the whole codebase and every later session.

## How To Apply

- On any finding, look for sibling instances before treating it as isolated.
- When it is a pattern:
  - It goes to healing, the way `healing` says: a review check so future reviews catch it, or a standard on how to do it properly ([Always Make No Mistakes](always-make-no-mistakes.md)). When unsure of the correct approach, the director is asked before it is codified.
  - File a sweep for the existing instances as debt, enumerated per [Sweeps Enumerate Into Tech-Debt First](sweeps-enumerate-into-tech-debt-first.md).
- Run code-review sweeps on occasion, not only when asked, to keep the codebase healthy.
- When an issue recurs that already has a rule, the rule was too weak: strengthen it ([Always Make No Mistakes](always-make-no-mistakes.md)).

## Related

- [Regular Layered Gap Analysis](regular-layered-gap-analysis.md)
- [Note Issues](note-issues.md)
