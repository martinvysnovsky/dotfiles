# Chezmoi Scripts Reference

Complete guide to script execution in chezmoi, including script types, execution order, and state management.

## Overview

Chezmoi can execute scripts as part of applying dotfiles. Scripts are identified by the `run_` prefix and execute at different stages with different behaviors.

## Script Types

### `run_` - Always Run Scripts
Executes every time `chezmoi apply` is run.

**Filename**: `run_script.sh` or `run_after_script.sh`

**Use case**: Actions that should happen every time (restart services, reload configs)

**Example**:
```bash
#!/bin/bash
# run_after_reload-shell.sh

# Reload shell configuration
pkill -USR1 bash
```

### `run_once_` - Run Once Scripts
Executes only once per machine, tracked in chezmoi state.

**Filename**: `run_once_install-docker.sh`

**Use case**: One-time setup (install software, create directories)

**State tracking**: Hash stored in `~/.local/share/chezmoi/.chezmoistate.boltdb`

**Re-run**: Delete from state:
```bash
chezmoi state delete-bucket --bucket=scriptState
```

**Example**:
```bash
#!/bin/bash
# run_once_install-docker.sh

if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
fi
```

### `run_onchange_` - Run on Change Scripts
Executes when the script content changes (content hash-based).

**Filename**: `run_onchange_install-packages.sh` or `run_onchange_install-packages.sh.tmpl`

**Use case**: Install packages, update dependencies when list changes

**Triggers**: 
- Script content modification
- Template variable changes (if `.tmpl`)

**State tracking**: Content hash stored in state database

**Example**:
```bash
#!/bin/bash
# run_onchange_install-packages.sh.tmpl

# This runs when packages list changes in .chezmoi.toml.tmpl
{{ range .packages.pacman.cli }}
pacman -S --needed {{ . }}
{{ end }}
```

### `run_before_` - Pre-Apply Scripts
Executes before chezmoi applies any changes.

**Filename**: `run_before_backup.sh`

**Use case**: Backup current configs, check prerequisites

**Example**:
```bash
#!/bin/bash
# run_before_backup.sh

BACKUP_DIR="$HOME/.config/backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r ~/.config/nvim "$BACKUP_DIR/" 2>/dev/null || true
```

### `run_after_` - Post-Apply Scripts
Executes after chezmoi applies all changes.

**Filename**: `run_after_restart-services.sh`

**Use case**: Restart services, reload daemons, cleanup

**Example**:
```bash
#!/bin/bash
# run_after_restart-services.sh

systemctl --user restart dunst
systemctl --user restart waybar
```

## Execution Order

Scripts execute in this order:

1. **`run_before_`** scripts (sorted alphabetically)
2. **Apply dotfiles** (copy/template files)
3. **`run_`** scripts (sorted alphabetically)
4. **`run_after_`** scripts (sorted alphabetically)

### Priority Ordering

Use numeric prefixes to control execution order:

```
run_before_10-check-deps.sh       # Runs first
run_before_20-backup.sh           # Runs second
run_before_30-prepare.sh          # Runs third

run_after_10-restart-services.sh  # Runs first
run_after_20-cleanup.sh           # Runs second
```

## Script Naming Patterns

### Combining Prefixes

Script prefixes can be combined:

```
run_once_executable_install-docker.sh
→ Runs once, with execute permissions

run_onchange_after_10-restart-services.sh.tmpl
→ Runs after apply, when template changes, priority 10

run_once_before_setup-dirs.sh
→ Runs once, before applying files
```

### Prefix Order
1. `run_` / `run_once_` / `run_onchange_`
2. `before_` / `after_`
3. Priority number (optional)
4. Descriptive name

### Template Scripts

Add `.tmpl` suffix to use template variables:

```bash
#!/bin/bash
# run_onchange_install-packages.sh.tmpl

{{ range .packages.pacman.cli }}
pacman -S --needed {{ . }}
{{ end }}

{{ if .theme.dark }}
pacman -S --needed catppuccin-gtk-theme-mocha
{{ end }}
```

## Script Environment

### Available Variables

Scripts run with these environment variables:

```bash
# Chezmoi variables
CHEZMOI_SOURCE_DIR     # Source directory path
CHEZMOI_TARGET_DIR     # Target directory (usually $HOME)
CHEZMOI_OS             # Operating system
CHEZMOI_ARCH           # Architecture
CHEZMOI_HOSTNAME       # Hostname
CHEZMOI_USERNAME       # Username

# Example usage
echo "Source: $CHEZMOI_SOURCE_DIR"
echo "OS: $CHEZMOI_OS"
```

### Script Execution Context

- **Working directory**: `$HOME` (target directory)
- **Interpreter**: Determined by shebang or file extension
- **User**: Current user (not root by default)

## Interpreter Support

### Bash Scripts
```bash
#!/bin/bash
# Most common, portable
```

