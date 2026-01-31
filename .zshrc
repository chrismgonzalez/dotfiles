# Kiro CLI pre block. Keep at the top of this file.
# [[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"

typeset -U path

# Better history management
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY
setopt HIST_IGNORE_SPACE
setopt HIST_IGNORE_ALL_DUPS

###############################
# Environment Variables
###############################


export LANG=en_US.UTF-8
export EDITOR='nvim'
export VISUAL='nvim'

# Directories
export DOTFILES=$HOME/code/dotfiles
export CODEDIR=$HOME/code
export ICLOUD=$HOME/icloud
export ZETTELKASTEN=$HOME/Zettelkasten

# Go configuration
export GODEBUG=asyncpreemptoff=1
export GOPATH="$HOME/go"
export GOROOT="$(brew --prefix golang)/libexec"

# fzf parameters used in all widgets - configure layout and wrapped the preview results (useful in large command rendering)
export FZF_DEFAULT_OPTS="--height 100% --layout reverse --preview-window=wrap"

# CTRL + R: put the selected history command in the preview window - "{}" will be replaced by item selected in fzf execution runtime
export FZF_CTRL_R_OPTS="--preview 'echo {}'"

# ALT + C: set "fd-find" as directory search engine instead of "find" and exclude "venv|virtualenv|.git" of the results during searching
export FZF_ALT_C_COMMAND="fd --type directory --exclude venv --exclude virtualenv --exclude .git"

# ALT + C: put the tree command output based on item selected
export FZF_ALT_C_OPTS="--preview 'tree -C {}'"

# CTRL + T: set "fd-find" as search engine instead of "find" and exclude "venv|virtualenv|.git" for the results
export FZF_CTRL_T_COMMAND="fd --exclude venv --exclude virtualenv --exclude .git"

# CTRL + T: put the file content if item select is a file, or put tree command output if item selected is directory
export FZF_CTRL_T_OPTS="--preview '[ -d {} ] && tree -C {} || bat --color=always --style=numbers {}'"

# Docker configuration
export DOCKER_DEFAULT_PLATFORM=linux/arm64

# AWS CLI
export AWS_CLI_AUTO_PROMPT=on-partial

# Claude Code
export CLAUDE_CODE_USE_BEDROCK=1
export ANTHROPIC_SMALL_FAST_MODEL_AWS_REGION=us-west-2

# Path configuration
path=(
    $HOME/.local/bin                          # pipx binaries, uv python installs
    ${GOPATH}/bin
    ${GOROOT}/bin
    /opt/homebrew/bin
    $path
)
export PATH

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

###############################
# Completion Settings
###############################

# Add zsh-completions to fpath
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
fi

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
# Zsh plugins
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# AWS Profile Switcher
# source "$SCRIPTS/awsp"

# NVM configuration

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"


###############################
# Source Additional Files
###############################
# Source aliases first (so they're available in other sourced files)
if [ -f "$DOTFILES/.aliases" ]; then
    source "$DOTFILES/.aliases"
else
    echo "Warning: .aliases file not found in $DOTFILES"
fi

# Source configuration files
for config_file in ~/.{bashrc}; do
    [ -f "$config_file" ] && source "$config_file"
done


# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/chris/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

# bun completions
[ -s "/Users/chris/.bun/_bun" ] && source "/Users/chris/.bun/_bun"

# [[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

export DISABLE_AUTOUPDATER=1
eval "$(fzf --zsh)"
eval "$(starship init zsh)"

# Kiro CLI post block. Keep at the bottom of this file.
# [[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"
