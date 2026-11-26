# Wikis

The machine serves every project's wiki on the home network, each on a name of its own, such as `addix.local`.

## Names

- A project with a wiki gets a name on the home network: its folder name, followed by `.local`.
- The machine's config can give a project's wiki another name, such as `cyberquest.local` for `johnny-cyberquest`.
- Any device on the home network opens a wiki by its name, without setup.
- The machine's own address lists the wikis it serves.

## Pages

- A wiki shows its pages as they are in the project's checkout.
- A change to a page shows within seconds.
- A project that gets a wiki, or a wiki cloned onto the machine, is served within a minute.
- A wiki that fails to build keeps showing its last good pages.

## Always On

- One command starts the wikis with the Mac and keeps them running, and another stops that.

## Online (Not Yet Implemented)

- The wikis are online, built from main, behind a sign-in with Google, GitHub or a password.

## Edge Cases

- On the home network, a wiki has no sign-in: anyone on the network can read it.
- An Android device may not find `.local` names.
