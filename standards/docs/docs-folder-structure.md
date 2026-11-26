# Docs Folder Structure

A project's docs live at `docs/`, the main entry point and the wiki's root. Each folder has one job.

## Why

Every folder answers one question, so a reader knows where a fact belongs before looking.

## Root

- `overview.md` - what the product is, functional only. A game's overview opens with its Idea.
- `architecture.md` - how it is built: the decisions, layers, libraries and conventions.
- Nothing feature-specific or work-tracking sits at the root.

## Knowledge

- `docs/features/` - the feature docs: the product as decided ([Feature Template](feature-template.md)).
- `docs/<app>/` - in a workspace with several apps, each app's docs, shaped like the root: its overview, architecture and features ([Application Template](application-template.md)).
- `docs/workspace/` - the cross-cutting concern docs as flat files: `authentication.md`, `design-system.md`, `testing.md` and the like ([Workspace Template](workspace-template.md)).
- `docs/lore/` - in a game, the decided lore, the skeleton: the story, its key characters and how its parts connect.
- `docs/world/` - in a game, the decided world: its places, how they connect and how big it is.
- `docs/content/<kind>/` - in a game, the decided content, a folder per kind such as `characters/` and `questlines/`: an overview with the kind's fields and entries, and a file per entry.

## Ideas

`docs/ideas/` holds what is not decided yet.

- `dump.md` - the raw ideas, from the director's prompts and brainstorms.
- A page per category pulled from the dump, such as `characters.md` or `places.md`, to find an idea by.
- A part leaves once a decided doc under Knowledge holds it.

## Work

- `docs/development/` - all work tracking, whichever the workflow: the lists of the simple workflow ([The Simple Workflow](../simple-workflow/the-simple-workflow.md)), or the tickets, their generated lists and the archive, and the director's own tasks beside either ([Communication Boundary](../behavior/communication-boundary.md)).

## Records

All records sit together under `docs/records/`, one group in the wiki with an `overview.md` listing them. Each record folder is a dated trail, written as things happen. Its shape lives in its own standard.

- `docs/records/log/` - everything the director says, one file per day.
- `docs/records/activity/` - the work done, one file per day.
- `docs/records/playtests/` - one file per playtest of a game.
- `docs/records/user-tests/` - one file per session with real users.
- `docs/records/changelog/` - one page per version.
- Any other dated trail a project keeps joins them under `docs/records/`, never at the docs root.

## Images

- Only an image or a video a page shows is tracked. The rest go to an ignored `unused` folder beside it, on the local disk.
- A hygiene check fails a tracked image or video that no page links.

## Related

- [Docs Are Hierarchical, Explicit And Short](docs-are-hierarchical-explicit-and-short.md)
