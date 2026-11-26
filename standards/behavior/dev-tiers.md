# Dev Tiers

Work goes in a recommended order, higher tiers first: CI/CD and build, then bugs, then tech debt, then features, each tier counting only what hurts the current phase's goal. The director decides the order, and the agent names what is still open in a higher tier whenever a pick skips it.

## Why

Work builds on a stable foundation, and open bugs and debt are the first thing forgotten.

## How To Apply

- Before starting a feature, check the build, the bugs and the debt of the current phase, where the project's workflow keeps them.
- A broken build comes first, before anything else lands.
- The director may pick a feature over open bugs or debt.
- A pick that skips an open tier gets one line in the report, every time: `Still open in this phase: 3 bugs, 2 debt`.
- Only bugs that hurt the current phase's goal take the bug tier: early on, a bug in a core feature or one that stops the product from being used from start to finish. Every other bug is filed for a later phase where the project's workflow says, such as under the epic it belongs to there in the tickets workflow.
- Only debt that hurts the current phase's goal takes the debt tier: it slows the current work, causes a bug, or blocks a check. Every other debt is noted all the same and filed for a later phase, where work that touches its code often resolves it on the way.
- Bugs and debt may blur into each other, which is fine.
- Debt in code that will not reach the product, a prototype or a throwaway probe, is never scheduled ahead of the work that decides whether the code stays.
- A bug the director wants to keep may stay on purpose. Then it is documented as a feature, and leaves the bugs.

## Related

- [Note Issues](note-issues.md)
- [Feature Workflow](feature-workflow.md)
- [Project Lifecycle](project-lifecycle.md)
