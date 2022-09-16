# Dotfiles for most of my configuration

## Usage

I recommend you pick and choose what you want to use from this repo, and create your own dotfiles repo to which they can be added.  Consider changing the git remote to point to your own personal dotfiles, or copy/paste mine into your existing dotfiles.

Your terminal and system configs are most likely custom to you, I've simply provided mine here so that you can receive some inspiration. Please save a copy of the files you want to take into your own dotfiles repo on your machine.

**DISCLAIMER** Carefully review the files to be sure they will meet your requirements.  Pick and choose what you want to use

### Contents

- `.alacritty.yml`
- `.aliases`
- `.bash_profile`
- `.bash_prompt`
- `.git_completion.zsh`
- `.gitconfig`
- `.gitignore`
- `.gitmessage`
- `.inputrc`
- `.zshrc`
- `.bashrc`
- `.git-completion.bash`
- `.osx` (OS X specific configuration -- use at your own risk, I recommend analyzing this file and running it independently from the `installs.sh` script)
- `.tmux.conf`
- `.vimrc`

### VSCode

Also included with in are my vscode extensions and a script to save new extenstions and add them in the `./vscode` directory so they are saved in version control.
The scripts mentioned are `save-code-extensions.sh` & `dotfiles-precommit-hook.sh`

### Creating a GPG key for commit signing

- Follow steps listed in the linked Github documentation [here](https://docs.github.com/en/authentication/managing-commit-signature-verification/checking-for-existing-gpg-keys)

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