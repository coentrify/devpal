# Prompt Small Models Differently

A prompt written for a frontier model degrades a small local one. Give each model tier its own prompt and let them diverge.

## Why

Each model tier answers best on a prompt written for it.

## How To Apply

- A small model loses the thread in long, multi-part instructions and fills gaps confidently: asked about state it cannot see, it answers with a plausible number instead of saying it cannot know.
- Keep the instruction short and rule-shaped: a numbered list of hard rules beats prose paragraphs.
- Lower the temperature for rule-following work. Creative defaults invent state.
- State a fact more than one way when it must survive rephrasing, since a small model will answer one phrasing and miss its synonym.
- Bound the reply length in the request as well as in the prompt.
- Each time the system gains a capability, re-read the prompt for rules that now contradict it: a rule from before, such as "you cannot see the screen", keeps the model refusing once the screen is wired up, and the symptom looks like a model problem.

## Related

- [Match Known Commands Deterministically, Classify The Rest](match-known-commands-deterministically-classify-the-rest.md)
- [Honest Assessments](../behavior/general-working-rules.md#honest-assessments)
