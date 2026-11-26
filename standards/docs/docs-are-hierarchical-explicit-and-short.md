# Docs Are Hierarchical, Explicit And Short

Knowledge pages are organized as a hierarchy and written for a human to read: a page per thing, its items under headings, every thing named outright, and one short sentence per list item.

## Why

A hierarchy gives every page the right focus level, for efficient and effective communication.

## A Page

- The page opens with a summary at its own focus level, one or two lines right under the title: what the thing is and what it is for, no details and no visual description, which rot when the look changes.
- An introduction, when the page needs one, is distinct from the summary: it is the first item of the contents, where the content begins.
- Then a contents section one focus level deeper, under a heading that fits the thing: `## Parts`, `## Features`. The items are grouped by what they do (`### Account Settings`, `### Billing`), one line each with a dash and a few words ("The Profile - Name And Photo").
- Then a `##` heading per item, in the same order. An item with one or a few things to say gets one line under its heading and a link to its own page. An item with more gets a page of its own, its features under headings. Sub-items take `###`.
- The look of the thing goes under an `## <Thing> Aesthetics` heading, in prose.
- A section with subsections opens with a short list of them as in-page links before its own text.
- A page holds only what relates to its own thing and its state. A fact that is always true, or that belongs to another thing, lives on that thing's page.
- An overview nests its stages by their grouping, never one flat list across groups.
- A summary or a description of a linked page stays at the focus level of the page it stands on, without details or specs.
- A line in a list relates its item to its siblings and its parent only, so it shows how the items differ in function and where they relate.
- The focus level of an overview is how it all ties together.

## Folders

- A thing whose items have pages of their own is a folder: its `overview.md` is the thing's own page and every item's page sits beside it, never a page standing outside the folder of its name. A simple thing stays a single file.
- The same holds one level up: a group's index page is its folder's `overview.md`.
- The wiki's sidebar follows the folders ([VitePress Wiki](../tooling/vitepress-wiki.md)).

## Writing

- Name things outright: the settings page, never "the page the gear icon opens".
- An abbreviation the project coins is spelled out where a page first uses it, headings included, the short form in brackets after: Single Source Of Truth (SSOT). Common ones, UI or CPU, need no spelling out.
- One short sentence per list item. Several facts become several items or a short paragraph under a heading, never a long list of long items.
- Good organization beats both lists and prose: structure first, then short lists, prose only for descriptive matter such as the look.
- A one-line statement under a heading is a spec that leads to a test.
- Plans, logs and changelogs keep their own shapes.

## How To Apply

- Legacy pages get rewritten page by page, with one model page reviewed by the director first.

## Related

- [Documentation Philosophy](documentation-philosophy.md)
- [Docs Describe Behavior, Not Wiring](docs-describe-behavior-not-wiring.md)
- [Feature Template](feature-template.md)
- [Docs State Knowledge](docs-state-knowledge.md)
- [VitePress Wiki](../tooling/vitepress-wiki.md)
