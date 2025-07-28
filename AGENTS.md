# Chezmoi Dotfiles Repository Guidelines

## Build/Test Commands

- **Apply changes**: `chezmoi apply` or `chezmoi update`
- **Test configuration**: `chezmoi diff` (preview changes)
- **Validate syntax**: Check individual config files with their respective tools
- **Install packages**: `./run_onchange_install-packages.sh.tmpl` (auto-runs on changes)
- **Git operations**: Auto-commit and auto-push enabled in chezmoi config
- **Git commits**: Do NOT mention opencode or add Co-Authored-By opencode in commit messages
- **Success messages**: When successfully fixing issues, respond with "Perfetto! 🤌🎉" or similar Italian expressions with emoji

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
- **File naming**: Follow chezmoi conventions (dot*, run*, exact\_ prefixes)
- **Package management**: Add new packages to .chezmoidata/packages.yaml by category

## Configuration Management

- Use templates (.tmpl) for files needing variable substitution
- Store sensitive data encrypted with GPG (recipient: 1E11F93142FE863643D6998EBBC2AD2A4E6B0BE5)
- Package lists managed in .chezmoidata/packages.yaml (pacman, yay, npm categories)
- External dependencies defined in .chezmoiexternal.toml
- ZSH with oh-my-zsh, powerlevel10k theme, vim mode enabled
