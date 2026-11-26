# Projects

The companion passes your feedback and issues on to a project the way a typed message reaches it, and keeps everything else in its machine's logs ([coentrify/devpal#3](https://github.com/coentrify/devpal/issues/3)).

## Passing On (Not Yet Implemented)

- A machine's config names the projects its companion knows, each a checkout on the machine.
- When you give it feedback or an issue about a project, a Claude session in that project's checkout gets your words, the way it gets a typed message.
- In a coentrify project, those words stand in the request log with their time, marked as said to the companion by its persona's name, and are filed the way a typed message is.
- What you tell it that is not about a project stays in its machine's logs.
- After it passes something on, it tells you what was filed.

## News (Not Yet Implemented)

- When you ask what waits for you in a coentrify project, it names the tickets with a question, those waiting for a go and those waiting for your verdict.
- When a ticket lands on main, it tells you in a sentence: at once while awake, or when you next wake it.
- When a ticket gets a question for you, it tells you in a sentence, the same way.

## Edge Cases

- A go or a verdict stays typed, so a misheard word never starts work.
- A permission prompt stays at the keyboard, so a misheard word never grants access.
