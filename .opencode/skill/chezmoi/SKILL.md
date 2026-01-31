---
name: chezmoi
description: Manage dotfiles with chezmoi. Use when (1) working with dotfiles, (2) creating chezmoi templates, (3) managing machine-specific configuration, (4) syncing configs across machines, (5) encrypting sensitive files with GPG, (6) using run scripts, (7) managing external dependencies, (8) handling cross-platform dotfiles.
---

# Chezmoi Dotfiles Management

## Quick Reference

This skill provides comprehensive chezmoi patterns for dotfiles management. Load reference files as needed:

**Core Operations:**
- **[file-naming.md](references/file-naming.md)** - Complete file naming conventions (prefixes, suffixes, attributes)
- **[templates.md](references/templates.md)** - Go template syntax, variables, functions, conditionals
- **[scripts.md](references/scripts.md)** - Script execution patterns (run_once_, run_onchange_, run_)

**Advanced Features:**
- **[encryption.md](references/encryption.md)** - GPG encryption workflows and configuration
- **[external-deps.md](references/external-deps.md)** - External file/archive management with .chezmoiexternal.toml
- **[troubleshooting.md](references/troubleshooting.md)** - Common issues and solutions

## Action Guidance

When the user asks about dotfiles or chezmoi operations, **implement the changes directly** using chezmoi commands rather than only suggesting them. If the user says "make this work on macOS only" or "add my bashrc to chezmoi", proceed with implementation.

**ALWAYS preview significant changes** with `chezmoi diff` or `chezmoi cat <file>` before applying.

## Essential Commands

```bash
# Add files to chezmoi
chezmoi add <file>              # Add a file to source directory
chezmoi add --template <file>   # Add as template for machine-specific config

# Preview and apply changes
chezmoi diff                    # Preview what would change
chezmoi cat <file>             # Preview rendered template output
chezmoi apply                  # Apply changes to home directory

# Edit dotfiles
chezmoi edit <file>            # Edit source file
chezmoi edit --apply <file>    # Edit and apply immediately
chezmoi edit --watch <file>    # Auto-apply on save

# Repository operations
chezmoi update                 # Pull from repo and apply
chezmoi re-add                 # Re-add modified files

# Inspection
chezmoi data                   # Show available template variables
chezmoi status                 # Show what would change
chezmoi doctor                 # Check for potential issues
```

## Repository-Specific Configuration

Your chezmoi setup uses the following patterns (from `.chezmoi.toml.tmpl` and AGENTS.md):

### GPG Encryption
- **Recipient**: `1E11F93142FE863643D6998EBBC2AD2A4E6B0BE5`
- **Auto-enabled**: Files prefixed with `encrypted_` are automatically encrypted
- **Quiet mode**: GPG output is muted with `--quiet` flag

### Git Integration
- **Auto-commit**: Enabled - changes are automatically committed
- **Auto-push**: Enabled - commits are automatically pushed to remote
- **Implication**: Be careful with sensitive data - it will be pushed automatically

### Package Management
- **Location**: `.chezmoidata/packages.yaml`
- **Categories**: `pacman`, `yay`, `npm`
- **Usage**: Reference in templates with `{{ .packages.pacman }}`
- **Pattern**: Add packages to YAML, not inline in scripts

### Diff Tool
- **Command**: `nvim -d`
- **Usage**: Interactive diffs in Neovim

## Core File Naming Patterns

### Most Common Prefixes

| Prefix | Effect | Example |
|--------|--------|---------|
| `dot_` | Rename to use leading dot | `dot_gitconfig` → `~/.gitconfig` |
| `private_` | Set permissions to 600 | `private_dot_ssh` → `~/.ssh` (mode 600) |
| `executable_` | Make file executable (755) | `executable_dot_local/bin/script` |
| `encrypted_` | Encrypt with GPG | `encrypted_private_dot_ssh/id_rsa.asc` |
| `exact_` | Remove unmanaged files | `exact_dot_config/nvim/` |
| `run_once_` | Run script once per machine | `run_once_install-packages.sh` |
| `run_onchange_` | Run when content changes | `run_onchange_install-deps.sh` |

### Suffix

| Suffix | Effect |
|--------|--------|
| `.tmpl` | Process as Go template |

### Complete Reference
For the full attribute system and allowed combinations, see [file-naming.md](references/file-naming.md).

## Machine-Specific Templates

Convert a static file to a template by adding `.tmpl` suffix, then use conditionals:

### By Operating System
```go
{{- if eq .chezmoi.os "darwin" }}
# macOS-specific configuration
export HOMEBREW_PREFIX="/opt/homebrew"
{{- else if eq .chezmoi.os "linux" }}
# Linux-specific configuration
export PATH="$PATH:/usr/local/bin"
{{- end }}
```

### By Hostname
```go
{{- if hasPrefix .chezmoi.hostname "work-" }}
# Work machine configuration
export WORK_ENV=1
{{- end }}
```

### By Environment Variable
```go
{{- if env "WORK_ENV" }}
# When WORK_ENV environment variable is set
export COMPANY_PROXY="http://proxy.company.com:8080"
{{- end }}
```

