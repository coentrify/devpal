# Plan

Test and decide the basics before the companion is built.

- Decide which computers it runs on (active)
- Decide the vibe of a persona: its look, its flavors and its way of speaking
- Test free speech recognition on the Mac mini for speed and quality
- Test free voices on the Mac mini for speed, quality and interruption
- Test training a voice from recordings, on the machine
- Test echo cancellation with the microphone beside the speaker
- Decide how it connects to a project's wiki and to the agents

## Decide Which Computers It Runs On

The open question of [coentrify/devpal#1](https://github.com/coentrify/devpal/issues/1).

- Macs first, with the parts that differ per system behind adapters: the lightest app, with speech recognition on the Neural Engine. Windows and Linux wait for an adapter for the sound, the speech recognition and the window.
- Every computer from the start: Windows and Linux run it at once, at the cost of a heavier app built on a web view, and more work before the first Mac has it.
