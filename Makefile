.PHONY: help bootstrap setup check diff sync update clean lint tags skip verbose

VENV := .venv
ANSIBLE := $(VENV)/bin/ansible-playbook
PLAYBOOK := ansible/playbook.yml

help:
	@echo "Dotfiles Management"
	@echo ""
	@echo "Commands:"
	@echo "  make bootstrap    Install uv and create venv"
	@echo "  make setup        Run full Ansible playbook"
	@echo "  make check        Dry run (check mode)"
	@echo "  make diff         Show what would change"
	@echo "  make sync         Sync dependencies from pyproject.toml"
	@echo "  make update       Update dependencies to latest versions"
	@echo "  make lint         Lint Ansible playbooks"
	@echo "  make clean        Remove venv"
	@echo ""
	@echo "Advanced:"
	@echo "  make tags TAG=packages    Run specific tags"
	@echo "  make skip TAG=dotfiles    Skip specific tags"
	@echo "  make verbose              Run with verbose output"

bootstrap:
	./bootstrap.sh

setup:
	@if [ ! -f $(ANSIBLE) ]; then echo "❌ Run 'make bootstrap' first"; exit 1; fi
	$(ANSIBLE) $(PLAYBOOK)

check:
	@if [ ! -f $(ANSIBLE) ]; then echo "❌ Run 'make bootstrap' first"; exit 1; fi
	$(ANSIBLE) $(PLAYBOOK) --check

diff:
	@if [ ! -f $(ANSIBLE) ]; then echo "❌ Run 'make bootstrap' first"; exit 1; fi
	$(ANSIBLE) $(PLAYBOOK) --check --diff

sync:
	@if [ ! -d $(VENV) ]; then echo "❌ Run 'make bootstrap' first"; exit 1; fi
	uv pip install -e .
	@echo "✓ Dependencies synced"

update:
	@if [ ! -d $(VENV) ]; then echo "❌ Run 'make bootstrap' first"; exit 1; fi
	uv pip install --upgrade -e .
	@echo "✓ Dependencies updated"

lint:
	@if [ ! -f $(ANSIBLE) ]; then echo "❌ Run 'make bootstrap' first"; exit 1; fi
	$(VENV)/bin/ansible-lint ansible/

clean:
	rm -rf $(VENV)
	@echo "✓ Virtual environment removed"

# Advanced targets
tags:
	@if [ ! -f $(ANSIBLE) ]; then echo "❌ Run 'make bootstrap' first"; exit 1; fi
	@if [ -z "$(TAG)" ]; then echo "Usage: make tags TAG=packages"; exit 1; fi
	$(ANSIBLE) $(PLAYBOOK) --tags $(TAG)

skip:
	@if [ ! -f $(ANSIBLE) ]; then echo "❌ Run 'make bootstrap' first"; exit 1; fi
	@if [ -z "$(TAG)" ]; then echo "Usage: make skip TAG=dotfiles"; exit 1; fi
	$(ANSIBLE) $(PLAYBOOK) --skip-tags $(TAG)

verbose:
	@if [ ! -f $(ANSIBLE) ]; then echo "❌ Run 'make bootstrap' first"; exit 1; fi
	$(ANSIBLE) $(PLAYBOOK) -vv
