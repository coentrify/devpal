# Overview

The Security standards: hard boundaries.

- [Keep Personal Data Out Of Requests](keep-personal-data-out-of-requests.md) - no name, email or account id of the director's in a web request
- [Keep Secrets Away From Agents](keep-secrets-away-from-agents.md) - a secret is set up so only the running app reads it, never in a `.env` file, a chat or a log
- [Never Access The Keychain](never-access-the-keychain.md) - never query the keychain
