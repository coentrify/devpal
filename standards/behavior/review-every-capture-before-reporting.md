# Review Every Capture Before Reporting

Look at each capture the pipeline produced before the report, and check it against the states list and the last feedback from testers. A capture that shows a regression is a finding.

## Why

A capture is proof, so it is checked before the director sees it.

## How To Apply

- After a capture run, read every new image and compare it with the previous set of the same state.
- Fix what regressed before committing, or file it and say so.
- Look at what a capture shows, not only whether it matches: seeded names, colors, icons and every new image get the question "what does this shape remind you of?" A doubtful default goes to the director as a question.
- Name in the review what the picture shows (which scenario, which record, which state) before it goes on a page, and check that it matches its caption and line. A conductor reviews an agent's capture the same way, never trusting its path name.
- A build warning at the close, such as a crossed size budget, counts as a finding of the capture pass: it is fixed or filed before the release, never carried as "clean".
- Keep the list of states the captures cover next to the captures.

## Related

- [Always Verify Before Reporting Done](always-verify-before-reporting-done.md)
