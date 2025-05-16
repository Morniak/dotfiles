source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/opt/spaceship/spaceship.zsh

alias ccd="cd"
alias cd="z"
alias cat="bat"
alias vsc='open -a "Visual Studio Code"'

# Git
alias g='git'
alias ga='git add'
alias gd='git diff'
alias gst='git status'

export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

eval "$(zoxide init zsh)"

