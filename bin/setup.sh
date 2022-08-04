# DO NOT USE, THIS IS A SCRATCHPAD!!!

#!/bin/bash

sudo -v

while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &


echo "------------------------------"
echo "Installing Xcode Command Line Tools."
# Install Xcode command line tools
xcode-select --install


echo "-----Creating folder for install downloads----"
# Create a folder who contains downloaded things for the setup
INSTALL_FOLDER=~/.macsetup
mkdir -p $INSTALL_FOLDER
MAC_SETUP_PROFILE=$INSTALL_FOLDER/macsetup_profile

# initial setup for finder

echo "-----customizing finder -----"

# show library folder
chflags nohidden ~/Library

# show hidden folders
defaults write com.apple.finder AppleShowAllFiles YES

# show path bar
defaults write com.apple.finder ShowPathbar -bool true

# show status bar
defaults write com.apple.finder ShowStatusBar -bool true

echo "--------------------------------"
echo "installing homebrew"


# install brew
if ! hash brew
then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  brew update
  brew upgrade --all
else
  printf "\e[93m%s\e[m\n" "You already have brew installed."
fi

# Install GNU core utilities (those that come with OS X are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils
sudo ln -s /usr/local/bin/gsha256sum /usr/local/bin/sha256sum

# Install some other useful utilities like `sponge`.
brew install moreutils
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
brew install findutils
# Install GNU `sed`, overwriting the built-in `sed`.
brew install gnu-sed
# Install Bash 4.
brew install bash
brew install bash-completion

echo "[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion" >> ~/.bashrc
source ~/.bash_profile

# We installed the new shell, now we have to activate it
echo "Adding the newly installed shell to the list of allowed shells"
# Prompts for password
sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells'
# Change to the new shell, prompts for password
chsh -s /usr/local/bin/bash

echo "------------------------------"
echo "installing curl/wget/git/bash"

# CURL / WGET
brew install curl
brew install wget

{
  # shellcheck disable=SC2016
  echo 'export PATH="/usr/local/opt/curl/bin:$PATH"'
  # shellcheck disable=SC2016
  echo 'export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"'
  # shellcheck disable=SC2016
  echo 'export PATH="/usr/local/opt/sqlite/bin:$PATH"'
}>>$MAC_SETUP_PROFILE

# git
brew install git
git config --global credential.helper osxkeychain

echo "------------------------------"
echo "installing iTerm2 and other tools"


# Terminal replacement https://www.iterm2.com
brew cask install iterm2

# Pimp command line
brew install micro                                                                                    # replacement for nano/vi
brew install lsd                                                                                      # replacement for ls
{
  echo "alias ls='lsd'"
  echo "alias l='ls -l'"
  echo "alias la='ls -a'"
  echo "alias lla='ls -la'"
  echo "alias lt='ls --tree'"
} >>$MAC_SETUP_PROFILE

brew install tree
brew install ack
brew install bash-completion
brew install jq
brew install htop
brew install tldr
brew install coreutils
brew install watch
brew install tmux
brew install vim
brew install ssh-copy-id

brew install z
touch ~/.z
echo '. /usr/local/etc/profile.d/z.sh' >> $MAC_SETUP_PROFILE

brew install ctop

echo "------------------------------"
echo "Fonts"
echo "------------------------------"

# fonts (https://github.com/tonsky/FiraCode/wiki/Intellij-products-instructions)
brew tap homebrew/cask-fonts
brew cask install font-jetbrains-mono

echo "------------------------------"
echo "Applications"
echo "------------------------------"
# Browser
brew cask install google-chrome
brew cask install firefox

# Music / Video
brew cask install spotify
brew cask install vlc

# Productivity
brew cask install kap                                                                                 # video screenshot
brew cask install rectangle
brew cask install alfred                                                                         # manage windows

# Communication
brew cask install slack

# Dev tools
brew cask install ngrok                                                                               # tunnel localhost over internet.
brew cask install postman                                                                            # Postman makes sending API requests simple.

# IDE
brew cask install jetbrains-toolbox
brew cask install visual-studio-code

# install node and yarn

echo "------------------------------"
echo "Node and Yarn"
echo "------------------------------"

brew install n

# make cache folder (if missing) and take ownership
sudo mkdir -p /usr/local/n
sudo chown -R $(whoami) /usr/local/n
# take ownership of node install destination folders
sudo chown -R $(whoami) /usr/local/bin /usr/local/lib /usr/local/include /usr/local/share

n lts

echo "------------------------------"
echo "Netlify and Gatsby"
echo "------------------------------"

npm install -g netlify-cli
npm install -g gatsby-cli

echo "------------------------------"
echo "Go"
echo "------------------------------"

## golang

brew install go@1.13
mkdir -p $GOPATH $GOPATH/src $GOPATH/pkg $GOPATH/bin

echo "------------------------------"
echo "Clean python installs"
echo "------------------------------"

rm /usr/local/bin/python*
rm /usr/local/bin/pip*

rm -Rf /Library/Frameworks/Python.framework/Versions/*

brew install python3
brew install pipenv


echo "------------------------------"
echo "Docker"
echo "------------------------------"


# Docker
brew install docker docker-machine
brew cask install virtualbox
docker-machine create --driver virtualbox default
docker-machine env default
eval "$(docker-machine env default)"

docker run hello-world
docker-machine stop default




echo "------------------------------"
echo "Cleaning up homebrew installs"
echo "------------------------------"
brew cleanup

# create ssh keys
echo "------------------------------"
echo "Creating SSH keys"
echo "------------------------------"

ssh-keygen -t rsa 4096 -C "cmgonza89@gmail.com"

echo "------------------------------"
echo "adding key to auth agent"
echo "------------------------------"


ssh-add ~/.ssh/id_rsa

echo "------------------------------"
echo "Source the shells"
echo "------------------------------"

{
  echo "source $MAC_SETUP_PROFILE # alias and things added by mac_setup script"
}>>~/.bash_profile
# shellcheck disable=SC1090
source ~/.bash_profile
