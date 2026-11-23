# Homebrew. Also sets HOMEBREW_*, MANPATH and INFOPATH, so it goes first.
if test -x /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv fish | source
else if test -x /home/linuxbrew/.linuxbrew/bin/brew
    /home/linuxbrew/.linuxbrew/bin/brew shellenv fish | source
end

# nvm is bash-only, so fish can't run `nvm use`. Where node came from nvm
# rather than Homebrew (the DGX box), put the newest installed version on PATH,
# just above Homebrew, so the user bin dirs below (pnpm globals) still win.
if test -d ~/.nvm/versions/node
    set -l nvm_bin (printf '%s\n' ~/.nvm/versions/node/*/bin | sort -V | tail -1)
    test -n "$nvm_bin"; and fish_add_path --global --move --path $nvm_bin
end

# --global --move --path keeps PATH a real global rather than a universal
# variable, so nothing is persisted into fish_variables and this config stays
# reproducible from the repo alone.
fish_add_path --global --move --path ~/.local/bin ~/go/bin ~/.cargo/bin ~/depot_tools

set -gx BUN_INSTALL "$HOME/.bun"
fish_add_path --global --move --path $BUN_INSTALL/bin

if test (uname) = Darwin
    set -gx PNPM_HOME "$HOME/Library/pnpm"
else
    set -gx PNPM_HOME "$HOME/.local/share/pnpm"
end
# pnpm 11 links global bins into $PNPM_HOME/bin; pnpm 10 (the DGX box, via nvm)
# puts them in $PNPM_HOME itself. fish_add_path skips whichever doesn't exist.
fish_add_path --global --move --path $PNPM_HOME $PNPM_HOME/bin

fish_add_path --global --move --path ~/.antigravity/antigravity/bin

