---
name: changesets
description: Ensure PRs carry a Changeset in repos that use Changesets for versioning/releases. Use whenever a repo has a `.changeset/` directory and you are opening, reviewing, or merging a PR, or cutting a release — a user- or consumer-facing change that lands without a changeset means no release gets cut (the work sits untagged), so downstream consumers can't pin it. Covers how to detect the setup, write a changeset, pick the bump, and the catch-up remedy when changesets were missed on already-merged PRs.
---

# Changesets discipline

[Changesets](https://github.com/changesets/changesets) drive versioning + releases in many repos. The failure mode this skill prevents: a user-/consumer-facing change lands **without** a changeset, so the release workflow has nothing to release — the work sits on the main branch untagged, and downstream consumers can't `go get`/`npm install` a version that reflects it. (Learned the hard way: a whole stack of merged PRs left unreleased because none carried a changeset.)

## Detect the setup

A repo uses Changesets if it has a **`.changeset/` directory** with `config.json`. The versioned package(s) are the workspace `name`(s) in the relevant `package.json` (e.g. `@scope/pkg`). Check the repo's `AGENTS.md`/`CONTRIBUTING` for the project-specific release section — it names which workspace is versioned and any bump conventions. **Repo-specific details there win over this skill.**

## The rule: add a changeset when a PR affects a published package

Before opening (or merging) a PR, ask: **does this change affect a published/consumed artifact?**

- **Yes → add a changeset.** New or changed behavior, CLI output, public API, or the **library/import surface a downstream consumer pins** (this counts even if a CLI's runtime behavior is unchanged — the tag is what `go get`/consumers pin).
- **No → skip.** Pure internal infra, CI, docs, or a refactor with no effect on any published package can skip (per most repos' `AGENTS.md`).

When unsure, lean toward adding one — a spurious changelog line is cheaper than an unreleased change.

## Write one

A changeset is a committed markdown file in `.changeset/` (team-tracked — commit it **with** the code, unlike local-only scratch trackers). `npm run changeset` generates one interactively, or hand-write a descriptively-named file (match the repo's existing naming):

```markdown
---
"@scope/pkg": minor
---

One or two sentences describing the change from the consumer's perspective —
this becomes the CHANGELOG entry.
```

- One changeset per concern; multiple can accumulate and coalesce into one version bump.
- **Bump levels:** `patch` (fixes / internal-but-shipped changes), `minor` (new features), `major` (breaking). **Pre-1.0 (0.x) semantics:** Changesets maps `major` → `1.0.0`, `minor` → `0.(y+1).0`, `patch` → `0.y.(z+1)`. So a pre-1.0 breaking change is usually a `minor` bump — don't reach for `major` unless you intend to ship `1.0.0`.

## How the release actually fires (typical flow)

1. Changesets land on the main branch.
2. A **release workflow** opens/updates a **"Version Packages" PR** that bumps the version, writes the CHANGELOG, and syncs any manifest versions.
3. Merging that PR **tags + publishes** the release.

Key mental model: a changeset **triggers** the release and supplies the changelog — it does **not** gate *what* gets tagged. The tag captures all of the main branch at that commit, so unrelated already-merged work rides along into the release once *something* triggers it. (Nested Go modules may get an extra tag like `go/vX.Y.Z` alongside the bare `vX.Y.Z`.)

## Catch-up remedy (changesets were missed)

You can't retro-add a changeset to an already-merged PR, but changesets are forward-looking release notes — they needn't be attached to their originating PR. So:

1. Open a small PR to the main branch adding catch-up changeset file(s) that describe the merged-but-unreleased work (pick the bump that reflects it).
2. Merge it → the Version Packages PR appears → merge that → the release cuts, capturing everything on main (including the changeset-less merges).

For any PR still **open**, add its changeset to its own branch (the proper per-PR way) so it folds into the same release.

## When opening a PR (self-check)

Run this before pushing a PR branch:
- Does the repo have `.changeset/`? If not, skip — not a Changesets repo.
- Does this change affect a published package (behavior / public API / consumed library surface)?
- If yes and no `.changeset/*.md` is staged for it → **write one and commit it with the change.**
