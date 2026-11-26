# Feature Spec Template

One spec per feature, beside its [feature doc](feature-template.md).

## Purpose

The functional list of use cases a person can run by hand and the e2e file implements as `test()`s, one per stable id. Use cases are functional. "Test case" is reserved for the e2e code.

The spec is the only place use cases and step-by-step scenarios live.

Title: `# <Feature Name>`, matching the feature doc. A subtitle only when the scope isn't obvious.

## Why

A feature is verified the same way by hand and by e2e, through one set of use cases.

## Use Cases

`## Use Cases` opens with a flat overview list of every case, ``<description> (`<feature-id>-N`)``, ordered by id. Below it, each case is its own `###` heading, which scans better than a nested-bullet wall and gives each case a real anchor.

## Use Case Shape

- Subheading: ``### <Use Case Name> (`<feature-id>-N`)``, the name in Title Case and the same as its test's title. ID format matches the overview list so the two read identically.
- Body: flat dash list. No nesting.
- Step order: start state, action, confirm(s), each step its own bullet. Never one arrow-chained sentence. Multi-action cases add more action and confirm bullets. Tightly coupled inverse actions (open + dismiss) can share one case.
- Static-baseline cases (e.g. touch-target sizing) may use a start-state bullet then confirm bullet(s) without an action - the case is an observation about the rendered state.

Example:

```
### List Unresolved Requests (`inbox-1`)

- On the request overview
- open the inbox from the navigation
- confirm the list shows the unresolved requests
```

### Start State

- First step describes the start state functionally, not as an action. Prefix with `On ` so it reads as a state declaration: "On mobile viewport, sidebar overlay open."
- Auth, navigation, and prior setup are implied by the state, not enumerated as steps. Auth is mocked - never write "Sign in" as a step.
- Self-contained: each case repeats whatever start state it needs, never "Reach the state from `<other-id>`". The IDs are anchors for e2e tags, not for chaining.
- Be explicit about preconditions that flip the case: "On a fresh visit, not signed in." is clearer than "On a fresh visit." when the case is about the unauthenticated flow. Extra confirms beat leaving anything ambiguous.
- State declarations and confirms are from the user's side, never the system's: "with an expired session", not "with stored credentials that have expired".

### Actions

- An action states the user's intent: what they are trying to do and, where it helps, what for. "The user submits the details to get into the records", not "clicks the login button" and not "triggers the login" - a reworded gesture is still a gesture.
- Each layer toward the code gets more technical: the feature doc states a capability ("the user can save a draft"), the spec states the intent per step ("saves the draft to finish it later"), the e2e does the gestures ("fill the form, press save").
- Never implementation verbs: tap, click, type, drag, swipe, press, hover, unless the gesture is the feature itself.
- One user intent per step.

### Confirms

- Always confirm the result of an action - the action step alone is not enough. The case is verified by the visible outcome.
- One observation per step. Multiple confirms after a single action are fine and often clearer than one packed sentence.
- Insert an intermediate confirm between two actions when the first action could realistically fail or produce an unexpected state - otherwise the second action runs on an unverified premise and the eventual failure points the wrong way. Pure data-entry actions (type a comment, tick a box) can skip the intermediate confirm and merge with the next action.
- Negative confirms must be observable. "No silent re-auth is attempted" is too vague to assert. "No redirect to the sign-in provider occurs" is concrete.

### Other Rules

- No state-marker tags like `(auth required)` on cases. A case that is about such a state lives in that feature's own spec.
- Steps stay brief, succinct, and functional - no selectors, no component names, no implementation language. Literal UI labels in backticks are allowed (e.g. `Save`).

## Stable IDs

- IDs never renumber. Adding a case adds a new ID. Removing one leaves the gap.
- An id changes only together with every reference to it, its tags and links included, in one change ([Propagate Renames And Convention Changes Everywhere](../behavior/propagate-renames-and-convention-changes-everywhere.md)).
- E2E tests carry the matching `@<feature-id>-N` tag. The spec is the source of truth.

## Coverage

- One use case per scenario worth verifying, including each edge case from the feature doc.
- Every spec ends with an `Overview` use case (`<feature-id>-overview` ID, no number) that strings the happy-path flows of the feature into a single showcase tour. This case is the source of truth for the overview take. Keep it concise - showcase main features, skip edge cases.
- Add the spec entry first, then the test that covers it.
- When finalizing, audit coverage in both directions: every feature and edge case in the feature doc has at least one use case here, and every use case maps to a feature or edge case there. Close a gap by writing the missing entry or moving the case to the spec that owns it.
- A use case lives in the spec of its *primary* feature. If a case is really about another feature (e.g. a search behavior that only happens to be exercised through a responsive scenario), move it to that feature's spec - don't duplicate.
- Not every use case lands as an e2e test. Visual, styling, and a11y assertions (font sizing, border radius, touch-target sizes) belong in the UI / styleguide test layer.
  - The spec still lists the case. The layer depends on what the case verifies.
  - The e2e file leaves a comment pointing to the layer that owns a skipped case, and the case in the spec gets a trailing `_Verified at the UI / styleguide layer._` italic note.
- One case = one scenario. If a case has conditional confirms that depend on environment or context ("In production... / In non-production..."), split it - a real test can only run in one mode at a time, and a smashed-together case verifies one branch in any single run.

## Related

- [Feature Workflow](../behavior/feature-workflow.md)
- [No Faux Headers In Lists](no-faux-headers-in-lists.md)
