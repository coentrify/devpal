# Decisions

The reasoning behind how this project uses coentrify.

## Adopted

- Behavior, Docs and Security - the Always modules.
- AI - the companion builds on models: speech recognition, a voice and Claude Code.
- Simple Workflow - the project starts small, with flat lists in `docs/development/`.
- Commits - Commits, Gate Commits On Exit Codes, Verify Staging Before Committing and A Turn's Records Land Together. The rest assumes tickets.
- Scripts - the project runs on npm scripts.
- Tooling - the VitePress wiki only.
- Records - the healing log. The request log is left out, since the repository is public and would hold every word the director says. The changelog joins once devpal ships versions.

## Choices

- Healing and updates are automatic. Filing with coentrify waits for the director's review.
- A VitePress wiki serves the docs and the standards on port 5274, beside addix on 5273.
- The entry point is `AGENTS.md`. `CLAUDE.md` imports it, the index and the Core Rules.
- Sessions work on main.
- The stack modules, such as TypeScript or a Swift module of the project's own, join once the stack is chosen.
- Personas made on a machine stay out of git, since one can carry a real person's voice.
