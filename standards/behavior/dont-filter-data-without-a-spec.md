# Don't Filter Data Without A Spec

Never drop or filter out data - client-side or server-side - unless that exclusion is explicitly specified: documented as intended behavior and covered by a test.

## Why

Unexpected data surfaces, so someone sees it and decides.

## How To Apply

- Before adding any filter - a `.filter()`, a narrowing request param, a guard that skips records - confirm the exclusion is specified. If it isn't, surface the data and get it specced first.
- When the exclusion is wanted, document it (feature doc or spec) and add a test that asserts it.
- Default to surfacing unexpected data as a distinct state or error over quietly removing it.

## Related

- [Verify APIs Against Docs And The Installed Artifact](verify-apis-against-docs-and-the-installed-artifact.md)
- [Note Issues](note-issues.md)
