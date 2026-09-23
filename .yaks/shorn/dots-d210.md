---
id: dots-d210
title: Point Claude Code at ~/.agents skills and AGENTS.md
type: task
priority: 2
created: '2026-09-23T13:46:27Z'
updated: '2026-09-23T13:46:53Z'
---

Claude Code reads ~/.claude/skills and ~/.claude/CLAUDE.md, not ~/.agents. Link ~/.claude/skills -> ../.agents/skills and have ~/.claude/CLAUDE.md import ~/.agents/AGENTS.md, both via chezmoi.

---
▸ 2026-09-23T13:46:53Z [Joel Webber]
Added home/dot_claude/symlink_skills (../.agents/skills) and home/dot_claude/CLAUDE.md (existing content + @~/.agents/AGENTS.md). Applied only those two targets; unrelated drift in .claude/settings.json and zed settings left alone.
