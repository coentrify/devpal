# Application Template

A workspace contains one or more applications. Each application has its own docs under `docs/<app>/`. Anything cross-app belongs in workspace docs at `docs/`.

## Why

Every application's docs have the same structure, and keep the focus of the application.

## overview.md

Entry point for the application - a reader should grasp the application's size and what it does at a glance. Basis for feature-specific docs that go deeper. Functional only, no implementation detail.

- Title: `# <Name>` (optionally with alias in parentheses).
- Subtitle: one sentence stating the application's purpose.
- Sections: Users, Features, Views, Functional Debt, Notes.

### Sections

- `Users` - functional user roles (e.g. "Administrator"). A flat list, then a `###` subheader with a short description per role.
- `Features` - brief noun phrases in Title Case (e.g. "User Overview", "Create User"). A flat list, then a `###` subheader with a short description per feature (same shape as `Users`).
- `Views` - user-facing pages and dialogs (e.g. "User List", "Create User (dialog)").
- `Functional Debt` - what an existing feature lacks (e.g. "Sort Users").
- `Notes` - caveats and product quirks (e.g. "Role is set on Create. It cannot be changed on Edit.").

### Status Markers

- A whole feature or view not built yet stands under Features or Views with a `(Not Yet Implemented)` suffix, linking its ticket, or its roadmap item in the simple workflow.
- The mark stands only on the feature itself, where it is described. A page that merely refers to it carries no mark, since marks spread over references rot once the feature lands.
- Each `Functional Debt` item links to the roadmap item that resolves it.

### Features Ordering

- Overview/landing view first.
- Group by entity (e.g. all User features together).
- Core features first, secondary later.

### Features Naming

Lookup/info features use a noun: `<Entity> <Noun>` (e.g. "User Overview"). Action features use a verb: `<Verb> <Entity>` (e.g. "Create User").

Standard nouns:

- `Overview` - landing view.
- `Table` - tabular listing.
- `Pagination` - paginated listing.
- `Summary` - condensed entity info (e.g. inline row).
- `Detail` - full entity info (page or drawer).

Standard verbs:

- `Filter` - narrow a set by criteria.
- `Sort` - order a set by columns or values.
- `Search` - targeted lookup by query.
- `Create` - new entity.
- `Edit` - mutate existing entity.
- `Delete` - remove entity.

Pluralization:

- Nouns: singular (entity type, not instance) - "User Overview", "User Detail".
- Verbs: plural for set-level operations ("Filter Users", "Sort Users").
- Verbs: singular for single-entity actions ("Create User", "Edit User", "Delete User", "Search User").

### Views Naming

Dialog labels follow Features Naming - most are user actions and use the verb pattern (e.g. "Create User (dialog)"). Confirmation dialogs prefix with "Confirm" (e.g. "Confirm Delete User (dialog)").

Common kinds: view, dialog, drawer, card.

Split logically distinct views even if they share code (e.g. Create and Edit User dialogs).

## architecture.md

- Technical companion to the app's overview.md - how this app is built, linking out to the workspace docs for shared concerns.
- Holds per-app technical detail while apps diverge.

## Work

- An application's work is tracked in the workspace's `docs/development/`.
- An epic can group the work of one application.

## Related

- [Documentation Philosophy](documentation-philosophy.md)
- [Things Of One Kind Are Consistent](../behavior/things-of-one-kind-are-consistent.md)
- [Docs Folder Structure](docs-folder-structure.md)
- [Workspace Template](workspace-template.md)
