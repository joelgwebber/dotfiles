# User-level agent guidance (`~/.agents`)

This is Joel's personal, cross-harness agent directory. It is shared by many
harnesses (Zed, Codex, Cursor, Gemini CLI, Amp, Copilot, …) — see
`.skill-lock.json`'s `lastSelectedAgents`.

## Skills live in `~/.agents/skills/<name>/SKILL.md`

Each skill is a directory with a `SKILL.md` (YAML frontmatter: `name`,
`description`, optional `activation:` / `disable-model-invocation`). Skills here
are **auto-discovered** — the agent reads each skill's `description` to decide
when to load it, so the description is the discovery signal. To make a new skill
reliably found, give it a specific, actionable `description` (name the tools,
symptoms, and when to use it), not a vague one.

Some entries are **symlinks** into a source repo (e.g. `yaks -> ~/src/rs/yaks/skills/...`);
edit those at their source, not here.

## Two kinds of skill — and how to update each

1. **Installed (lock-managed).** Installed from GitHub with the
   [`skills` CLI](https://skills.sh/) (`npx skills`) and tracked in
   `~/.agents/.skill-lock.json` by `source` + `skillFolderHash`. Examples:
   `find-skills`, `sightmap-*`, `subtext-*`.
   - Update all: `npx skills update`
   - Add one: `npx skills add <owner/repo@skill> -g -y`  (`-g` = global/user-level)
   - **Do not hand-edit** an installed skill's files — a re-run of `update`
     overwrites them. Fix the change upstream in its source repo and re-install/update.

2. **Hand-authored (local, unmanaged).** Created by hand (or by an agent) directly
   under `~/.agents/skills/`; **not** in `.skill-lock.json`. `npx skills update`
   leaves them alone, so maintain them by editing their `SKILL.md` directly.
   - `fsta-sightmap-browser` — driving live Fullstory staging (FSTA) with
     `sightmap browser` by attaching to a real logged-in Chrome (CfT can't do
     managed SSO); includes the `--enable-features=WebMCPTesting` flag guidance.

When adding a hand-authored skill, follow the built-in `create-skill` guidance:
lowercase-hyphenated `name` matching the directory, a specific `description`, and
focused instructions.

## Checking what's installed vs. hand-authored

- In the lock (`jq -r '.skills | keys[]' ~/.agents/.skill-lock.json`) → installed.
- A skill dir present but absent from the lock → hand-authored (update by hand).
