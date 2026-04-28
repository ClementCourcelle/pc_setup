DOTFILES_REPO ?= git@github.com:ClementCourcelle/dotfiles.git
DOTFILES_DIR  ?= $(HOME)/dotfiles
SETUP_DIR     := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.DEFAULT_GOAL := help
.PHONY: help all tools dotfiles gnome

help:
	@printf 'Usage: make [target]\n\n'
	@printf 'Targets:\n'
	@printf '  %-10s %s\n' all      'Install tools, dotfiles, and GNOME settings'
	@printf '  %-10s %s\n' tools    'Install system tools (requires sudo)'
	@printf '  %-10s %s\n' dotfiles 'Clone/update dotfiles repo and deploy with stow'
	@printf '  %-10s %s\n' gnome    'Apply GNOME dconf settings'
	@printf '\nVariables (override with make VAR=value):\n'
	@printf '  %-15s %s\n' DOTFILES_REPO '$(DOTFILES_REPO)'
	@printf '  %-15s %s\n' DOTFILES_DIR  '$(DOTFILES_DIR)'

all: tools dotfiles gnome

tools:
	sudo bash $(SETUP_DIR)install_tools.sh

dotfiles:
	@if [ ! -d '$(DOTFILES_DIR)' ]; then \
		git clone $(DOTFILES_REPO) $(DOTFILES_DIR); \
	else \
		git -C $(DOTFILES_DIR) pull --rebase; \
	fi
	bash $(DOTFILES_DIR)/install_dotfiles.sh

gnome:
	dconf load / < $(SETUP_DIR)gnome-settings.ini
	sudo rm -rf /usr/share/gnome-shell/extensions/ubuntu-dock@ubuntu.com

