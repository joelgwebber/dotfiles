---
id: dots-52e5
title: Stop committing MCP secrets to Zed settings.json
type: task
priority: 2
created: '2026-06-03T16:00:10Z'
updated: '2026-06-03T19:01:11Z'
labels:
- zed
- config
- secrets
- mcp
---

## Problem
config/zed/settings.json embeds Bearer tokens for the subtext-local and
subtext-staging MCP servers (URL-based context_servers with `headers.Authorization`).
We had to do git surgery (commit af0d902, was de00fd5) to replace them with
`Bearer REPLACE_ME` placeholders before pushing. Working tree still has the
real tokens; backup at tmp/zed-secrets-backup.txt.

`git status` now permanently shows settings.json as modified (placeholders → secrets).

## State of Zed support (researched 2026-06-03)
- **No env var interpolation in settings.json yet**. Active discussion at
  zed-industries/zed#26043. Zed team prefers platform secrets storage
  (Keychain) over `${VAR}` syntax. No timeline.
- **`env` field on context_servers** exists, but only for command-based
  servers. Our offenders (subtext-local, subtext-staging) are URL-based and
  carry their secrets in `headers.Authorization`, where `env` doesn't help.
- **OAuth flow** is supported for URL-based remote servers: omit the
  `Authorization` header and Zed prompts for auth on first use. The Subtext
  setup-plugin skill description says Subtext supports OAuth, so this is
  likely the cleanest fix for our case.

## Options
1. **Try OAuth on the two subtext URL servers** — drop `headers.Authorization`,
   let Zed handle auth. Best if it works.
2. **git skip-worktree on settings.json** — stopgap; doesn't survive clone.
3. **Smudge/clean filter** — strips secrets on commit, injects on checkout.
   Survives clones if filter is registered.
4. **Bitwarden-CLI render-on-startup** — generate settings.json from a
   template at login. Reproducible across machines, adds startup dep.
5. **Wait for Zed native secrets support** — track #26043.

## Plan
- Try option 1 first (OAuth) — quickest test, may make this moot for subtext.
- If OAuth doesn't fit, evaluate options 3 vs 4.

## Outcome (2026-06-03)
Option 1 worked. Dropping `headers.Authorization` (and the entire `headers`
block) from the `subtext-local` and `subtext-staging` context_servers
triggers Zed's OAuth flow. The Bearer tokens we had embedded were
holdovers from before Zed's OAuth support landed — no longer needed.

Net result: settings.json is fully committable; no secrets remain in
working tree or repo. The `Bearer REPLACE_ME` placeholders introduced
by the earlier surgery are removed in the follow-up commit.

Broader concern of MCP secrets in command-based servers (`env` field)
is not currently active for this repo — no command-based MCP server
needs an embedded secret. Re-open / re-file if that changes.

## Links
- Zed feature request: https://github.com/zed-industries/zed/discussions/26043
- Zed MCP docs: https://zed.dev/docs/ai/mcp
