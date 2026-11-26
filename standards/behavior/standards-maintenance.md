# Standards Maintenance

Sweep the standards periodically to keep them tight and lean.

## Why

Standards rot if left alone.

## Recurring Sweep

A sweep analyzes the standards, documents what it finds, and files it as work to pick up, in a batch or as tickets ([Sweeps Enumerate Into Tech-Debt First](sweeps-enumerate-into-tech-debt-first.md)). It looks for:

- Bloat - sections that yap when one sentence would do.
- Stale rules - standards that contradict current practice or reference removed concepts. Update or delete.
- Duplication - two standards saying the same thing. Pick the most correct home, defer from the other.
- Drift - the line in the overview no longer matches the standard's gist. Rewrite the line.
- Format violations - em dashes, numbered lists, non-Title-Case headers, hard-wrapped lines.
- Dead cross-links - links to files that have been renamed or deleted.

## Format

- A header is in Title Case, every word capitalized, apart from code and a name that is lowercase by nature, such as `npm`.
- A paragraph or a list item is one line.
- No semicolon in prose: two thoughts are two sentences, or two bullets.
- No filler word, such as `genuinely` or `truly`, and no British spelling.
- A standard opens with its rule, its Why is its first section, and it ends with Related.

## Budget

Soft caps: past a cap, a standard is trimmed or split before anything is added to it.

- The count is the body: the Related list stays out of it.
- A standard: about 600 words.
- A template: about 1,200 words.
- A hub, such as a workflow: about 3,000 words.
- A page accepted past its budget is listed in its module's `budget-exceptions.json`, with the words accepted and the reason. It surfaces again once it grows past them.

## Adding A Standard

- Check first whether another standard owns the rule. A rule with a home is added there.
- A rule lives on one page. Every other page that needs it links there, and never says it again.
- A new standard goes in the module it belongs to. A subject without a module gets a module of its own.
- The file is named after its title ([File Names](../docs/file-names.md)).
- The standard follows the template: the rule in one or two sentences, a Why, how to apply it, and its related standards.
- A Why says why the rule is needed, in a line or two.
- The overview of the module gets one line for the standard.

## When To Sweep

- A standard that feels wrong, or does not apply, is noted and goes through healing ([Always Make No Mistakes](always-make-no-mistakes.md)). The task at hand goes on.
- After a standard changes, by healing or by an update, a sweep of what it touches follows.
- When the standards feel heavy.

## How To Apply

- Apply format fixes freely.
- A rule change goes the way `healing` says, and the report names it ([Always Make No Mistakes](always-make-no-mistakes.md)).
- A standard from coentrify that a project changes turns `customized` in `coentrify.json`, with the reason in `standards/decisions.md`.
- A contributor files a changed or added standard with coentrify, if relevant ([File A Change With Coentrify](file-a-change-with-coentrify.md)).

## Related

- [Note Issues](note-issues.md)
- [File A Change With Coentrify](file-a-change-with-coentrify.md)
- [File Names](../docs/file-names.md)
