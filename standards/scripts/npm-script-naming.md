# npm Script Naming

A script is named by who runs it: a task as `<verb>:<app>:<thing>`, and an automation context's script as `<context>:<thing>`.

## Why

A script's name says what it runs and for which context.

## Tasks (Run By Humans Or Shared)

Format: `<verb>:<app>:<thing>`. App always comes second, never `<verb>:<thing>:<app>`. Omit `<app>` in single-app projects. Omit `<thing>` when not needed.

### Verbs

A verb names the kind of run, such as these:

- `start:` - long-running processes (dev server, report viewer).
- `test:`, `lint:`, `build:`, `e2e:`, `install:` - one-shot runs.

### Examples

- `start:admin` - run the admin dev server.
- `e2e:admin:report` - run the full e2e suite with HTML report and videos.

## Contexts (Run By Automation)

Format: `<context>:<thing>`. Each automation context gets its own entry scripts, distinct from the human-run tasks above. The `hooks:` and `ci:` prefixes are examples of the general pattern: one prefix per context.

An entry script calls a task, such as `"hooks:pre-commit": "npm run lint"`, so a context and a human run one command that cannot drift. When a context needs a command of its own, that command is a task as well, such as `lint:ci`, and the entry script calls it.

- `hooks:pre-commit`, `hooks:pre-push` - called by git hooks.
- `ci:lint`, `ci:test` - called by CI workflow steps.

## Wrappers

For tools that ship as installable binaries (Playwright, MSW, etc.), add a thin wrapper script in `package.json`: `"install:playwright": "playwright install --with-deps chromium"`. Call it via `npm run install:playwright` rather than invoking the binary directly.

Don't expose internal env vars or build flags (`DEMO=1`, `CI=true`) in script names. Keep them inside the script.

## Related

- [Thin Wrappers In CI And Hooks](thin-wrappers-in-ci-and-hooks.md)
- [No npx In Scripts](no-npx-in-scripts.md)
