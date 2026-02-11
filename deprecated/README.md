# Deprecated Files

This directory contains files that have been replaced by the new Ansible-based setup.

## Replaced by Ansible (as of 2026-02-10)

### Setup Scripts
- `setup.sh` - Original monolithic setup script
- `setup-new.sh` - Modular setup script with config.yaml
- `clean_dotfiles.sh` - Cleanup script

### Library Modules
The `lib-old/` directory contains shell script modules that have been replaced by Ansible roles:
- `backup.sh` → Ansible backup functionality
- `packages.sh` → `ansible/roles/packages/`
- `symlinks.sh` → `ansible/roles/dotfiles/`
- `utils.sh` → Ansible built-in functions
- `validate.sh` → Ansible validation

### Configuration
- `config.yaml` → `ansible/vars/*.yml`

## Migration

The new setup uses:
- `bootstrap.sh` - Installs uv and Ansible
- `Makefile` - Commands to run Ansible playbooks
- `ansible/` - All automation logic

See the main README.md for usage instructions.
