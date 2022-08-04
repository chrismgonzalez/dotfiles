# Dotfiles and set up scripts (use at your own risk)

## Features:
* TODO
## Contents

- `installgo.sh` - checks the machine characteristics and installs the proper Go version based on CPU architectures
- `create-macos-boot-iso.sh` - used to create a bootable .iso file to use when creating macOS virtual machines in virtual box
- `installs.sh` - stripped down version of `setup.sh` that focuses on installing essential apps and settings for a new dev machine
- `setup.sh` facilitates the scalable and proactive deliverables of running all the scripts and `apt upgrade`

## Usage
I recommend you pick and choose what you want to use from this repo, and create your own dotfiles repo to which they can be added.  Consider changing the git remote to point to your own personal dotfiles, or copy/paste mine into your existing dotfiles. 

Your terminal and system configs are most likely custom to you, I've simply provided mine here so that you can receive some inspiration. Please save a copy of the files you want to take into your own dotfiles repo on your machine.

**DISCLAIMER** Carefully review the files and scripts to be sure they will meet your requirements.  You may want to comment certain things out (such as the symlink creation in `installs.sh`)

## Download & installation

A brand new developer machine will most likely require you to install XCode and Command Line tools.  There are a few solutions to this problem:

1. When you start up your machine for the first time, go ahead and run `xcode-select --install`. This will install Git for you so that you can clone this repo through normal methods, like a `git clone ...`
2. Use the commands below to download a tarball of the repo, unpack it, give the install script execution rights, and boom you're off.

### Follow the below commands to setup your maching entirely from a script

```sh
# navigate to a director on your machine, in this instance, we'll use /Desktop
cd $HOME

# Use curl to download a tarball of our mac-setup-v2 branch
curl -L -o mac-setup.zip https://github.com/chrismgonzalez/dotfiles/archive/mac-setup.zip

# Unzip the archive we just downloaded
unzip mac-setup.zip

# navigate to to the ./scripts directory
cd dotfiles/bin

# make the script we want to run executable
chmod +x installs.sh

# run the script
./installs.sh

```
### If Git is already installed on your machine, follow the below steps

Clone the repo to a hard disk location of your choice, for me, it's the home directory.

```sh

cd $HOME

git clone https://github.com/chrismgonzalez/dotfiles.git

# change to the scripts directory
cd dotfiles/bin

# make it executable
chmod +x installs.sh

# run
./installs.sh
```

### Additional considerations

The rest of the repository contains various configuration files for a handful of tools such as:

- `.zshrc`
- `.bashrc`
- `.git-completion.bash`
- `.osx` (OS X specific configuration -- use at your own risk, I recommend analyzing this file and running it independently from the `installs.sh` script)
- `.vimrc`
