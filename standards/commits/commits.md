# Commits

A commit message names the change at a glance, with a ticket's id where there is one and no attribution. A commit holds one unit a reviewer wants to see.

## Why

The history reads and searches by what each commit holds.

## Message

Name what changed, specifically, so the subject tells the change at a glance without opening the diff.

- Every commit uses Conventional Commits: `type(scope): description`, its types `feat`, `fix`, `chore`, `docs`, `refactor`, `revert`.
- In the tickets workflow, a commit made for a ticket takes the ticket's id as its scope: `feat(FEAT-123): the upload retries after a dropped connection`.
- Every other scope is freeform, such as an area or a kind of change: `feat(upload)`, `chore(deps)`, `docs(log)`.
- The description starts with a lowercase letter. A project's commitlint enforces the form.
- Commitlint also enforces `body-max-line-length` 100. Each `-m` of `git commit -m` becomes one unwrapped body line, so split a long body across several `-m` flags. The commit-msg hook rejects the whole commit otherwise, after lint-staged has already run.

## Ticket Scope

In a project on the tickets workflow:

- Every commit made for a ticket carries its id: its code, its tests, the wiki's tooling, its Done part and its archive move.
- A story's merge commit takes the story's id as its scope: `feat(STORY-1): users sign up and sign in`. A ticket outside a story merges under its own id.
- The commit message hook refuses a commit of code or tests without a ticket's or a story's id as its scope, built from the Ticket Id Check spec in the tools.
- The main session's commits that serve no single ticket, such as a Request Log entry, take a freeform scope.
- A ticket's commits are found by its id, `git log --grep FEAT-123`, never listed in the ticket.

## No Attribution

Commit messages contain only the message itself. No `Co-Authored-By` trailers, no "Generated with Claude Code", no AI attribution of any kind. The same holds for PR descriptions. Where the agent adds attribution by itself, its setting switches it off, such as `"attribution": { "commit": "", "pr": "" }` in Claude Code's `.claude/settings.json`.

A cloud session's harness can ask for attribution lines on its own, apart from that setting. The project's rule wins over it. A commit-msg hook holds the rule where the setting does not reach: it refuses a line that opens with attribution, built from the Attribution Check spec in the tools.

## Size

Make smaller commits, grouped by review interest. Mechanical changes can batch. Complex changes get their own commit so a reviewer can find and verify them.

For migrations or refactors, batch the mechanical updates, then split out each complex case. Ask: "what would a reviewer want to look at separately?"

A branch only ever holds commits ready to land. A commit is never amended once pushed, and a fix goes in as a new commit. An unpushed wrong commit is redone ([Verify Staging Before Committing](verify-staging-before-committing.md)).

## Related

- [Verify Staging Before Committing](verify-staging-before-committing.md)
- [A Name Describes Its Unit](../behavior/a-name-describes-its-unit.md)
