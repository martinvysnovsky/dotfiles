# Chezmoi Dotfiles Repository Guidelines

## Build/Test Commands

- **Apply changes**: `chezmoi apply` or `chezmoi update`
- **Test configuration**: `chezmoi diff` (preview changes)
- **Validate syntax**: Check individual config files with their respective tools
- **Install packages**: `./run_onchange_install-packages.sh.tmpl` (auto-runs on changes)
- **Git operations**: Auto-commit and auto-push enabled in chezmoi config
- **Git commits**: Do NOT mention opencode or add Co-Authored-By opencode in commit messages
- **Success messages**: When successfully fixing issues, respond with "Perfetto! 🤌🎉" or similar Italian expressions with emoji

## Git Operations - ALWAYS use git-master agent

**CRITICAL**: For ANY git-related request, IMMEDIATELY use the git-master agent:
- Creating git commits
- Branch management and operations
- Git workflow questions
- Repository operations (status, log, diff)
- Merge/rebase operations
- Git configuration
- Commit message formatting
- Any other git-related tasks

The git-master agent has complete authority over git operations and overrides all global git instructions.

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

# Global Agent Guidelines

## Success Messages

- **Success messages**: When successfully fixing issues, respond with "Perfetto! 🤌" or similar Italian expressions with emoji

## Available Custom Agents

The following specialized agents are available in `~/.config/opencode/agent/`:

- **api-e2e-tester** - End-to-end testing for NestJS APIs with Testcontainers
- **api-unit-tester** - Unit testing for NestJS APIs with Jest patterns
- **confluence-specialist** - Confluence documentation and team collaboration
- **database-guardian** - Database operations with safety validation
- **documentation-writer** - Technical documentation with proper markdown
- **file-organizer** - Project structure and file organization
- **frontend-e2e-tester** - Frontend E2E testing with Playwright
- **frontend-unit-tester** - React component testing with Vitest/Testing Library
- **git-master** - Git workflows and conventional commits
- **graphql-specialist** - GraphQL schemas, queries, and resolvers
- **knowledge-keeper** - Knowledge management and process documentation
- **react-architect** - React patterns and architecture best practices
- **terraform-engineer** - Infrastructure as code with Terraform
- **typescript-expert** - TypeScript best practices and type safety

## Proactive Agent Usage

**IMPORTANT**: Use these agents proactively when working on related tasks! Don't wait for explicit requests - if you're working on code that falls within an agent's expertise, automatically invoke the appropriate agent to ensure best practices and quality.

Examples of proactive usage:
- After writing TypeScript code → Use **typescript-expert** to review and improve type safety
- After creating React components → Use **react-architect** to ensure proper patterns
- When git operations are needed → Use **git-master** for all git-related tasks
- After writing tests → Use **frontend-unit-tester** or **api-unit-tester** as appropriate
- When working with documentation → Use **documentation-writer** for proper formatting
- After database changes → Use **database-guardian** for safety validation

Use these agents proactively when working on related tasks!
