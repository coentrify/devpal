# Non-Destructive Documenting And Test Automation

The observation steps of the [Feature Workflow](feature-workflow.md) - doc, spec and e2e - describe what exists and verify it, and never modify production code. Implementation changes happen in their own step, their own commit.

## Why

Production code changes only in implementation, where it is reviewed.

## How To Apply

- Diff during observation touches only `docs/`, `e2e/`, `mocks/`, test setup. Touching production source is a red flag.
- Mocks live outside the code under observation. The thing being mocked stays untouched.
- A test written failing first, for behavior not built yet, is expected to fail. One that fails on behavior that exists is a finding: file it as a bug ([Note Issues](note-issues.md)) and fix nothing in this step. The test lands with the fix as its reproducing test, never red on main.
- Each step commits separately. Never mix observation work and behavior change in one diff.

## Related

- [Feature Workflow](feature-workflow.md)
- [Note Issues](note-issues.md)
