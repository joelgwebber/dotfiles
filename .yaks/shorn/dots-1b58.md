---
id: dots-1b58
title: Decide how to sync ~/.agents
type: task
priority: 2
created: '2026-09-13T22:46:14Z'
updated: '2026-09-13T22:48:37Z'
---

Survey of ~/.agents (172K, 18 files, 20 skill entries), 2026-09-13.

THREE POPULATIONS, different sync needs:

1. LOCK-MANAGED / installed (11 dirs on disk): find-skills, sightmap-authoring, sightmap-browser, subtext-{privacy,review,session,setup-plugin,shared,sightmap,telemetry,using-subtext}.
   Sources are all PUBLIC: vercel-labs/skills, fullstorydev/subtext.
   REPRODUCIBLE from .skill-lock.json via 'npx skills update'. Syncing their files is redundant and actively fights the updater -- the user's own AGENTS.md says 'do not hand-edit an installed skill'. Sync the LOCK, not the files.

2. HAND-AUTHORED (5 dirs, not in lock): changesets, github-stacked-prs, fsta-sightmap-browser, sightkick-authoring, sightkick-debug.
   NOT reproducible -- they exist only on this machine. Sync as files or lose them.

3. SYMLINKS (4): yaks, yaks-tracker, yaks-working, yaks-coordinating -> /Users/joel/src/rs/yaks/skills/... (absolute, so they break on Linux).

PUBLIC-REPO RISK (dotfiles is public):
- changesets, github-stacked-prs: generic, safe to publish.
- fsta-sightmap-browser: names app.staging.fullstory.com and a managed-SSO workaround.
- sightkick-authoring + sightkick-debug (~24K): document sightkick/sightmap. fullstorydev/sightmap is PRIVATE and no public sightkick repo exists -- so these two describe an internal, unreleased project. This is the real blocker for 'just sync everything'.

SYMLINKS ARE SOLVABLE: verified in a sandbox that chezmoi's symlink_ prefix writes the source file's CONTENTS as the link target, so a relative target works. home/dot_agents/skills/symlink_yaks containing '../../src/rs/yaks/skills/yaks' resolves from ~/.agents/skills/ to ~/src/rs/yaks/skills/yaks on any machine. Requires the yaks checkout at ~/src/rs/yaks on both boxes.

TWO BUGS FOUND:
- Stale lock: .skill-lock.json still lists 'yak' and 'yak-tracker' (old names, source joelgwebber/yaks), but on disk those are now symlinks named yaks/yaks-tracker pointing into the dev repo. 'npx skills update' would try to reinstall over them.
- The dev checkout ~/src/rs/yaks has remote rocketsurgery-games/yaks, while both the lock and the Claude plugin marketplace point at joelgwebber/yaks. Unclear which is canonical.

---
▸ 2026-09-13T22:48:37Z [Joel Webber]
Implemented the safe-subset option. Managed now:
  ~/.agents/AGENTS.md
  ~/.agents/.skill-lock.json      (source: dot_skill-lock.json -- leading dot would be ignored)
  ~/.agents/skills/changesets/SKILL.md
  ~/.agents/skills/github-stacked-prs/SKILL.md
  ~/.agents/skills/{yaks,yaks-tracker,yaks-working,yaks-coordinating}  (relative symlinks)

Verified after apply: all 4 symlinks are relative and resolve, SKILL.md readable through them, all 20 skill dirs still present (chezmoi removed nothing), and fsta-sightmap-browser / sightkick-* / the 11 installed skills all confirmed unmanaged.

home/.chezmoiignore recreated to list the 3 internal skills, so 'chezmoi add -r ~/.agents' can't sweep them into a public repo.

Also cleared a stale 'config file template has changed' warning: the template content was unchanged since 3ebc8ea, but the rebase rewrote the file and chezmoi's stored hash predated it. chezmoi init regenerated an identical config.
