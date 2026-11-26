# Healing Log

Every change that automatic healing makes to the harness gets one entry in `docs/records/healing-log.md`. An entry stays until the director has ruled on it.

## Why

The harness heals on its own, and the director keeps the last word on every change.

## How To Apply

- An entry is one line: the date, what went wrong, what changed, and the commit. The change is committed first, and its entry follows with the turn's records, naming the change's commit ([A Turn's Records Land Together](../commits/a-turns-records-land-together.md)). `- 2026-11-19 - a commit followed a git add in one command - Verify Staging Before Committing gets a check in the commit gate - 85f1950`
- The entry goes in through the project's append script, so every entry has the same shape and the log can be counted.
- One entry holds one change. A mistake that changed a rule and a check gets two entries.
- The director rules on an entry: keep it, change it, or revert it.
- A ruled entry leaves the log, and git keeps it ([Remove Completed Items From Docs](../simple-workflow/remove-completed-items-from-docs.md)).
- A change that holds beyond the project is filed with coentrify as [File A Change With Coentrify](../behavior/file-a-change-with-coentrify.md) says, without waiting for the ruling when `filing` is automatic.
- The log is read as a whole now and then. A trigger that comes back points at a rule that is still too weak.
- Healing on `review` files the change in the workflow, and writes no entry.

## Related

- [Always Make No Mistakes](../behavior/always-make-no-mistakes.md)
