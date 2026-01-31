# Dotfiles and set up scripts (use at your own risk)

## Features

* Modular setup script with configuration file
* Automated macOS development environment setup
* Homebrew package management
* Shell configuration (Zsh with Oh My Zsh)
* Python and Node.js environment setup
* Dotfile symlink management
* Backup and restore functionality
* Dry-run mode for safe testing

## Contents

### Main Setup Scripts

- **`setup-new.sh`** - Modern modular setup script (recommended)
  - Multiple operation modes: `--init`, `--update`, `--validate`, `--restore`
  - Configuration via `config.yaml`
  - Dry-run support with `--dry-run`
  - Verbose logging with `--verbose`
  - Automatic backups with restore capability
  
- **`setup.sh`** - Legacy monolithic setup script (deprecated, see MIGRATION.md)

- **`config.yaml`** - Configuration file for setup-new.sh
  - Feature toggles
  - Package lists (brews, casks, fonts)
  - Custom symlinks and directories
  - Environment variables

### Library Modules (`lib/`)

- `utils.sh` - Logging, helpers, confirmation prompts
- `validate.sh` - Configuration validation
- `backup.sh` - Backup/restore with JSON manifest
- `packages.sh` - Package installation (Homebrew, Xcode, Zsh, Python, Node)
- `symlinks.sh` - Symlink and directory management

### Other Scripts

- `installgo.sh` - Installs Go based on CPU architecture
- `create-macos-boot-iso.sh` - Creates bootable macOS ISO for VirtualBox
- `installs.sh` - Stripped down version focusing on essential apps

## Quick Start

### Prerequisites

1. Install Xcode Command Line Tools:
   ```sh
   xcode-select --install
   ```

2. Clone this repository:
   ```sh
   cd $HOME
   git clone https://github.com/chrismgonzalez/dotfiles.git
   cd dotfiles
   ```

### Using the New Setup Script (Recommended)

1. **Review and customize configuration:**
   ```sh
   vim config.yaml
   ```

2. **Validate configuration:**
   ```sh
   ./setup-new.sh --validate
   ```

3. **Preview changes (dry-run):**
   ```sh
   ./setup-new.sh --init --dry-run --verbose
   ```

4. **Run initial setup:**
   ```sh
   ./setup-new.sh --init
   ```

5. **Update packages later:**
   ```sh
   ./setup-new.sh --update
   ```

### Setup Script Modes

```sh
# Initial setup (full installation)
./setup-new.sh --init

# Update packages only
./setup-new.sh --update

# Validate configuration file
./setup-new.sh --validate

# Restore from backup
./setup-new.sh --restore TIMESTAMP

# Dry-run (preview without changes)
./setup-new.sh --init --dry-run

# Verbose logging
./setup-new.sh --init --verbose
```

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

### Creating a GPG key for commit signing
* Follow steps listed in the linked Github documentation [here](https://docs.github.com/en/authentication/managing-commit-signature-verification/checking-for-existing-gpg-keys)

Use the below steps to resolve any gpg signing issues on commit:
```sh
brew install gnupg
brew link --overwrite gnupg
brew install pinentry-mac

# Intel mac (older homebrew)
echo "pinentry-program /usr/local/bin/pinentry-mac" >> ~/.gnupg/gpg-agent.conf 
killall gpg-agent

# M1 mac
echo "pinentry-program /opt/homebrew/bin/pinentry-mac" >> ~/.gnupg/gpg-agent.conf 
killall gpg-agent

# test the output (no errors means the above was successful)
echo "test" | gpg --clearsign  # on linux it's gpg2 but brew stays as gpg

# now you can use GPG signing
git config --global gpg.program gpg  # perhaps you had this already? On linux maybe gpg2
git config --global commit.gpgsign true  # if you want to sign every commit

# After you have run a signed commit, you can verify with:
git log --show-signature -1
```

Reference: https://stackoverflow.com/questions/39494631/gpg-failed-to-sign-the-data-fatal-failed-to-write-commit-object-git-2-10-0