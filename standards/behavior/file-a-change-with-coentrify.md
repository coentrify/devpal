# File A Change With Coentrify

A project that is a contributor files a harness change with coentrify, where the change holds beyond the project.

## Why

What one project learns reaches every project.

## How To Apply

- A project files only when its `coentrify.json` says `contributor: true`. Any project can be a contributor, and the setting is the director's standing go to file at the source.
- `filing` in `coentrify.json` says who files. With `review`, the default, the director looks at the issue first, and that look is the go for it. With `automatic`, the subagent that `healing` starts files it on its own ([Always Make No Mistakes](always-make-no-mistakes.md#a-rule-or-a-check)).
- A change is filed as an issue at the source that `coentrify.json` names. Creating the issue is the filing, so the agent creates it there itself once the go is in, without asking again.
- Filing needs no clone of the source and no rights on it, only an issue opened there.
- A session whose tools cannot create the issue shows the director a prefilled link to a new one, which files it in one click. `node node_modules/coentrify/src/tools/scripts/issue-link.mjs <draft>` prints it from the draft's title and body.
- The link appears in the chat, copied whole from what the script printed right before the reply, one link per print. It never stands only in a tool's output or a file, and is never typed out or pieced together.
- The draft is saved where the project's workflow puts a finding ([Note Issues](note-issues.md)), so its link can be printed again until the issue is filed.
- A change to a module with a source of its own is filed with coentrify only when it is generic, as an addition of the module or the standard that coentrify lacks.
- An issue holds one point, so issues close one by one.
- Before filing, search the open issues.
- A point that is filed already gets an addition on that issue, or a thumbs up.
- A trigger is a mistake that comes back and costs, within the project or across projects. A rule a project keeps for itself is no trigger on its own.
- A mistake that coentrify's own text or steps cause, at a step every project goes through, comes back across projects, so one time is enough to file it. A mistake the project's own content causes has to come back first.
- The test: would another project, following the same steps, meet it too?
- An issue states the trigger, the proposal and the check: what happened, the rule to add, change or loosen and the standards it touches, and whether code could catch it instead, and which.
- The source is public, and it expects issues from the projects that use it. An issue tells nothing of its project's content for that reason: its story, its world, its characters, its mechanics and its names stay out.
- It states the strategy or the gap in the abstract, the trigger included, and an example in it is made up for the filing.
- Before a draft is saved, the agent reads it as one who knows the project would. That reader finds nothing to recognize the project by.

## Related

- [Standards Maintenance](standards-maintenance.md)
- [Always Make No Mistakes](always-make-no-mistakes.md)
