---
id: dots-0bce
title: nvim not pulling from the system clipboard
type: bug
priority: 2
created: '2026-10-02T04:08:37Z'
updated: '2026-10-02T05:05:19Z'
labels:
- linux
verify: nvim --headless -c "if has_key(get(g:, \"clipboard\", {}), \"name\") | cquit | endif" -c q
---

Not sure why. I checked, and it's working everywhere else, but pasting back into vim (from `"+p`) refuses to pick up the system clipboard.

It doesn't seem to be just the terminal (Ghostty), as it pastes fine into `micro` running in the same terminal.

---
▸ 2026-10-02T05:05:18Z [Joel Webber]
Fixed. `~/.config/nvim/lua/plugins/osc52.lua` installed an OSC52 clipboard
provider whose `paste` function never reads the system clipboard:

    local function paste()
      return { vim.fn.split(vim.fn.getreg(''), '\n'), vim.fn.getregtype('') }
    end

`getreg('')` is nvim's **unnamed register**. So `"+p` returned whatever you last
yanked or deleted inside nvim, and the OS clipboard was never consulted. Copy
worked (OSC52 writes are fine), which is why this read as a half-broken
clipboard rather than a missing provider.

That snippet is verbatim from the nvim-osc52 README, and it is not a bug there.
Reading a clipboard over OSC52 requires the terminal to answer an OSC 52 query,
which terminals disable by default -- it would let anything holding a tty
exfiltrate your clipboard. Ghostty is no exception. So upstream substitutes the
unnamed register, because over SSH there is nothing better. On a local desktop
it just replaces a working bidirectional provider with a write-only one.

The A/B, measured against a clipboard holding 359 bytes:

    nvim --clean      ->  exepath('wl-paste') = /usr/bin/wl-paste,  len 359
    nvim (config)     ->  g:clipboard.name = 'osc52',               len  52

Two different values from one clipboard is the whole bug. 359 is the real
contents; 52 was the unnamed register of a freshly started nvim.

Why micro looked fine: pasting into micro used the terminal's paste binding,
which injects the text as keystrokes (bracketed paste). That never touches a
clipboard provider, so it exercises a completely different path than `"+p` and
tells us nothing about nvim's provider. Same reason Ghostty was correctly
exonerated but the conclusion ("not the terminal") pointed in the wrong
direction.

Fix: gate the plugin behind `cond` so it only loads over SSH, where it is
actually the right tool. Locally nvim 0.12.5 autodetects wl-copy/wl-paste
(wl-clipboard installed, `WAYLAND_DISPLAY=wayland-1`) and gets both directions.
`vim.opt.clipboard = 'unnamedplus'` in config/options.lua is untouched and now
behaves.

Edited in the chezmoi source (`home/dot_config/nvim/lua/plugins/osc52.lua`) and
applied with a targeted `chezmoi apply`; repo and live file verified identical.

Verified after the change: `g:clipboard` is unset (built-in autodetect) and
`strlen(getreg('+'))` is 359, matching `--clean`.

The simpler alternative, if you never want OSC52: delete the file. Keeping it
gated costs nothing locally and saves rediscovering this on the next remote box.

---
▸ 2026-10-02T05:05:19Z [Joel Webber]
verify: `nvim --headless -c "if has_key(get(g:, \"clipboard\", {}), \"name\") | cquit | endif" -c q` -> PASS (exit 0)
