# Gate Commits On Exit Codes

A commit, a tag or a "done" claim is gated on the exit code of the check itself, never on its printed output.

## Why

Only the exit code tells whether a check passed.

## How To Apply

- Only `&&` stands between the exit-code test and the commit or the tag: no `;`, no `echo "exit $?"`, no edit on the line before that can fail without stopping what follows.
- Never pipe a check into `grep`, `tail` or `head` before deciding on it, background runs included. Redirect to a file, save `$?`, then read the file. The shape that works: `npm run test:hygiene >check.log 2>&1; rc=$?; [ $rc -eq 0 ] && git commit ...` (never `status` as the variable, zsh holds it read only).
- A filtered check that prints nothing is not a pass. Read its exit code or its raw tail first.
- Re-read the last check's output before committing, even when it was green by construction.
- Where a rule keeps being broken by hand, the check moves into a hook or a script that refuses on its own, a project's commit hook running the hygiene suite on every commit, say (Parallel Agents lists the scripts).
- A pipe returns the exit code of its last command, so `build | grep ERROR && git commit` and `suite | tail -30` report green while the check failed. A `;` or an `echo $?` between test and commit runs the commit whatever happened. Each of these has landed broken work, even with this rule loaded.
- A hook refuses a `git commit` or `git tag` right after a `;`, or after a piped check anywhere before it. A newline between test and commit is not caught, so the same rule holds there.

## Related

- [Always Verify Before Reporting Done](../behavior/always-verify-before-reporting-done.md)
- [Verify Staging Before Committing](verify-staging-before-committing.md)
