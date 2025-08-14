# Development Standards

## Code Style Guidelines

### Shell Scripts
- Use `#!/bin/bash` shebang
- Follow existing patterns in run scripts
- Use proper error handling with `set -e`
- Quote variables to prevent word splitting

### Lua (Neovim)
- Use tabs for indentation
- Return table syntax for plugins
- Follow lazy.nvim plugin structure
- Keep configs modular in separate files

### YAML/TOML
- Use 2-space indentation for YAML
- Follow chezmoi configuration patterns in TOML
- Maintain consistent formatting across files

### Configuration Files
- Use meaningful variable names
- Document complex configurations
- Test changes with `chezmoi diff` before applying
- Keep sensitive data encrypted

## Git Standards

- **CRITICAL**: All git operations must use the git-master agent
- Do NOT mention opencode in commit messages
- Do NOT add Co-Authored-By opencode in commits
- Follow conventional commit format when appropriate
- Auto-commit and auto-push are enabled in chezmoi config