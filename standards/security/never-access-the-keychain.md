# Never Access The Keychain

Never access the director's macOS keychain. Do not run `security find-internet-password`, `security find-generic-password`, `security dump-keychain`, or any other `security` / keychain query, and do not script around them. This is a hard boundary.

## Why

The keychain is the director's private credential store. Probing it is an intrusion.

## How To Apply

- A secret a task needs is set up as [Keep Secrets Away From Agents](keep-secrets-away-from-agents.md) says, never taken from the keychain.

## Related

- [Keep Secrets Away From Agents](keep-secrets-away-from-agents.md)
- [General Working Rules](../behavior/general-working-rules.md)
