# Thin Wrappers In CI And Hooks

Git hooks and CI workflow steps are thin dispatchers: each is a one-line `npm run <name>` call and nothing else. The real sequence of commands lives in `package.json`.

## Why

Every behavior is found in `package.json`, and runs the same from CI, a hook or by hand.

## How To Apply

- Git hooks call `hooks:<name>` and CI calls `ci:<name>`, a dedicated script per context ([npm Script Naming](npm-script-naming.md)).
- Git hook (husky example): `.husky/<name>` holds a single `npm run hooks:<name>` line and nothing else. `hooks:<name>` in `package.json` calls a task (e.g. `"hooks:pre-commit": "npm run lint"`).
- CI step example:

  ```yaml
  - run: npm run ci:lint
  ```

  `ci:<name>` calls a task as well (e.g. `"ci:lint": "npm run lint:affected"`, where `"lint:affected": "nx affected --target=lint --base=origin/main"`).
- Editing an existing hook or CI step: move any inline commands into a matching npm script first.
- Wrap even a one-line command, for consistency.

## Related

- [npm Script Naming](npm-script-naming.md)
