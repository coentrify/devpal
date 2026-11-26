# The Simple Workflow

The work is tracked in a few flat lists, and the director asks one question: what's next?

## Why

Everything has a place to go, with light organization that stays simple.

## The Lists

- Inbox - raw and rough ideas: anything goes in, as a flat list of points, and is easily scrapped
- Todo - what was decided to do soon
- Roadmap - the concepts decided on, by priority: what will be done, and what is nice to have when there is time
- Plan - the active file, with what is in flight now
- Bugs and debt - the other lists the plan pulls from

Every list is a file in `docs/development/`: `inbox.md`, `todo.md`, `roadmap.md`, `plan.md`, `bugs.md` and `tech-debt.md`. A workspace with several apps gives each app a folder of its own in it.

## How To Apply

- Put anything new in the inbox.
- When the director rants, extract one bullet per topic or idea.
- Move an item to the todo when the director decides to do it soon, or to the roadmap for later.
- An item still to be workshopped stays in the inbox until the director decides on it.
- Pull items from the todo into the plan.
- Pull from the bugs and the debt list into the plan as well.
- Answer "what's next?" with a recommendation from the lists, in the order of [Dev Tiers](../behavior/dev-tiers.md), and the director picks.
- What counts as a bug or debt of now depends on where the project is in its lifecycle ([Project Lifecycle](../behavior/project-lifecycle.md)).

## Where A Finding Goes

A finding in the middle of other work is filed by its kind ([Note Issues](../behavior/note-issues.md)).

- Technical (smell, suppression, deprecated pattern, missing test, missing tool or process) -> the debt list ([Technical Debt Template](technical-debt-template.md)).
- A clear bug, where the build does not do what its feature doc or spec says -> the bugs list ([Bugs Template](bugs-template.md)).
- A functional doubt, where the intended behavior itself is unclear -> the inbox, as a question for the director, never a bug and never a fix.
- A functional doc out of date or wrong, where the fix is small -> the fix rides along with the current work and the report names it.
- A functional doc out of date or wrong, where the gap is larger -> the inbox.
- A missing prerequisite -> the plan, above the current item ([Backward-Trace Missing Prerequisites](../behavior/backward-trace-missing-prerequisites.md)).
- A sweep -> one entry in the debt list that lists every instance ([Sweeps Enumerate Into Tech-Debt First](../behavior/sweeps-enumerate-into-tech-debt-first.md)).

## Related

- [Todo Template](todo-template.md)
- [Plan Template](plan-template.md)
- [Roadmap Template](roadmap-template.md)
- [Bugs Template](bugs-template.md)
- [Technical Debt Template](technical-debt-template.md)
