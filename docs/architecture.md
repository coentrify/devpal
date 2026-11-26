# Architecture

How devpal is built: the decisions so far.

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

- Its lines come from Claude Code, on each user's own Claude login, with its persona's character in the prompt and its projects' docs at hand.
