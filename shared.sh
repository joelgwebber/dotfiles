# n[vim] ALL THE THINGS.
set -o vi
bindkey -v
export EDITOR=nvim
export GIT_EDITOR=nvim
alias vim='nvim'

# Make ls and grep not suck.
alias ls='ls --color -F'
alias grep='grep --color=auto'

export PS1="%F{blue}[%m]%f %F{green}%(4~|.../%3~|%~)%f > "

