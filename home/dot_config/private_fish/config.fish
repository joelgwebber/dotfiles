# Managed by chezmoi -- `chezmoi edit ~/.config/fish/config.fish`, then `chezmoi apply`.
#
# Load order: fish sources conf.d/*.fish (alphabetically) BEFORE this file.
#   00-path    PATH and package-manager shims
#   10-env     editor, aliases
#   20-tools   pyenv, direnv
#   30-work    FullStory env (work machines only)
#
# conf.d runs for every fish, interactive or not, so PATH/EDITOR are always
# present -- an improvement over the zsh setup, where everything lived in
# .zshrc and so only existed in interactive shells.

if status is-interactive
    fish_vi_key_bindings

    # Secrets and the FullStory env are interactive-only, matching what .zshrc
    # did. Scripts that need them can call `load-secrets` / `load-work-env`.
    load-secrets
end
