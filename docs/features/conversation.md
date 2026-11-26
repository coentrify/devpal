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
- While it speaks, it hears only stop words, such as stop, wait or hold on: one stops it at once, and it listens.
- Its own voice coming back through the microphone never stops it, and it never answers it.

## Wake Words (Not Yet Implemented)

- When you say its wake words and a sentence, it answers out loud.
- After its answer, you go on talking without its wake words, until 30 seconds of silence.
- Within a second after you stop talking, it shows it is thinking.

## Character

- It answers in its persona's character, in a sentence or two, without repeating itself.
- Known phrases get the persona's fixed reply, the same every time.
- It knows what it can and cannot do, and says so when asked.

## Projects

- When you say work on and a project's name, it focuses on that project and shows the name on its screen.
- When you say back to base, it leaves the project.
- When you ask about a project, its agent looks it up in the project's files, docs and wiki as they are today, read-only.
- Without a project in focus, it looks across all the projects on the machine.
- While it looks something up, it says so, and then gives the agent's answer in a sentence or two.
- What its memory already answers, it answers itself.
- It never guesses about a project, and never only offers to look something up.
- When looking something up fails, it says why.

## Orders

- When you give an order with a project in focus, it reads the order back in your own words and asks: Go?
- When you say go, the project's agent starts the work, and it tells you when the agent is done.
- When you say no or cancel, nothing happens.
- Without a project in focus, it asks which project.
- An agent edits files, and runs git and npm, but never pushes or deletes.
- Each project's agent keeps its own session, so it remembers earlier orders, and you can open that session yourself.

## Cloning

- When you ask it to clone a repository by its name, it asks: Go?
- When you say go, it clones the repository onto the machine, focuses on it, and says what the project is.

## Memory

- It remembers the last 10 exchanges of the conversation, until it restarts.
- When you tell it something worth keeping, or ask it to remember or learn something, it keeps it in a memory on your machine.
- When you ask it to forget something, it forgets it.
- It answers from what it remembers.
- Its memory is a plain list you can read and edit yourself.

## Memory Of The Day (Not Yet Implemented)

- It remembers the day's conversation.
- A new day starts fresh.
