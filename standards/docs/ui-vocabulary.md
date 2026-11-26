# UI Vocabulary

Use functional names for UI patterns - terms that say what the thing does. Be consistent: one pattern, one name everywhere (prose, docs, commits, component class names).

A drawer is a drawer because of its role ("CreateUserDrawer"). Motion descriptors ("slide-in") and component-file names don't earn their keep at the product level.

## Why

Functional names work for every reader without explaining the implementation.

## Drawer Vs Sheet

Both are valid functional names for distinct patterns - don't collapse them into one. A panel can be a drawer on desktop and a sheet on mobile - call each by its role in that layout.

### Drawer

Side-attached panel that opens from a screen edge (typically right or left), used alongside the main view on desktop. Example: a filter panel beside a list on desktop.

### Sheet

Mobile-style panel that slides up from the bottom and modally covers the lower portion of the screen. Example: a filter panel on mobile.

## Don't Use "Surface" As A UI-Area Noun

"The chat surface", "the conversation surface" - product-design jargon that reads as wordy and weirdly abstract. Use the feature's name or natural English: "the chat", "the settings screen", "in the chat". "Surface" the verb (to surface, surfaced) is fine - it means "bring up / show" and is unrelated.

## Related

- [Things Of One Kind Are Consistent](../behavior/things-of-one-kind-are-consistent.md)
- [Docs Describe Behavior, Not Wiring](docs-describe-behavior-not-wiring.md)
- [Feature Template](feature-template.md)
