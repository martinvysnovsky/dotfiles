# Agent Guidelines for Chezmoi Dotfiles Repository

## Build/Test Commands
- **Apply changes**: `chezmoi apply` or `chezmoi update`
- **Test configuration**: `chezmoi diff` (preview changes)
- **Validate syntax**: Check individual config files with their respective tools
- **Install packages**: `./run_onchange_install-packages.sh.tmpl` (auto-runs on changes)

## Repository Structure
- This is a **chezmoi** dotfiles repository managing system configuration
- Files prefixed with `dot_` become `.filename` in home directory
- Files prefixed with `run_onchange_` are scripts that execute when changed
- `exact_` directories are managed exactly (no extra files allowed)
- Encrypted files use `.asc` extension and GPG encryption

## Code Style Guidelines
- **Shell scripts**: Use `#!/bin/bash`, follow existing patterns in run scripts
- **Lua (Neovim)**: Use tabs for indentation, return table syntax for plugins
- **YAML**: Use 2-space indentation, follow existing package.yaml structure
- **TOML**: Follow chezmoi configuration patterns in .chezmoi.toml.tmpl
- **File naming**: Follow chezmoi conventions (dot_, run_, exact_ prefixes)

## Configuration Management
- Use templates (.tmpl) for files needing variable substitution
- Store sensitive data encrypted with GPG (recipient in .chezmoi.toml.tmpl)
- Package lists managed in .chezmoidata/packages.yaml
- External dependencies defined in .chezmoiexternal.toml