# Devpal

A talking companion that lives on a dev machine's screen, on coentrify. The docs are in `docs`, the standards in `standards`.

- Read the index, `standards/overview.md`, and follow its Core Rules in every task. Read them again after a compaction. The commands are in `node_modules/coentrify/src/commands.md`.
- A coentrify command, or a prompt that means one, ends with the greeting from Greet in `node_modules/coentrify/src/onboarding.md`, once, at the top of its closing reply, the banner written out in full.
- The work is tracked in the simple workflow: `docs/development/plan.md` first, then the roadmap, the todo and the inbox.
- A session starts with `npm run check:coentrify`. A session without `node_modules` runs `npm install` first.
- Work happens on main: a session commits to main and pushes it.
- Personas made on a machine stay local and untracked, in `personas/` beside the plain one. Never commit, publish or share one.