### Shell Scripts (sh)
```sh
#!/bin/sh
# POSIX compliant
```

### Python Scripts
```python
#!/usr/bin/env python3
# run_once_setup-python.py

import os
print(f"Setting up for {os.environ.get('CHEZMOI_USERNAME')}")
```

### Other Languages
```ruby
#!/usr/bin/env ruby
# run_once_setup.rb
```

Chezmoi supports any executable with proper shebang.

## State Management

### Script State Database

Chezmoi stores script state in:
```
~/.local/share/chezmoi/.chezmoistate.boltdb
```

### View State

```bash
# List all state buckets
chezmoi state dump

# View script state
chezmoi state get --bucket=scriptState
```

### Reset State

```bash
# Delete entire script state (re-runs all run_once/run_onchange scripts)
chezmoi state delete-bucket --bucket=scriptState

# Re-run specific script: modify content slightly or delete from state
```

### Manual State Management

For `run_once_` scripts, modify the script to re-run:
```bash
# Add comment to change content hash
# Updated: 2025-01-31
```

## Error Handling

### Exit Codes

Scripts should return appropriate exit codes:

```bash
#!/bin/bash
# run_once_install-package.sh

if ! command -v package &> /dev/null; then
    if ! sudo pacman -S --needed package; then
        echo "Failed to install package" >&2
        exit 1
    fi
fi

exit 0
```

### Chezmoi Behavior on Errors

- Script exits with **non-zero**: Chezmoi **stops** and reports error
- Script exits with **zero**: Chezmoi continues
- Use `set -e` for automatic error handling

```bash
#!/bin/bash
set -e  # Exit on any error

command1
command2  # If this fails, script stops
command3
```

### Conditional Errors

```bash
#!/bin/bash

if ! critical_command; then
    echo "Critical error" >&2
    exit 1
fi

if ! optional_command; then
    echo "Warning: optional command failed" >&2
    # Don't exit, continue
fi
```

## Script Patterns

### Package Installation (with Template)

```bash
#!/bin/bash
# run_onchange_install-packages.sh.tmpl

echo "Installing packages..."

# Pacman packages
{{ range .packages.pacman.cli }}
pacman -S --needed {{ . }}
{{ end }}

# AUR packages
{{ range .packages.yay }}
yay -S --needed {{ . }}
{{ end }}

# Node packages
{{ range .packages.npm }}
npm install -g {{ . }}
{{ end }}
```

### Service Management

```bash
#!/bin/bash
# run_after_10-enable-services.sh

systemctl --user enable --now dunst
systemctl --user enable --now waybar

# Only on workstation
{{ if eq .chezmoi.hostname "workstation" }}
systemctl --user enable --now picom
{{ end }}
```

### Conditional Execution by OS

```bash
#!/bin/bash
# run_once_install-deps.sh.tmpl

{{ if eq .chezmoi.os "linux" }}
# Linux specific
sudo pacman -S --needed base-devel git

{{ else if eq .chezmoi.os "darwin" }}
# macOS specific
brew install gcc git
{{ end }}
```

### Directory Creation

```bash
#!/bin/bash
# run_once_create-dirs.sh

mkdir -p ~/.local/bin
mkdir -p ~/.local/share/applications
mkdir -p ~/.config/{nvim,tmux,git}
mkdir -p ~/projects/{personal,work}
```

### Download External Files

```bash
#!/bin/bash
# run_once_download-fonts.sh

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

# Download JetBrains Mono
if [ ! -d "$FONT_DIR/JetBrainsMono" ]; then
    curl -L https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip -o /tmp/jbm.zip
    unzip /tmp/jbm.zip -d "$FONT_DIR/JetBrainsMono"
    fc-cache -f
fi
```

### Git Repository Clone

```bash
#!/bin/bash
# run_once_clone-repos.sh.tmpl

PROJECTS="$HOME/projects"

{{ range .repositories }}
if [ ! -d "$PROJECTS/{{ .name }}" ]; then
    git clone {{ .url }} "$PROJECTS/{{ .name }}"
fi
{{ end }}
```

**Data in `.chezmoi.toml.tmpl`**:
```toml
[[data.repositories]]
    name = "dotfiles"
    url = "git@github.com:user/dotfiles.git"

[[data.repositories]]
    name = "project1"
    url = "git@github.com:user/project1.git"
```

### Check Dependencies

```bash
#!/bin/bash
# run_before_check-deps.sh

REQUIRED_COMMANDS=("git" "curl" "unzip")

for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: Required command '$cmd' not found" >&2
        exit 1
    fi
done

echo "All dependencies satisfied"
```

### Idempotent Operations

