# Always Verify Before Reporting Done

The verification step always applies. The mechanism varies by what was changed.

## Why

Done means it works, and only the matching check shows that.

## How To Apply

- Pick the verification surface that matches the change: browser preview for UI, e2e run for spec edits, type check for type changes, unit run for logic, lint for style-rule fixes, build for tooling.
- Run it before declaring done. "I read the diff" never substitutes for "I ran the check" when a check exists.
- If no automated check exists for the change, name what is being skipped and why, so the director can decide whether to verify manually.
- Never frame the absence of a browser preview as a reason to skip verification.

## Related

- [Review Changes Before Reporting Done](review-changes-before-reporting-done.md)
