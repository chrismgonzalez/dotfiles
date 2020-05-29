# include other dotfiles
# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{bash_prompt}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

# History control
# don't use duplicate lines or lines starting with space
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
# append to the history file instead of overwrite
shopt -s histappend

# Aliases
alias cp='cp -Rv'
alias ls='ls --color=auto -ACF'
alias ll='ls --color=auto -alF'
alias grep='grep --color=auto'
alias mkdir='mkdir -pv'
alias mv='mv -v'
alias wget='wget -c'

alias gadd='git add'
alias gcom='git commit'
alias gsup='git status'
alias goto='git checkout'

alias node='nodejs'

alias pip='pip3'
alias python='python3'
alias pym='python3 manage.py'
alias mkenv='python3 -m virtualenv venv'
alias startenv='source venv/bin/activate'
alias stopenv='deactivate'
alias pyinstall='pip install -r requirements.txt'

# Use programs without a root-equivalent group
alias docker='sudo docker'
alias npm='sudo npm'
alias prtn='sudo protonvpn'

# Show contents of dir after action
function cd () {
    builtin cd "$1"
    ls -ACF
}

# Golang install or upgrade
function getgolang () {
    sudo rm -rf /usr/local/go
    wget -q -P tmp/ https://dl.google.com/go/go"$@".linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf tmp/go"$@".linux-amd64.tar.gz
    rm -rf tmp/
    go version
}

# GHCLI install or upgrade
function getghcli () {
    wget -q -P tmp/ https://github.com/cli/cli/releases/download/v"$@"/gh_"$@"_linux_amd64.deb
    cd tmp/ && sudo dpkg -i gh_"$@"_linux_amd64.deb
    cd .. && rm -rf tmp/
    gh --version
}


# Markdown link check in a folder, recursive
function mlc () {
    find $1 -name \*.md -exec markdown-link-check -p {} \;
}

# Go
export PATH=$PATH:/usr/local/bin:/usr/local/go/bin:~/.local/bin:$GOPATH/bin
export GOPATH=~/go

# Yarn
export PATH=$PATH:/opt/yarn-1.22.4/bin:$PATH

# Vim for life
export EDITOR=/usr/bin/vim

# Bash completion
source ~/.git-completion.bash


VIRTUAL_ENV_DISABLE_PROMPT=true
function omg_prompt_callback() {
    if [ -n "${VIRTUAL_ENV}" ]; then
        echo "\e[0;31m(`basename ${VIRTUAL_ENV}`)\e[0m "
    fi
}