### Combined Conditions
```go
{{- if or (eq .chezmoi.os "darwin") (env "WORK_ENV") }}
# macOS OR when WORK_ENV is set
{{- end }}

{{- if and (eq .chezmoi.os "linux") (eq .chezmoi.osRelease.id "arch") }}
# Arch Linux specifically
{{- end }}
```

### Using Package Data
```go
{{- range .packages.pacman }}
pacman -S --needed {{ . }}
{{- end }}
```

## Escaping Nested Templates

When the target file itself uses `{{ }}` syntax (like mise, Jinja2, Tera, or other templating systems), escape the braces so chezmoi doesn't process them:

```go
# In chezmoi template that outputs mise config
SOME_VAR = "{{ "{{" }}env.OTHER_VAR{{ "}}" }}"

# This renders as:
SOME_VAR = "{{env.OTHER_VAR}}"
```

The `{{ "{{" }}` and `{{ "}}" }}` are Go template expressions that output literal brace characters.

## Common Workflows

### Converting Static File to Template

When converting a static config to machine-specific template:

1. **Read the current file** to understand its contents
2. **Identify machine-specific values** (paths, hostnames, environment settings)
3. **Add as template**: `chezmoi add --template <file>`
4. **Edit the template source** to add conditionals
5. **Preview rendering**: `chezmoi cat <file>`
6. **Apply changes**: `chezmoi apply`

### Adding Encrypted File

For sensitive files like SSH keys or credentials:

```bash
# Add encrypted file (automatically uses GPG recipient from config)
chezmoi add --encrypt ~/.ssh/id_rsa

# This creates: encrypted_private_dot_ssh/id_rsa.asc
# Edit encrypted file
chezmoi edit --encrypted ~/.ssh/id_rsa
```

### Managing External Dependencies

For external Git repositories, archives, or files:

1. Create `.chezmoiexternal.toml` in source directory
2. Define externals (see [external-deps.md](references/external-deps.md))
3. Apply with refresh: `chezmoi apply --refresh-externals`

### Installing Packages

Create `run_onchange_install-packages.sh.tmpl`:

```bash
#!/bin/bash
# packages.yaml hash: {{ include ".chezmoidata/packages.yaml" | sha256sum }}

{{- range .packages.pacman }}
sudo pacman -S --needed {{ . }}
{{- end }}

{{- range .packages.yay }}
yay -S --needed {{ . }}
{{- end }}
```

This script re-runs whenever `packages.yaml` changes.

## Best Practices

### Security
- ✅ **DO** use `encrypted_` prefix for sensitive files
- ✅ **DO** use `private_` for SSH directories and keys
- ❌ **DON'T** commit plaintext secrets (auto-push is enabled!)
- ❌ **DON'T** use `encrypted_` without GPG key configured

### File Organization
- ✅ **DO** use `exact_` for directories that should mirror source exactly
- ✅ **DO** add packages to `.chezmoidata/packages.yaml`
- ✅ **DO** use templates (`.tmpl`) for machine-specific files
- ❌ **DON'T** hardcode machine-specific paths in non-templates

### Scripts
- ✅ **DO** use `run_once_` for one-time setup scripts
- ✅ **DO** use `run_onchange_` for scripts that should re-run when changed
- ✅ **DO** make scripts idempotent (safe to run multiple times)
- ❌ **DON'T** use `run_` for expensive operations (runs every apply)

### Templates
- ✅ **DO** test templates with `chezmoi execute-template`
- ✅ **DO** preview with `chezmoi cat <file>` before applying
- ✅ **DO** use `.chezmoi.os`, `.chezmoi.hostname` for conditionals
- ❌ **DON'T** forget to escape nested template syntax

## When to Load Reference Files

**Need complete file naming reference?**
- All prefixes and suffixes → [file-naming.md](references/file-naming.md)
- Allowed combinations → [file-naming.md](references/file-naming.md)

**Working with templates?**
- Template variables and functions → [templates.md](references/templates.md)
- Conditional logic patterns → [templates.md](references/templates.md)
- Data file integration → [templates.md](references/templates.md)

**Setting up scripts?**
- Script types and execution → [scripts.md](references/scripts.md)
- Package installation patterns → [scripts.md](references/scripts.md)
- State management → [scripts.md](references/scripts.md)

**Configuring encryption?**
- GPG setup and workflows → [encryption.md](references/encryption.md)
- Asymmetric vs symmetric → [encryption.md](references/encryption.md)

**Managing external files?**
- .chezmoiexternal.toml format → [external-deps.md](references/external-deps.md)
- Archive extraction → [external-deps.md](references/external-deps.md)
- Git repository integration → [external-deps.md](references/external-deps.md)

**Debugging issues?**
- Common errors and solutions → [troubleshooting.md](references/troubleshooting.md)
- Template debugging → [troubleshooting.md](references/troubleshooting.md)

## Integration with Repository

This chezmoi setup integrates with your repository patterns:

- **Source Directory**: `~/.local/share/chezmoi`
- **Config File**: `~/.config/chezmoi/chezmoi.toml` (generated from `.chezmoi.toml.tmpl`)
- **Package Data**: `.chezmoidata/packages.yaml` for declarative package management
- **Auto-sync**: Changes automatically committed and pushed to Git
- **Encryption**: GPG-encrypted sensitive files with configured recipient
- **Diff Tool**: Neovim for interactive diffs
