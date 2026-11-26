# Architecture

How devpal is built: the decisions so far.

- Everything runs on the machine: listening, speaking and the brain. Only a question handed on to Claude Code leaves it.

## Computers

- Macs first: the lightest app, with speech recognition on the Neural Engine ([coentrify/devpal#1](https://github.com/coentrify/devpal/issues/1)).
- The sound, the speech recognition and the window sit behind adapters.
- Windows and Linux follow, each once its adapters exist.

## Screen

- The app is native Swift, in `app/`, and draws with Metal.
- A background is a Metal shader in `backgrounds/<name>/`, and a filter is one in `filters/<name>/`. They are compiled when the app starts.
- A persona's image is a set of SVG stills in `personas/<name>/image/`.
- `npm start` opens the window, and `--snapshot` renders one frame to a PNG for the tests.

## Machine

- `~/.devpal/config.json` picks the machine's persona, background and filter.
- `~/.devpal/vocabulary.txt` holds the machine's special words.
- `~/.devpal/memory.md` is what the companion has learned, one fact per line.
- `~/.devpal/models` holds the talk model, and `~/.devpal/logs` the logs.
- None of it leaves the machine or goes into version control.

## Package

- On npm it is `devpal`, public like `coentrify`.
- The repository is set up on coentrify.
- Each machine keeps its config and its logs in its home folder.
- The timings are defaults a machine's config can change.

## Listening

- A voice detector starts speech recognition only while someone talks.
- Only what follows the wake words goes to its brain.
- Echo cancellation keeps it from hearing itself.
- On a Mac, speech recognition is Parakeet v3 through FluidAudio, on the Neural Engine.
- A Silero voice detector cuts what you say into sentences at 0.75 seconds of silence.
- Special words are rescored with a small CTC model, from the words devpal ships and the machine's own list in `~/.devpal/vocabulary.txt`.
- Parakeet v3 with the word list won the test on this Mac mini: 4.8% word errors, 17 of 20 special words, 38 ms a sentence. Whisper large-v3-turbo had 11.5% and 4 of 20 at 231 ms, and Apple's on-device recognizer 21.8% and none. Neither got better from a word list.

## Speaking

- The voice is Kokoro 82M through FluidAudio, on the Neural Engine.
- A persona's `voice.json` picks its Kokoro voice. The plain persona speaks as `am_onyx`.
- Each sentence is synthesized while the one before it plays.
- The microphone and the voice share one audio engine with macOS voice processing on. With the microphone and the speaker on separate devices, it cancels only part of the echo.
- So while it speaks, it acts only on stop and pause words in what it hears. 800 ms after it stops, everything heard while it spoke is dropped, and listening starts fresh.
- Every drop starts a new generation, and every listening event carries the generation of its audio, so an event about dropped audio that arrives late is ignored.
- A persona's `replies.json` holds fixed replies to known phrases, matched word for word before the model.
- A voice can be trained from a sample, on the machine.

## Brain

- The talk model is Qwen3 4B Instruct 2507, quantized to Q4_K_M, in `~/.devpal/models`.
- llama.cpp's server runs it on port 5276, started by the app and stopped when it quits. Its log is `~/.devpal/logs/brain.log`.
- The model's instructions are the persona's `tone.md`, ten short numbered rules, the projects on the machine, the project in focus, and what it remembers.
- A full spoken answer takes about 1.3 seconds once the model is warm.
- An answer is one short sentence, capped at 60 tokens, with a repeat penalty of 1.15.

## Turns

- Each sentence goes through code first: the persona's fixed replies, then remember, don't forget, learn and forget, then work on, back to base and clone. They act directly.
- A read-back waits for go, yes or do it, and no, cancel or never mind drop it.
- Every other sentence the model sorts into question, order or chat, at temperature 0, with a JSON schema that allows only those three. It sorted 24 of 24 test sentences right.
- A question the memory already answers, sharing two meaningful words with a fact, goes to the model. Other questions go to an agent.
- An order is read back in the developer's own words, and waits for go.
- With a project in focus, once its agent has answered, chat goes to the agent too, and a yes to a question the agent asked starts the work at once.
- Chat goes to the model, which keeps its memory with two tools, remember and forget, for phrasings the code misses.

## Agents

- Each project's agent is Claude Code, run headless in the project's folder on the user's own Claude login. It takes the `claude` on the PATH, or else the newest one the Claude desktop app keeps.
- Each project folder has one session, kept in `~/.devpal/sessions.json` and resumed every time, so the agent keeps its context. The developer can open it with `claude --resume` in that folder.
- Without a project in focus, a question goes to Claude Code in the projects folder, `~/dev` or `projects` in the machine's config.
- Reading uses Read, Grep, Glob, WebFetch, and git log, status and diff.
- Working adds editing and writing files, git add, commit, checkout, switch, branch and stash, npm, node and mkdir, with edits accepted.
- Pushing, rm, git reset and git clean are never allowed.
- An order runs in the background, and its report is spoken once the companion is quiet.
- Cloning runs git over SSH. It searches the GitHub owners of the projects already on the machine, with the name joined by dashes, by nothing and by underscores.
- After a clone, the new project's agent reads its docs and says what it is, and the project comes into focus.
- A one-sentence question cost about $0.16 on the Claude account in testing.
