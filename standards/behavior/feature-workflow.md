# Feature Workflow

Every new product feature follows this pipeline. Identify the next step, verify its prerequisite, run it, commit.

## Why

A feature is built on intent and context, never on guesses.

## The Pipeline

- Plan ([Always Work From A Plan](always-work-from-a-plan.md)).
- Functional doc at `docs/features/<feature>.md` ([Feature Template](../docs/feature-template.md)).
- The laws a project adopted are checked against the feature, in a step of their own.
- Spec at `docs/features/<feature>.spec.md` ([Feature Spec Template](../docs/feature-spec-template.md)).
- E2E tests, failing first.
- Implement use case by use case, in mock state.
- Regression-test the affected area.
- Proof: a screenshot, a video, a test run or whatever fits, that tells the director the feature is done and lets the director verify it. Proof the director cannot check is no proof.

Small steps keep the focus.

Doc, spec and e2e steps are observation only - no production-code edits ([Non-Destructive Documenting And Test Automation](non-destructive-documenting-and-test-automation.md)).

Commit at each step boundary on the work's branch ([Commits](../commits/commits.md)). Never blend steps. The steps land on main together, green. If a prerequisite is missing, park and recurse ([Backward-Trace Missing Prerequisites](backward-trace-missing-prerequisites.md)).

## Related

- [Always Work From A Plan](always-work-from-a-plan.md)
- [Non-Destructive Documenting And Test Automation](non-destructive-documenting-and-test-automation.md)
- [Backward-Trace Missing Prerequisites](backward-trace-missing-prerequisites.md)
