# Propagate Renames And Convention Changes Everywhere

When you rename a concept, file, route or label, update every reference in the same change: sibling docs, links, specs, labels. Never fix one and wait to be told to "align the others". A changed doc or code convention updates every page that states it in the same change, and its existing occurrences go to a sweep, filed as debt ([Sweeps Enumerate Into Tech-Debt First](sweeps-enumerate-into-tech-debt-first.md)).

## Why

A name or a convention reads the same in every place.

## How To Apply

Enumerate first: grep the old term to list every site. Where the meaning changes too, grep the old wording as well, since a paraphrase names a concept without its name. Sweep them all. Re-grep afterward to confirm none remain.

## Related

- [Review Changes Before Reporting Done](review-changes-before-reporting-done.md)
- [Always Work From A Plan](always-work-from-a-plan.md)
