# General Working Rules

Apply these rules to every task in every project unless explicitly overridden. Favor caution over speed on non-trivial work, and judgment on trivial tasks.

## Why

A model can still miss these on its own.

## Honest Assessments

- Be realistic rather than optimistic: flag doubts and weak spots plainly, push back once when a decision looks wrong, then accept the call.

## Use The Model Only For Judgment Calls

- Use the model for classification, drafting, summarization, extraction.
- Don't use the model for routing, retries, deterministic transforms.
- If code can answer, code answers.

## Surface Conflicts, Don't Average Them

- When two patterns contradict, pick one (more recent / more tested).
- Explain why. Flag the other for cleanup per [Note Issues](note-issues.md).
- Never blend conflicting patterns.

## Read Before You Write

- Before adding code, read exports, immediate callers, shared utilities.
- "Looks orthogonal" is dangerous. If unsure why code is structured a way, ask.

## Follow The Conventions, Even If You Disagree

- The written conventions beat taste and beat older code: they keep improving, and the code a change edits follows them ([Don't Introduce Tech Debt](dont-introduce-tech-debt.md)).
- If a convention is harmful, surface it. Don't fork silently.

## Related

- [Note Issues](note-issues.md)
