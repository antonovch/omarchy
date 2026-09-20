---
name: sync-upstream-release
description: >
  Sync this fork with a new upstream Omarchy release tag: fetch tags from the
  `upstream` remote, merge the newest unmerged `vX.Y.Z` tag into the current
  branch, resolve conflicts, and verify with the test suite. Use when asked to
  "sync with upstream", "pull in the latest release", "merge the new Omarchy
  version", or similar fork-maintenance requests. Not for merging
  `upstream/quattro` (upstream's dev branch) itself — this fork only tracks
  upstream's tagged releases, layering its own commits on top.
---

# Sync Upstream Release

This repo (`antonovch/omarchy`, remote `origin`) is a fork of `basecamp/omarchy`
(remote `upstream`). It carries fork-specific commits on top of upstream's
release tags — it does **not** track `upstream`'s default branch
(confusingly also named `quattro`) directly, which is upstream's own
active development branch and diverges heavily (hundreds of commits either
way). Only tagged releases (`vX.Y.Z`) get merged in.

## Steps

1. **Fetch tags.**
   ```bash
   git fetch upstream --tags --prune-tags
   ```

2. **Find the newest release not yet merged.** List tags newest-first and
   check ancestry against the current branch:
   ```bash
   git tag --sort=-creatordate | head -5
   git merge-base --is-ancestor <tag> HEAD && echo "already merged" || echo "new"
   ```
   If the newest tag is already an ancestor of `HEAD`, there is nothing to do
   — report that and stop.

3. **Check working tree is clean** (`git status`) before merging.

4. **Merge the tag directly** into the current branch (this is the
   established pattern here — see commit `91bde129`, "Merge tag 'v4.0.3' into
   quattro"):
   ```bash
   git merge <tag> --no-edit
   ```

5. **Resolve any conflicts.** For each conflicted file, check whether it's a
   real textual conflict or a semantic one (e.g. both sides touched the same
   list/config in different places and git auto-merged it without markers,
   like `install/hardware/all.sh` history shows). For anything where the
   right resolution is a judgment call — not a mechanical "keep both" — stop
   and **ask the user** rather than guessing. Do not resolve by silently
   discarding either side's change.

6. **Run the test suite** before considering the sync done:
   ```bash
   ./test/all
   ```
   A prior release merge (v4.0.3) needed a follow-up fixup commit ("Fix test
   fallout from merging v4.0.3") — expect this class of breakage and fix it
   in a separate commit on top of the merge commit, not by amending the merge.

7. **Do not push** without explicit confirmation — leave the merge commit
   local and let the user decide when to push `origin/quattro`.

## Notes

- `upstream`'s `HEAD`/default branch is itself called `quattro` — don't
  confuse it with this fork's local `quattro` branch. They share a name, not
  a history relationship worth merging wholesale.
- If a new tag turns out to already be reachable from a branch you expected
  (or vice versa), re-check with `git log --oneline <a>..<b>` rather than
  assuming — release tags here sometimes live on short-lived branches
  (`v4-0-4`, etc.) that aren't merged back into upstream's dev branch either.
