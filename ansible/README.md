# Ansible Setup

This directory contains Ansible playbooks and roles for automated system setup.

## Structure

```
ansible/
├── ansible.cfg              # Ansible configuration
├── playbook.yml             # Main playbook
├── inventory/
│   └── localhost.yml        # Local inventory
├── vars/
│   ├── common.yml           # Common variables
│   ├── darwin.yml           # macOS-specific variables
│   └── debian.yml           # Debian/Ubuntu-specific variables
└── roles/
    ├── prerequisites/       # System prerequisites
    ├── packages/            # Package installation
    ├── languages/           # Programming language setup
    └── dotfiles/            # Dotfile symlinking
```

## Usage

From the repository root:

```bash
# Bootstrap (first time)
./bootstrap.sh

# Run full setup
make setup

# Dry run (check what would change)
make check

# See detailed diff
make diff

# Run specific role
make tags TAG=packages

# Skip specific role
make skip TAG=dotfiles
```

## Roles

### prerequisites
- Installs Xcode Command Line Tools (macOS)
- Installs Homebrew (macOS)
- Updates package managers
- Creates common directories

### packages
- Installs CLI tools and applications
- OS-specific package managers (brew/apt)
- Fonts (macOS)

### languages
- Python (via uv)
- Node.js (via nvm)
- Rust (via rustup)
- Go (via package manager)

### dotfiles
- Creates symlinks from dotfiles repo to home directory
- Links scripts to ~/.local/bin

## Adding New Packages

Edit the appropriate vars file:
- `vars/darwin.yml` for macOS packages
- `vars/debian.yml` for Linux packages
- `vars/common.yml` for cross-platform settings

## Customization

1. Edit variables in `vars/` files
2. Modify role tasks in `roles/*/tasks/`
3. Add new roles as needed
