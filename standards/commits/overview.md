# Overview

The Commits standards: how work is committed.

- [A Turn's Records Land Together](a-turns-records-land-together.md) - the log entry, tickets, gos, moves, playtest notes and healing-log entries of a turn land in one commit before it ends, two around a landing
- [Commits](commits.md) - every commit is a lowercase conventional commit, and a ticket's commits take its id as the scope, feat(FEAT-123): description. NO AI attribution anywhere. Split by review interest
- [Gate Commits On Exit Codes](gate-commits-on-exit-codes.md) - only `&&` stands between the exit-code test and the commit or tag. Never pipe a check into grep or tail
- [Verify Staging Before Committing](verify-staging-before-committing.md) - read the staged list before every commit. Explicit paths when others share the tree
