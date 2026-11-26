# VitePress Wiki

The project docs are served as a VitePress wiki on a fixed non-default port, started by one npm script and open from the first minute of a session. The sidebar is generated from the docs folder, the pages hot reload, every image opens in a lightbox, and the wiki builds in the pre-push hook so a broken page never lands.

## Why

The director reviews the docs, changelogs, captures and reels in the wiki while the agent works.

## Setup

- The sidebar mirrors the docs folder tree ([Docs Folder Structure](../docs/docs-folder-structure.md)), generated, with no page listed by hand.
- The root pages stand on top in the order they read, any other root page after them, so a new page never goes missing.
- Every folder is a collapsed group. The known folders come in a set order, any other folder after them.
- A sidebar group is never a page itself, since a group that links cannot be closed by clicking it again. Its overview is the first item inside the dropdown.
- A page's title is its H1, and a spec nests collapsed under its feature.
- The record groups run newest first: the log, the activity, the playtests, the user tests and the changelog. The activity and log groups are titled Activity Log and Request Log.
- A new or deleted page is picked up in place: once the changes settle, the sidebar is rebuilt and the open pages reload. The server never restarts for it, since a burst of new pages would restart it over and over.
- The wiki has one config file, `.vitepress/config`, and a session never creates a second one.
- The watcher ignores the build output and the cache.
- Every image enlarges on a click to the full window width, so the director judges a capture at full size. The arrow keys walk the page's images, Escape or a click closes it, a counter shows the position, and the hidden state has its own display rule.
- Local search, last updated dates and clean URLs are on.
- Headings are slugged as GitHub slugs them, set once in the config, so an anchor holds on GitHub, in an editor and the wiki. A log heading `## 12:57` links as `#1257`.
- The dev server sends `Cache-Control: no-store`, so the director never reviews a stale image.
- Videos sit in the public folder and embed with a plain video tag.
- A bare word in angle brackets in a page, `<name>`, reads as an html tag and fails the build. It goes in code marks.
- A hosts-file domain is a stopgap not worth keeping.
- The URL with the port is the bookmark.

## How To Apply

- Set the wiki up on day one with the docs skeleton, before any feature.
- At session start, run the wiki when the project has one and hand over its URL. It keeps running after the session when the director asked for it ([Own Ports, Own Processes](../behavior/own-ports-own-processes.md)).
- Keep the config generic, with no hand-kept page lists.
- A full wiki cleanup check against the product as it is is filed as work at each version's close: stale names, drifted references, duplicated facts, the reconstructed history checked against the changelogs.
- Verify a theme change on a fresh navigation, with a page at rest and one with the feature in use, by what is painted. A hot reload replaces a page's images without the lightbox listeners, so a stale page reads as a broken lightbox.

