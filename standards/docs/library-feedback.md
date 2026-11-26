# Library Feedback

Friction with a library never gets a doc in the project. It is surfaced to the director in the report, or filed with a library the project contributes to, and a workaround in the code gets a why-comment where it sits.

## Why

Feedback on a library belongs with that library, and the director has the relationship to take it there.

## How To Apply

- The first time a friction point shows up (a missing data-testid, an unintuitive event, a bug, an API shape that forces a hack), name it in the report: the library, the friction, and the workaround if there is one.
- A workaround gets a why-comment at the code, naming the library's friction.
- Never prescribe the fix. That is the maintainer's call.
- A library the project contributes to, listed under `libraries` in `coentrify.json`, gets its friction filed at its source as an issue, one point each, the way its `filing` says ([File A Change With Coentrify](../behavior/file-a-change-with-coentrify.md)).
- What the friction costs the project in ongoing work is debt, a ticket of its own.
- Every brief to an agent that may hit library friction says so.
