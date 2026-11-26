# Keep Secrets Away From Agents

A secret, such as a credential, a token or an API key, is set up so only the running app can read it, as far from the agent as the setup allows.

## Why

What an agent reads can end up in a chat, a log or a commit, and a secret that leaks there is out of the director's hands.

## How To Apply

- A secret lives in the environment the app runs in, such as the host's or the CI's secret store, never in a file or a message the agent reads.
- A `.env*` file with secrets is avoided, even where the director points to one. Configuration that is no secret can live in the project.
- When a task needs a secret, the agent sets up where the app reads it, and the director puts the value there.
- A secret that reaches the chat anyway is never written to a log, a record or a commit, the request log included.
- The keychain is never touched ([Never Access The Keychain](never-access-the-keychain.md)).

## Related

- [Never Access The Keychain](never-access-the-keychain.md)
- [Keep Personal Data Out Of Requests](keep-personal-data-out-of-requests.md)
