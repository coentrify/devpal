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
- Until there is echo cancellation, the microphone is muted while it speaks, and for 300 ms after.
- A voice can be trained from a sample, on the machine.

## Brain

- The talk model is Qwen3 4B Instruct 2507, quantized to Q4_K_M, in `~/.devpal/models`.
- llama.cpp's server runs it on port 5276, started by the app and stopped when it quits. Its log is `~/.devpal/logs/brain.log`.
- A persona's `tone.md` is the model's instructions.
- A full spoken answer takes about 1.3 seconds once the model is warm.
- It hands a question on to Claude Code when it needs more, such as a project's docs or its agents, on each user's own Claude login.
