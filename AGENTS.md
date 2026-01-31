# Chezmoi Dotfiles Repository

## Agent Usage

**CRITICAL**: For ANY chezmoi or dotfiles-related operation, IMMEDIATELY use the dotfiles-manager agent:

- Chezmoi command workflows (`apply`, `diff`, `add`, `edit`, `encrypt`)
- File naming conventions and template creation
- GPG encryption and secrets management
- Script execution and package installation
- Cross-platform configuration
- Troubleshooting and debugging
- Any other dotfiles or chezmoi tasks

The dotfiles-manager agent has complete authority over chezmoi operations and has access to the comprehensive chezmoi skill with detailed reference documentation.

**Do NOT attempt chezmoi operations directly** - always delegate to the dotfiles-manager agent.

## Commands

- **Test**: `chezmoi diff` (preview changes before applying)
- **Apply**: `chezmoi apply` (apply changes to system)
- **Validate**: `chezmoi verify` (check repository integrity)

## File Naming Conventions

- `dot_*` → `.filename` in home directory
- `run_onchange_*` → executes when file changes
- `run_once_*` → executes once per machine
- `encrypted_*` → GPG encrypted (recipient: 1E11F93142FE863643D6998EBBC2AD2A4E6B0BE5)
- `*.tmpl` → template files with variable substitution (e.g., `{{ .chezmoi.hostname }}`, `{{ .packages.pacman }}`)
- `exact_*` → directories managed exactly (removes untracked files)

## Code Style

- **Shell scripts**: `#!/bin/bash` shebang, no error handling required for simple scripts
- **YAML**: 2-space indentation, structured by category (pacman/yay/npm in packages.yaml)
- **TOML**: Follow existing .chezmoi.toml.tmpl structure
- **Lua**: Tabs for indentation, LazyVim plugin syntax

## Guidelines

- Add packages to `.chezmoidata/packages.yaml`, not inline in scripts
- Use templates (`.tmpl`) for files needing variable substitution or file hashing
- Encrypt sensitive files with GPG (`chezmoi encrypt` or `encrypted_` prefix)
- Auto-commit/auto-push enabled - changes apply to git automatically
