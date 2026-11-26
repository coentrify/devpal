# Don't Introduce Tech Debt

Code you write or extend should follow the established conventions, whatever the surrounding file happens to do.

## Why

Any work should add value. Debt detracts from it.

## How To Apply

- Before extending a type, const, or file, check it against the relevant conventions (as-const + `Enum` over bare unions, one artifact per file, barrel imports). New or extended code conforms even when its neighbors don't.
- The code a change edits, the function or the scope it works in, follows the conventions, the older code in it included.
- What the agent's own change introduced is fixed in the same pass, never filed as new debt: a leftover alias, a probe gone blind, a helper bypassed.
- A violation that was already there, in a file the change touches, is fixed in the same pass when it is small and obvious, and named for a veto ([Flag Every Addition Of Your Own](flag-every-addition-of-your-own.md)).
- One that is complex, or outside the change's scope, is noted as debt and left as it is ([Note Issues](note-issues.md)).
- A green build and passing tests do not mean no debt was added. The compiler does not enforce these conventions.
- In the tickets workflow, a ticket lands right.

## Related

- [Note Issues](note-issues.md)
- [General Working Rules](general-working-rules.md)
