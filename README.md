# Dotfiles and System Setup

Personal dotfiles and automated system setup using Ansible + GNU Stow. Works on both macOS and Linux.

## Features

* **Cross-platform** - Supports macOS and Linux (Debian/Ubuntu)
* **Ansible automation** - Idempotent system setup and package installation
* **GNU Stow** - Clean symlink management for dotfiles
* **Modular structure** - Organized into logical packages
* **Language runtimes** - Python (uv), Node.js (nvm), Rust, Go, TypeScript, Terraform
* **Shell setup** - Zsh with Oh My Zsh and plugins
* **Version controlled** - All configs tracked in git

## Quick Start

### Prerequisites

On a fresh machine, you'll need Git and basic command line tools:

**macOS:**
```sh
xcode-select --install
```

**Linux (Debian/Ubuntu):**
```sh
sudo apt update
sudo apt install git curl
```

### Installation

1. **Clone the repository:**
   ```sh
   cd ~
   git clone https://github.com/chrismgonzalez/dotfiles.git
   cd dotfiles
   ```

2. **Bootstrap** (installs uv and Ansible in a local venv):
   ```sh
   ./bootstrap.sh
   ```

3. **Run the setup:**
   ```sh
   make setup
   ```

   This will:
   - Install system packages (Homebrew/apt)
   - Install language runtimes (Python, Node.js, Rust, Go, TypeScript, Terraform)
   - Set up Zsh with Oh My Zsh
   - Symlink all dotfiles using Stow

## Available Commands

```sh
make help       # Show all available commands
make setup      # Run full Ansible playbook
make check      # Dry run (check what would change)
make diff       # Show detailed diff of changes
make update     # Update Ansible and dependencies
make lint       # Lint Ansible playbooks
make clean      # Remove virtual environment
```

### Advanced Usage

```sh
# Run specific tags
make tags TAG=packages      # Just install packages
make tags TAG=languages     # Just setup languages
make tags TAG=dotfiles      # Just stow dotfiles
make tags TAG=zsh           # Just setup Zsh

# Skip specific tags
make skip TAG=dotfiles      # Skip dotfile symlinking

# Verbose output
make verbose
```

## Structure

```
dotfiles/
├── ansible/              # Ansible automation
│   ├── playbook.yml     # Main playbook
│   ├── roles/           # Modular roles
│   │   ├── prerequisites/
│   │   ├── packages/
│   │   ├── languages/
│   │   └── dotfiles/
│   └── vars/            # OS-specific variables
│       ├── common.yml
│       ├── darwin.yml   # macOS
│       └── debian.yml   # Linux
├── bin/                 # Scripts → ~/.local/bin/
├── zsh/                 # Zsh config → ~/
├── bash/                # Bash config → ~/
├── vim/                 # Vim config → ~/
├── git/                 # Git config → ~/
├── alacritty/           # Alacritty → ~/.config/alacritty/
├── nvim/                # Neovim → ~/.config/nvim/
├── tmux/                # Tmux config → ~/
├── starship/            # Starship → ~/.config/
├── kiro/                # Kiro config → ~/.kiro/
├── launchagents/        # macOS LaunchAgents
├── macos/               # macOS-specific configs
├── bootstrap.sh         # Initial setup script
├── Makefile            # Command shortcuts
└── pyproject.toml      # Python dependencies
```

## What Gets Installed

### Common (macOS & Linux)
- **CLI tools**: git, curl, wget, vim, neovim, tmux, fzf, ripgrep, fd, eza, starship, lazygit
- **Shell**: Zsh with Oh My Zsh and plugins (autosuggestions, syntax-highlighting, completions)
- **Languages**: 
  - Python 3.12 (via uv)
  - Node.js LTS (via nvm)
  - Rust stable (via rustup)
  - Go latest
  - TypeScript + ts-node
  - Terraform
- **Tools**: GNU Stow, jq, yq, htop, tree, pre-commit

### macOS Specific
- Homebrew packages and casks
- Fonts: FiraCode Nerd Font, JetBrains Mono Nerd Font, Victor Mono Nerd Font
- Applications: Rectangle, Ghostty
- Mac App Store apps (via `mas`)

### Linux Specific
- APT packages (Debian/Ubuntu)
- Starship, GitHub CLI via external installers

## Customization

### Adding Packages

Edit the appropriate vars file:

**macOS packages** (`ansible/vars/darwin.yml`):
```yaml
brew_packages:
  - your-package-here

brew_casks:
  - your-app-here

mas_apps:
  - { id: 497799835, name: "Xcode" }
```

**Linux packages** (`ansible/vars/debian.yml`):
```yaml
apt_packages:
  - your-package-here
```

### Adding Dotfiles

1. Create a new stow package:
   ```sh
   mkdir -p myapp
   # Add files with proper structure
   # e.g., myapp/.config/myapp/config.yml
   ```

2. Add to Ansible stow list (`ansible/roles/dotfiles/tasks/main.yml`):
   ```yaml
   loop:
     - myapp  # Add your package here
   ```

3. Run `make setup` to stow it

### Language Versions

Edit `ansible/vars/common.yml`:
```yaml
python_version: "3.12"
node_version: "lts/*"  # or "20.11.0" for specific version
rust_version: "stable"
go_version: "latest"
```

## How It Works

### Ansible
Handles system-level setup:
- Package installation (Homebrew, apt)
- Language runtime installation
- Zsh and Oh My Zsh setup
- System configuration

### GNU Stow
Manages dotfile symlinks:
- Each directory is a "package" (zsh, nvim, etc.)
- Directory structure mirrors your home directory
- Creates symlinks from `~` to `~/dotfiles/package/`
- Example: `~/.zshrc` → `~/dotfiles/zsh/.zshrc`

### Workflow
1. Bootstrap installs uv and Ansible in a local venv
2. Ansible runs playbook to set up system
3. Stow creates symlinks for all dotfiles
4. Edit files in the dotfiles repo, changes are live immediately

## Troubleshooting

### Stow conflicts
If stow reports conflicts, backup and remove the conflicting files:
```sh
mv ~/.conflicting-file ~/.conflicting-file.backup
make setup
```

### Ansible asks for password
Some tasks require sudo (changing default shell, modifying /etc/shells). Enter your password when prompted.

### Missing packages
If a package fails to install, check:
- macOS: `brew search package-name`
- Linux: `apt search package-name`

Update the appropriate vars file with the correct package name.

## Notes

This is my personal dotfiles setup. Feel free to fork and customize for your needs. Your terminal and system configs are personal - use mine as inspiration.

**Disclaimer**: Review the Ansible playbooks and dotfiles before running to ensure they meet your requirements.

## License

MIT - Use at your own risk.

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