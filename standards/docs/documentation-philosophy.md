# Documentation Philosophy

Project docs describe what the product does, briefly and with one purpose per file, and hold enough to rebuild the product from them.

## Why

The docs orient every reader, and they are the basis for manual testing and for generating tests.

## What The Product Does

Docs describe what the product does and who uses it. The architecture doc holds the decisions about how it is built, and the details stay in the code ([Docs Describe Behavior, Not Wiring](docs-describe-behavior-not-wiring.md)).

## Brevity

A name of a feature, a view or an item is a short phrase ("Invite User", "Deactivate User"). A fact is a short sentence. Small lists of short items beat connecting sentences. The overview is a scannable product summary. Depth lives in the feature pages and their parts' pages, shaped and worded per [Docs Are Hierarchical, Explicit And Short](docs-are-hierarchical-explicit-and-short.md), which also owns naming things outright.

## One Purpose Per File

Each doc has a narrow job. Don't cram specifications into an overview. Don't cram technical debt into a feature list. If a fact doesn't fit the file's job, it lives in another file.

## No Meta About The Doc Inside The Doc

Don't open a doc with a paragraph explaining what the doc is for or how to read it ("Known bugs in the current build. Each entry links to..."). That kind of rule lives in the template or standard for the doc type. The doc itself jumps straight to content - readers know what `bugs.md` is from the filename and the H1.

## User-Facing Concepts

Even when the code reuses a single component for multiple flows, doc readers care about the user-facing concept. Split "Create User dialog" and "Edit User dialog" into two items. Don't collapse them because the code does.

## Plain Punctuation

ASCII over typographic polish, per [Normal Dashes](../behavior/normal-dashes.md).

## Readable Headings

Title case for document titles (`# Admin`). Sections use short functional names (`## Users`, `## Features`, `## Views`), not compound labels like `## Pages / views` or `## Flows / use-cases`.

## Consistent Structure Across Apps

When a structure is agreed for one app's doc, the same structure applies to every app. No per-app prose variations.

## Simple Markdown

Standard syntax. Prefer flat dash lists. Avoid numbered lists. Hierarchy comes from headings and from a page per part: a point with parts gets a subsection of its own. Nested bullets are allowed but strongly discouraged. E.g.:

```
## List
- Item 1
- Item 2
```


## The Product As It Is Now

A product doc states what the product is now, one fact per bullet, grouped under headings, without dates, provenance or change history ([Docs State Knowledge](docs-state-knowledge.md)).

## Reproducible From The Docs

The rule of thumb for a project's docs as a whole: another agent, handed the docs without the codebase, rebuilds the product in its essence, small changes and interpretations expected. A fact the product depends on that lives only in the code or the chat is a gap. A cleanup moves information to its right place and never drops anything valuable.

## Related

- [Docs Describe Behavior, Not Wiring](docs-describe-behavior-not-wiring.md)
