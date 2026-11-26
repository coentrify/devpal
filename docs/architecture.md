# Architecture

How devpal is built: the decisions so far.

- Everything runs on the machine: listening, speaking and the brain. Only a question handed on to Claude Code leaves it.

## Package

- On npm it is `devpal`, public like `coentrify`.
- The repository is set up on coentrify.
- Each machine keeps its config and its logs in its home folder.
- The timings are defaults a machine's config can change.

## Listening

- A voice detector starts speech recognition only while someone talks.
- Only what follows the wake words goes to its brain.
- Echo cancellation keeps it from hearing itself.
- On a Mac, speech recognition is Parakeet v3 through Core ML on the Neural Engine. Whisper large-v3-turbo is the fallback.

## Speaking

- The voice is a free text-to-speech model that runs on the machine.
- A voice can be trained from a sample, on the machine.

## Brain

- A small talk model runs on the machine, fast enough to answer at once, with its persona's character in the prompt.
- It hands a question on to Claude Code when it needs more, such as a project's docs or its agents, on each user's own Claude login.
