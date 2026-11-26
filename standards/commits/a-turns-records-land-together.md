# A Turn's Records Land Together

The records a turn produces are committed together, once, before the turn ends: the log entry, with the tickets, gos, assignments, moves, playtest notes and healing-log entries that came from it.

## Why

A commit per record buries the work in bookkeeping. One commit per turn keeps every record, and the history shows the work.

## How To Apply

- The records take a scope of their own, such as `docs(records)`. A commit that holds the log alone keeps `docs(log)` ([Verify Staging Before Committing](verify-staging-before-committing.md)).
- A record is never left uncommitted waiting for a go.
- A turn that lands a branch commits its records before the landing, since a merge wants a clean tree, and what follows from the landing in one commit after it: two commits at most.
- The work itself keeps its own commits, grouped by review interest ([Commits](commits.md#size)).
- In a tickets project the conductor commits the records. A builder or a healer hands its words to the conductor in its report.

## Related

- [Commits](commits.md)
- [Healing Log](../records/healing-log.md)
