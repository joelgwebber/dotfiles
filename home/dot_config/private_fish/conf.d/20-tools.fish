if command -q pyenv
    set -gx PYENV_ROOT "$HOME/.pyenv"
    test -d $PYENV_ROOT/bin; and fish_add_path --global --move --path $PYENV_ROOT/bin
    pyenv init - fish | source
    pyenv virtualenv-init - fish | source
end

if command -q direnv
    direnv hook fish | source
end
