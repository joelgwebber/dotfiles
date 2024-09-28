# n[vim] ALL THE THINGS.
set -o vi
bindkey -v
export EDITOR=nvim
export GIT_EDITOR=nvim
alias vim='nvim'

# Make ls not suck.
alias ls='ls --color -F'

export PS1="%F{blue}[%m]%f %F{green}%(4~|.../%3~|%~)%f > "

