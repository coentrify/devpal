# Own Ports, Own Processes

Every server the agent starts (dev server, preview, e2e web server) runs on a port of its own, and the agent only ever stops what it started.

## Why

More worktrees could be using the same machine.

## Own Ports

- Each project gets a fixed, random 5-digit port (e.g. `41737`) for the agent's servers, stable so launch configs and tooling can rely on it, and different per project so parallel agents never collide.
- The framework's default port stays free for the director, who tests the build by hand with a separate `npm start`.
- Never fall back to the default port, and never reuse a server that already listens on a port: it may be the director's app, another project, or stale code.
- A session in a worktree can find the launch config's port taken by another session's server. It adds an entry of its own on a free port for the run and leaves that entry out of the commit.

## Kill Only Your Own

- Capture `$!` when you background a process, and kill that PID.
- Start every process of your own so it is easy to find again: a distinctive port or a marker of its own in its command line, and match on that.
- Before any `pkill`, list what would die with its full command line, `ps -o pid=,args= -p "$(pgrep -d, -f <pattern>)"`, and read it.
- Never free a port by killing whatever listens on it. Start your own on another port instead.
- When you do kill something of theirs, say so plainly and restart it before continuing.

### Why

A pattern kill that looks local can hit a process of the director's that runs the same script, such as a server a desktop app forks behind an open window. It happens during cleanup, after attention has moved on, and the damage shows up where the terminal is not looking.

## Stop What You Started

- Stop every server and process you started once you are done with it, so nothing lingers on a port.
- The exception is a server the director asked to keep running, such as the docs wiki, or a prototype the director uses from its link.

## Related

- [General Working Rules](general-working-rules.md)
