# Dotfiles and set up scripts (use at your own risk)

## Included `scripts/`

- `installgo.sh` - checks the machine characteristics and installs the proper Go version based on CPU architectures
- `create-macos-boot-iso.sh` - used to create a bootable .iso file to use when creating macOS virtual machines in virtual box
- `installs.sh` - stripped down version of `setup.sh` that focuses on installing essential apps and settings for a new dev machine
- `setup.sh` facilitates the scalable and proactive deliverables of running all the scripts and `apt upgrade`

## Download & installation

A brand new developer machine will most likely require you to install XCode and Command Line tools.  There are a few solutions to this problem:

1. When you start up your machine for the first time, go ahead and run `xcode-select --install`. This will install Git for you so that you can clone this repo through normal methods, like a `git clone ...`
2. Use the commands below to download a tarball of the repo, unpack it, give the install script execution rights, and boom you're off.

### Follow the below commands to setup your maching entirely from a script

```sh
# navigate to a director on your machine, in this instance, we'll use /Desktop
cd $HOME

# Use curl to download a tarball of our mac-setup-v2 branch
curl -L -o mac-setup-v2.zip https://github.com/chrismgonzalez/dotfiles/archive/mac-setup-v2.zip

# Unzip the archive we just downloaded
unzip mac-setup-v2.zip

# navigate to to the ./scripts directory
cd mac-setup-v2/scripts

# make the script we want to run executable
chmod +x installs.sh

# run the script
./installs.sh

```

### If Git is already installed on your machine, follow the below steps

Clone the repo to a hard disk location of your choice

```sh

cd $HOME

git clone https://github.com/chrismgonzalez/dotfiles.git`

# change to the scripts directory
cd scripts

# make it executable
chmod +x installs.sh

# run
./installs.sh
```

### Additional considerations

The rest of the repository contains various configuration files for a handful of tools such as:

- `.zshrc`
- `.bashrc`
- `.gitcompletion.bash`
- `.osx` (OS X specific configuration -- use at your own risk)
- `.vimrc`
