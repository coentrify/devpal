# A Quiet Tree While A Suite Runs

Make no source edits while a browser suite runs against a watching dev server.

## Why

Tests should run in a stable environment.

## How To Apply

- While a suite runs, work on what the server does not watch: docs, standards, the plan, reading code.
- Start the next code edit after the result is in.
- A run that overlapped with edits is invalid. Rerun it before reading anything into it.
- With a conductor, a suite may run on a copy of the tree while the real one is edited. The copy is cleaned up after.

## Related

- [Always Verify Before Reporting Done](always-verify-before-reporting-done.md)
- [Gate Commits On Exit Codes](../commits/gate-commits-on-exit-codes.md)
