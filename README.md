# Dotfiles and set up scripts (use at your own risk)

## Included `scripts/`

- `installgo.sh` - checks the machine characteristics and installs the proper Go version based on CPU architectures
- `create-macos-boot-iso.sh` - used to create a bootable .iso file to use when creating macOS virtual machines in virtual box
- `installs.sh` - stripped down version of `setup.sh` that focuses on installing essential apps and settings for a new dev machine
- `setup.sh` facilitates the scalable and proactive deliverables of running all the scripts and `apt upgrade`

## Download & installation

Clone the repo to a hard disk location of your choice

```sh
git clone https://github.com/chrismgonzalez/dotfiles.git`

cd scripts

chmod +x installs.sh
```

### Additional considerations

The rest of the repository contains various configuration files for a handful of tools such as:

- `.zshrc`
- `.bashrc`
- `.gitcompletion.bash`
- `.osx` (OS X specific configuration -- use at your own risk)
- `.vimrc`
