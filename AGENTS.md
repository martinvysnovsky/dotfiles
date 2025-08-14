# Chezmoi Dotfiles Repository

This is a **chezmoi** dotfiles repository managing system configuration files.

## Build/Test Commands

- **Apply changes**: `chezmoi apply` or `chezmoi update`
- **Test configuration**: `chezmoi diff` (preview changes)
- **Validate syntax**: Check individual config files with their respective tools
- **Install packages**: `./run_onchange_install-packages.sh.tmpl` (auto-runs on changes)
- **Git operations**: Auto-commit and auto-push enabled in chezmoi config

## Chezmoi File Conventions

- Files prefixed with `dot_` become `.filename` in home directory
- Files prefixed with `run_onchange_` are scripts that execute when changed
- Files prefixed with `run_once_` execute only once per machine
- `exact_` directories are managed exactly (no extra files allowed)
- Encrypted files use `.asc` extension and GPG encryption
- Templates use `.tmpl` extension for variable substitution

## Repository Structure

- **`dot_config/`** - System configuration files
- **`private_dot_ssh/`** - SSH keys and configuration (encrypted)
- **`.chezmoidata/`** - Data files (packages.yaml)
- **`wallpapers/`** - Desktop wallpapers and assets
- **`taskchampion-sync-server/`** - Task management server setup

## Chezmoi-Specific Guidelines

### Template Variables
- Use `{{ .chezmoi.hostname }}` for hostname-specific configs
- Use `{{ .chezmoi.os }}` for OS-specific configurations
- Store sensitive data encrypted with GPG recipient: 1E11F93142FE863643D6998EBBC2AD2A4E6B0BE5

### Package Management
- Add new packages to `.chezmoidata/packages.yaml` by category (pacman, yay, npm)
- External dependencies go in `.chezmoiexternal.toml`
- Use template scripts for conditional package installation

### Configuration Files
- **Shell scripts**: Use `#!/bin/bash`, follow existing patterns in run scripts
- **Lua (Neovim)**: Use tabs for indentation, return table syntax for plugins
- **YAML**: Use 2-space indentation, follow existing package.yaml structure
- **TOML**: Follow chezmoi configuration patterns in .chezmoi.toml.tmpl
- **ZSH**: oh-my-zsh with powerlevel10k theme, vim mode enabled
