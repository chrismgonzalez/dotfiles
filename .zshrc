###############################
# Early Initialization
###############################

# Better history management
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS

# Enable Powerlevel10k instant prompt (must stay at top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

typeset -g POWERLEVEL9K_INSTANT_PROMPT=off

###############################
# Environment Variables
###############################
export LANG=en_US.UTF-8
export EDITOR='vim'
export DOTFILESDIR=$HOME

# Go configuration
export GODEBUG=asyncpreemptoff=1
export GOPATH="$HOME/go"
export GOROOT="$(brew --prefix golang)/libexec"

# Docker configuration
export DOCKER_DEFAULT_PLATFORM=linux/arm64

# Path configuration
path=(
    $HOME/.local/bin                          # pipx binaries
    /opt/homebrew/opt/postgresql@13/bin       # PostgreSQL
    ${GOPATH}/bin
    ${GOROOT}/bin
    $path
)
export PATH

###############################
# Oh My Zsh Configuration
###############################
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

# Plugin configuration
plugins=(
    git
    brew
    history
    kubectl
    docker
    aws
    history-substring-search
    zsh-autosuggestions        # Add if you have it installed
    zsh-syntax-highlighting    # Add if you have it installed
)

source $ZSH/oh-my-zsh.sh

###############################
# Completion Settings
###############################
# Initialize completion system
autoload -Uz compinit && compinit
autoload -U +X bashcompinit && bashcompinit

# Case insensitive completion
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' \
    'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' \
    'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' \
    'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*'

# Tool-specific completions
[[ $commands[kubectl] ]] && source <(kubectl completion zsh)
complete -C '/opt/homebrew/bin/aws_completer' aws
complete -o nospace -C /opt/homebrew/Cellar/tfenv/3.0.0/versions/1.2.0/terraform terraform

###############################
# Tool Configuration
###############################
# NVM configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"


###############################
# Source Additional Files
###############################
# Source aliases first (so they're available in other sourced files)
if [ -f "$DOTFILESDIR/.aliases" ]; then
    source "$DOTFILESDIR/.aliases"
else
    echo "Warning: .aliases file not found in $DOTFILES"
fi
# Source configuration files

for config_file in ~/.{bashrc,p10k.sh}; do
    [ -f "$config_file" ] && source "$config_file"
done

