# Companion

The companion lives on a dev machine's screen, wakes when you talk to it, and speaks to you on its own ([coentrify/devpal#1](https://github.com/coentrify/devpal/issues/1)).

## Install (Not Yet Implemented)

- Installing it on a machine takes one command.
- Its setup asks for the persona, the projects, the screen and the microphone.

## Sleep And Wake (Not Yet Implemented)

- While it is asleep, its screen is off.
- When you say its wake words, the screen wakes and it greets you.
- After 30 minutes without you talking, it falls asleep.
- When you wish it good night, it falls asleep at once.
- While asleep, it takes less than 2% CPU.

## Screen

- The screen stacks three layers: a background, the persona, and a filter in front of both.
- Each layer is picked on its own, so any background, persona and filter go together.
- While it is quiet, it shows its idle still.
- Subtitles show the dialogue near the bottom of the screen, under the filter.
- What you say glows cyan, and what it says glows magenta.
- The project in focus shows as a small label at the top left.

## Screen While Awake (Not Yet Implemented)

- While awake, it fills its screen.
- While it speaks, its speaking stills rotate.

## Backgrounds

- A background fills the screen behind the persona.
- The package ships a synthwave background: a neon grid running to a striped setting sun.

## Filters

- A filter lies over the whole screen, such as an old TV, a modern screen or black and white.
- The package ships a retro CRT filter, with horizontal scan lines.
- Now and then the CRT picture glitches: a line tears, the colors split, a frame jumps.

## Speaking

- When it speaks, you hear it through the machine's speaker, in its persona's voice.

## Speaking On Its Own (Not Yet Implemented)

- While awake, it says something on its own every 10 to 20 minutes.
- What it says on its own is a joke or a remark, in its persona's character, about the projects it knows.
- No line repeats within a week.

## Privacy (Not Yet Implemented)

- What you say without its wake words is never sent and never stored.