```bash
#!/bin/bash
# run_onchange_setup-fish.sh

# Add custom path to fish config (idempotent)
FISH_CONFIG="$HOME/.config/fish/config.fish"

if ! grep -q "/.local/bin" "$FISH_CONFIG" 2>/dev/null; then
    echo 'set -gx PATH $HOME/.local/bin $PATH' >> "$FISH_CONFIG"
fi
```

### System Configuration

```bash
#!/bin/bash
# run_once_setup-system.sh.tmpl

{{ if eq .chezmoi.os "linux" }}
# Enable multilib repository
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo "[multilib]" | sudo tee -a /etc/pacman.conf
    echo "Include = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
    sudo pacman -Sy
fi
{{ end }}
```

## Debugging Scripts

### Enable Debug Output

```bash
#!/bin/bash
set -x  # Print commands before executing

echo "Starting setup..."
# Commands are printed as they execute
```

### Test Scripts Manually

```bash
# Run script directly (bypass chezmoi)
bash ~/.local/share/chezmoi/run_once_test.sh

# Test with dry run
chezmoi apply --dry-run --verbose
```

### Check Script Syntax

```bash
# Bash syntax check
bash -n run_script.sh

# Shell syntax check
sh -n run_script.sh
```

### View Script Output

```bash
# Apply with verbose output
chezmoi apply --verbose

# Scripts output to stdout/stderr
```

## Best Practices

1. **Use shebang**: Always include `#!/bin/bash` or appropriate interpreter
2. **Check before installing**: Test if command/package exists before installing
3. **Make idempotent**: Scripts should be safe to run multiple times
4. **Use `run_onchange_` for packages**: Avoid re-installing every time
5. **Priority numbers**: Use numeric prefixes for execution order
6. **Error handling**: Exit with non-zero on critical errors
7. **Template for machine-specific**: Use `.tmpl` for conditional logic
8. **Test with dry run**: Always test with `--dry-run` first
9. **Document purpose**: Add comments explaining script purpose
10. **Keep scripts focused**: One script per responsibility

## Common Patterns

### Install from Package List

Store packages in `.chezmoidata/packages.yaml`:
```yaml
pacman:
  - git
  - vim
  - tmux

yay:
  - spotify
  - slack-desktop
```

Use in script:
```bash
#!/bin/bash
# run_onchange_install-packages.sh.tmpl

{{ range .packages.pacman }}
pacman -S --needed {{ . }}
{{ end }}
```

### OS-Specific Scripts

Create separate scripts per OS:
```
run_once_setup_linux.sh.tmpl
run_once_setup_darwin.sh.tmpl
```

With conditional execution:
```bash
{{ if eq .chezmoi.os "linux" }}
#!/bin/bash
# Linux setup
{{ end }}
```

### State Reset Pattern

For development/testing, add version to force re-run:
```bash
#!/bin/bash
# run_once_setup.sh
# Version: 2

# Script content...
```

Increment version to trigger re-run.

## Common Mistakes

### ❌ Missing Shebang
```bash
# run_script.sh (missing #!/bin/bash)
echo "This might not execute correctly"
```
**Fix**: Always add shebang.

### ❌ Not Checking Existence
```bash
pacman -S package  # Reinstalls every time
```
**Fix**: Check first:
```bash
pacman -S --needed package
```

### ❌ Wrong Script Type
Using `run_` when `run_once_` is appropriate causes unnecessary re-execution.

### ❌ Not Handling Errors
```bash
command_that_might_fail
# Continue anyway
```
**Fix**: Check exit code or use `set -e`.

### ❌ Assuming Root Access
```bash
apt install package  # Fails: no root
```
**Fix**: Use `sudo` or run as appropriate user.

## Script Testing Checklist

- [ ] Shebang is correct
- [ ] Script is executable (or has `executable_` prefix)
- [ ] Script is idempotent (safe to run multiple times)
- [ ] Error conditions are handled
- [ ] Dependencies are checked before use
- [ ] OS/hostname conditions are correct (if using templates)
- [ ] Test with `chezmoi apply --dry-run --verbose`
- [ ] Test actual execution on clean system (VM/container)

## Advanced Patterns

### Multi-Stage Setup

```bash
# run_once_before_10-deps.sh
# Install dependencies

# run_once_before_20-download.sh
# Download files

# run_once_after_10-configure.sh
# Configure services

# run_once_after_20-enable.sh
# Enable services
```

### Parallel Safe Scripts

For `run_onchange_` scripts, ensure they're safe if executed concurrently (rare, but possible).

### Integration with External Tools

```bash
#!/bin/bash
# run_once_setup-mise.sh.tmpl

# Install mise
curl https://mise.run | sh

# Install tools from .mise.toml
mise install

{{ if .development }}
# Development-only tools
mise use -g node@latest python@latest
{{ end }}
```

## See Also

- [File Naming Reference](file-naming.md) - Script naming conventions
- [Templates Reference](templates.md) - Using templates in scripts
- [Troubleshooting](troubleshooting.md) - Common script errors
