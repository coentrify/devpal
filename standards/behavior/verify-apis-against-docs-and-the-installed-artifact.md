# Verify APIs Against Docs And The Installed Artifact

When a dependency is pinned and the docs disagree with it, the installed artifact decides what the code can use. The other path is to update the dependency.

## Why

The installed code is what runs, so it decides.

## How To Apply

- When updating the dependency is an option, check its docs for what the update would add.
- For API endpoints, verify existence, path, method, and request/response shape against the OpenAPI/Redoc spec itself before documenting them - don't infer from client code or assume an endpoint is missing.
- For a generated asset whose layout the framework unwraps or parses, derive that layout from the framework's documented rule instead of positioning by eye, then render the result and look at it.

## Related

- [Always Verify Before Reporting Done](always-verify-before-reporting-done.md)
