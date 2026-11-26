# Conversation

You talk with the companion out loud, and it answers in its persona's voice and character ([coentrify/devpal#2](https://github.com/coentrify/devpal/issues/2)).

## Listening

- It listens all the time through the machine's microphone, and never sends or stores what it hears.
- A sentence ends once you have been silent for a moment.
- While you talk, the words so far show as subtitles, and settle once you are silent.
- You teach it special words, such as names, brands and odd verbs, in a list that stays on your machine.

## Talking

- It answers out loud once you have been silent for a moment.
- It speaks each sentence as soon as it is ready.
- When you talk while it speaks, it stops and listens.
- Its own voice coming back through the microphone never stops it, and it never answers it.

## Wake Words (Not Yet Implemented)

- When you say its wake words and a sentence, it answers out loud.
- After its answer, you go on talking without its wake words, until 30 seconds of silence.
- Within a second after you stop talking, it shows it is thinking.

## Character

- It answers in its persona's character, in a sentence or two.
- It knows what it can and cannot do, and says so when asked.

## Projects

- When you ask about a project on the machine, it looks it up in that project's files and docs as they are today, read-only.
- While it looks something up, it says so.

## Agents (Not Yet Implemented)

- It talks to the agents working on the projects.

## Memory

- It remembers the last 10 exchanges of the conversation, until it restarts.
- When you tell it something worth keeping, or ask it to remember or learn something, it keeps it in a memory on your machine.
- When you ask it to forget something, it forgets it.
- It answers from what it remembers.
- Its memory is a plain list you can read and edit yourself.

## Memory Of The Day (Not Yet Implemented)

- It remembers the day's conversation.
- A new day starts fresh.
