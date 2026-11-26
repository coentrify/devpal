# No npx In Scripts

In `package.json` scripts, husky hooks, and CI workflows, never prefix commands with `npx`. The binary is already a project dependency, so it should be resolved via npm's PATH (an npm script finds it automatically) or via an explicit `npm run <wrapper>` call - never `npx nx ...`, `npx playwright ...`.

## Why

A script runs what the lock file declares, online or offline.

## How To Apply

- `npx` exists for the case where a tool is not installed locally: it falls back to fetching from the network. In a script it hides that a dependency should be declared, masks a mismatch between `package-lock.json` and what runs, and quietly does the wrong thing in an offline or locked-down CI.

## Exceptions

- One-off interactive commands at the terminal can still use `npx`. This rule is about checked-in scripts.

## Related

- [npm Script Naming](npm-script-naming.md)
- [Thin Wrappers In CI And Hooks](thin-wrappers-in-ci-and-hooks.md)
