---
name: github-stacked-prs
description: Work with GitHub stacked pull requests and the `gh stack` CLI extension without corrupting a chain of dependent PRs. Use when a repo has a stack of stacked/dependent PRs (a chain where each PR's base is the branch below it), when the GitHub UI offers to "create a stack", when `gh stack` is installed, or when a stacked branch shows a surprise huge diff / merge conflict after a rebase or merge.
---

# GitHub stacked PRs + `gh stack`

A "stack" is a chain of dependent PRs where each PR's base branch is the head branch of the PR below it (bottom PR bases on `main`). GitHub has a native stack feature (web UI) driven by the **`gh stack`** CLI extension (`github/gh-stack`). This skill captures the operating model and the recovery recipes for when local and remote drift.

## The one invariant that explains everything

Every branch in a stack must contain its parent's tip in its history. So whenever the trunk or any lower branch moves, keeping the stack valid **requires rebasing the branches above it and force-pushing them** (`--force-with-lease`). Cascade-rebase-and-force-push is the *design*, not a malfunction. Do not expect a stack to behave like independent PRs whose commits never move.

## The failure mode to avoid: mixing manual git with the web UI

Trouble almost always comes from driving branches by hand with `git` **and** clicking the web UI's "create/add to stack" button. The web button assumes the tool's model and will cascade-rebase + force-push the sibling branches out from under your local clone. Symptoms:

- A stacked PR suddenly shows a **huge diff** (e.g. the whole lower stack) and/or a **conflict** on a file both sides touched.
- `git fetch` reports `(forced update)` on the stack's branches.

Pick one lane and stay in it:

- **Tool-driven (workflow A):** let `gh stack` own the stack. Use `gh stack add`/`submit`/`sync`/`rebase`. Reconcile with `gh stack sync` after any server-side change.
- **Manual git (workflow B):** manage branches with `git` yourself and use only `gh stack link` to maintain the GitHub stack object. **Do not** use the web "add to stack" button — it triggers rebases you didn't initiate.

## `gh stack` verbs worth knowing

- `gh stack view` — at-a-glance truth for the locally-tracked stack. A `⚠` on a branch means it does not sit on the tip of its locally-tracked parent (local drift).
- `gh stack sync` — the reconcile button: fetch → reconcile local with the GitHub stack → fast-forward trunk → **cascade-rebase onto updated parents** → atomic `--force-with-lease` push → relink. `--prune` deletes local branches for merged PRs. This is the tool-mediated version of the manual recipes below.
- `gh stack rebase` — cascading rebase across the stack (`--continue`/`--abort`, `--no-trunk`, `--downstack`/`--upstack`).
- `gh stack checkout <stack#|PR#|URL|branch>` — hydrate **local tracking** from an existing remote stack (needed before `view`/`sync`/`rebase` work on a stack you built by hand or in the UI). Caution: it adopts your **existing local branches** as-is; if those are stale relative to a server-side rebase, you'll get a `⚠` and must realign (see below).
- `gh stack link <bottom> ... <top>` — create/update the **remote** stack object from branch names / PR numbers / URLs, bottom-to-top. The no-local-tracking path (for jj/Sapling/ghstack/git-town/manual-git users). It refuses to silently drop a PR: if the stack already contains PRs you omit (even merged ones), it errors and asks you to list them all. Append shortcut: `gh stack link <stack#> <newPR>`.
- `gh stack add <branch>` / `gh stack submit` — add a new slice on top / push + create/update PRs.

Note: plain `gh` (no extension) has **no** stack verbs — `gh pr` is all flat, per-PR. `gh pr update-branch` updates one PR's head from its base and does **not** cascade.

## Recovery recipes (manual git)

Confirm ground truth first — never theorize about hashes:

```
git fetch origin --prune            # watch for "(forced update)" lines
git rev-parse --short <branch> origin/<branch>   # compare local vs remote per branch
```

**Re-parent a hand-built branch onto a rebased base** (branch shows a giant diff because its base was force-updated). Replay only the branch's own commits onto the new base:

```
git rebase --onto origin/<new-base-branch> <old-base-hash> <branch>
git push --force-with-lease origin <branch>
```

`<old-base-hash>` is the commit the branch was originally forked from (the old base tip). Verify afterward: `git diff --stat origin/<new-base-branch>...HEAD` should show only the branch's own files, and `HEAD~1` should equal the new base.

**Realign stale local sibling refs to origin** (origin was rebased; your local copies are behind; you're not editing them). Verify origin is a clean chain, then fast-forward the refs *without* checking them out (no working-tree churn, no push):

```
git merge-base --is-ancestor origin/<lower> origin/<upper>   # confirm clean chain, bottom→top
git branch -f <branch> origin/<branch>                       # for each stale sibling
```

`git branch -f` moves a local ref to match origin without switching branches. Origin is the source of truth after a server-side rebase (it's what reviewers see); prefer aligning local to it over re-pushing local.

## General guidance

- Before building a new slice on a stack, `git fetch --prune` and check for `(forced update)`; a server-side stack action may have moved the branches.
- Expect force-pushes when a lower PR merges (`gh stack sync --prune` cascade-rebases the rest onto trunk). In a low-traffic repo the re-triggered CI is usually fine; in a busy one, coordinate so reviewers aren't disrupted mid-review.
- After any local force-push during review, glance at `gh stack view` (or the PR UI) to confirm the stack still reconciles.
- Keep commit hygiene (sign-offs, scope) intact across rebases — a tool-driven rebase preserves commits, but verify sign-offs survived if the repo enforces DCO.
