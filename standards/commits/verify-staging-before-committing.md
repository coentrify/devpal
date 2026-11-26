# Verify Staging Before Committing

Before every `git commit`, read `git diff --cached --name-status` and confirm the commit will hold exactly the files meant for it, no more and no fewer.

## Why

No one else's work is swept into a commit, and nothing meant for it is left behind.

## How To Apply

- Edit and stage in one call, read the staged status, commit in the next.
  - A batched `git add a b c` aborts on the first bad pathspec and stages nothing new, while earlier staged changes still commit.
  - Printing the stat in the same chained command as the commit is no check, since the commit runs regardless.
  - Never chain the add and the commit: a `git mv` or `git rm` staged early rides into an unrelated commit through `git add ... && git commit`.
  - A hook refuses a commit that follows a `git add` in the same command.
  - Where a project can, a commit-msg hook refuses a `docs(log)` commit that holds anything but the log. A turn's records together take another scope ([A Turn's Records Land Together](a-turns-records-land-together.md)).
- When earlier `git rm` or `git mv` calls of your own left things in the index, `git reset -- <your paths>` first, then stage each commit's list.
- While anyone else works in the tree - the director, a parallel session, a sub-agent - stage by explicit file name, never a bare `git add -A` and never a directory pathspec, which is `-A` in disguise. A "changed on disk" note about a file you are not editing is the sign.
- Index entries you did not stage are the director's or another session's: leave them staged, and commit only your own paths with `git commit -- <paths>`.
- If a wrong commit lands and is unpushed:
  - `git reset HEAD~1` and redo the staging.
  - With someone else in the tree, `git reset --soft HEAD~1`, unstage only what your own staging swept in, leave their entries as they were, and commit only your own paths with `git commit -- <paths>`.
- The index is shared with everything else in the tree: the director stages files too, and a parallel session or a capture run leaves half-done and untracked files beside yours.

## Related

- [Review Changes Before Reporting Done](../behavior/review-changes-before-reporting-done.md)
- [Gate Commits On Exit Codes](gate-commits-on-exit-codes.md)
- [Commits](commits.md)
