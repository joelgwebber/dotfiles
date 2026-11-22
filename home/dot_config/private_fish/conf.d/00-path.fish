# Homebrew. Also sets HOMEBREW_*, MANPATH and INFOPATH, so it goes first.
if test -x /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv fish | source
else if test -x /home/linuxbrew/.linuxbrew/bin/brew
    /home/linuxbrew/.linuxbrew/bin/brew shellenv fish | source
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
fish_add_path --global --move --path $PNPM_HOME/bin

fish_add_path --global --move --path ~/.antigravity/antigravity/bin

# nvm is bash-only, so fish can't run `nvm use`. Where node came from nvm
# rather than Homebrew (the DGX box), put the newest installed version on PATH.
if test -d ~/.nvm/versions/node
    set -l nvm_bin (printf '%s\n' ~/.nvm/versions/node/*/bin | sort -V | tail -1)
    test -n "$nvm_bin"; and fish_add_path --global --move --path $nvm_bin
end
