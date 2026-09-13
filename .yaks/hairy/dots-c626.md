---
id: dots-c626
title: Stale entries in ~/.agents/.skill-lock.json
type: task
priority: 3
created: '2026-09-13T22:48:37Z'
updated: '2026-09-13T22:48:37Z'
---

Now that .skill-lock.json is synced across machines, its accuracy matters more.

Two issues:
1. The lock lists 'yak' and 'yak-tracker' (old singular names, source joelgwebber/yaks), but neither exists on disk -- those skills are now the symlinks 'yaks' and 'yaks-tracker' pointing into the dev checkout at ~/src/rs/yaks. A 'npx skills update' may try to reinstall them, potentially over the symlinks.
2. The dev checkout's remote is rocketsurgery-games/yaks, while both the lock and the Claude plugin marketplace (~/.claude/plugins/known_marketplaces.json) point at joelgwebber/yaks. Unclear which is canonical -- possibly a transfer or a fork.

Not touched during the sync work: .skill-lock.json is owned by the skills CLI, so hand-editing it is the wrong fix. Likely correct fix is 'npx skills remove yak yak-tracker' (or whatever the CLI's removal verb is), then verify the symlinks survive an update.
