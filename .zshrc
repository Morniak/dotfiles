
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="spaceship"
plugins=(
  git 
  zsh-autosuggestions 
  vscode 
  fzf
  zoxide
)

source $ZSH/oh-my-zsh.sh

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
   export EDITOR='vim'
 else
   export EDITOR='code -w'
fi

alias ccd="cd"
alias cat="bat"

export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
