# Docs Describe Behavior, Not Wiring

A doc describes its thing at the focus level of its page: what it does, and how it is built as a whole ([Docs Are Hierarchical, Explicit And Short](docs-are-hierarchical-explicit-and-short.md)). A detail that only the code keeps true lives in the code.

## Why

A doc stays true while the code changes.

## How To Apply

- The overview, a feature doc and a spec describe what something does for the user, and the states it goes through.
- The paths a user takes, as flows and use cases, live in the spec.
- The architecture doc holds the decisions and describes the whole: the layers and the folders that carry them, such as `ui`, the libraries chosen and why, and the conventions.
- A concern doc does the same for one concern, such as authentication or testing.
- File paths, the names of classes, services and components, and the wiring between them stay in the code, since they change with it.
- A debt ticket or debt entry holds the technical detail its work needs.
- Concrete endpoints and environment URLs live only in a concern doc of their own under `docs/workspace/`, such as `api.md` and `environments.md`. Credentials live in no doc.
- When a doc reads like a copy of the code, cut to the throughline: keep the essence, and drop the specifics.

## Related

- [Documentation Philosophy](documentation-philosophy.md)
- [Docs Are Hierarchical, Explicit And Short](docs-are-hierarchical-explicit-and-short.md)
- [Workspace Template](workspace-template.md)
