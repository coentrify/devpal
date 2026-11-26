# Match Known Commands Deterministically, Classify The Rest

Route known requests through exact matching first, and use the model only for what the matcher misses. Never let the model invent the set of things the system can do.

## Why

A command the user relies on behaves the same every time, costs no latency and works without the model.

## How To Apply

- Match the common phrasings deterministically, and treat that as the fast path.
- Exact matching alone is brittle: a typo drops the user into a conversational path that may refuse them.
- On a miss, ask the model to classify the request into a fixed list of known actions plus an explicit "none".
- Classifying into a fixed list is the one job small models do reliably, so the model belongs on the fallback path.
- Give the classifier worked examples, including deliberate misspellings, and negative examples for requests that merely sound like a command.
- Build any capability or help listing from what is wired up, never from the model, or it will describe abilities that do not exist.
- Only the action path may report an action as done, and every request that can reach both paths is tested for a false "done".

## Related

- [Prompt Small Models Differently](prompt-small-models-differently.md)
- [General Working Rules](../behavior/general-working-rules.md)
