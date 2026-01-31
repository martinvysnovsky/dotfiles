# Chezmoi File Naming Reference

Complete guide to chezmoi's source state attributes (prefixes and suffixes).

## Overview

Chezmoi uses file and directory names in the source directory to determine how they should be named and processed in the target directory. The pattern is:

```
[prefix_][prefix_]...[name][.suffix][.suffix]...
```

## Core Prefixes

### `dot_` - Dotfile Prefix
Adds a leading `.` to the filename in the target directory.

**Source**: `dot_config/nvim/init.lua`
**Target**: `~/.config/nvim/init.lua`

**Source**: `dot_gitconfig`
**Target**: `~/.gitconfig`

### `private_` - Private Files (chmod 600)
Makes file readable/writable only by owner (permissions: `rw-------`).

**Source**: `private_dot_ssh/private_id_rsa`
**Target**: `~/.ssh/id_rsa` (permissions: 600)

**Source**: `private_dot_gnupg/gpg.conf`
**Target**: `~/.gnupg/gpg.conf` (permissions: 600)

### `readonly_` - Read-only Files (chmod 444)
Makes file read-only for all users (permissions: `r--r--r--`).

**Source**: `readonly_dot_ssh/authorized_keys`
**Target**: `~/.ssh/authorized_keys` (permissions: 444)

### `executable_` - Executable Files (chmod 755)
Makes file executable (permissions: `rwxr-xr-x`).

**Source**: `executable_dot_local/bin/script.sh`
**Target**: `~/.local/bin/script.sh` (permissions: 755)

**Source**: `run_once_executable_install-packages.sh`
**Target**: Executable script that runs once

### `encrypted_` - GPG Encrypted Files
File is encrypted in the source directory, decrypted when applied.

**Source**: `encrypted_private_dot_ssh/encrypted_private_id_rsa.age`
**Target**: `~/.ssh/id_rsa` (decrypted, private)

**Configuration required** in `.chezmoi.toml.tmpl`:
```toml
encryption = "gpg"
[gpg]
    recipient = "your-gpg-key-id"
```

### `exact_` - Exact Directories
Removes files in target directory that aren't in source directory.

**Source**: `exact_dot_config/nvim/lua/plugins/`
**Target**: `~/.config/nvim/lua/plugins/` (untracked files removed)

**Warning**: Use carefully - files not in source will be deleted!

### `symlink_` - Symbolic Links
Creates a symbolic link instead of copying the file.

**Source**: `symlink_dot_vimrc` (contains target path)
**Target**: `~/.vimrc` → symlink to path in file

**File content**: `/path/to/actual/vimrc`

### `modify_` - Modified Files
Runs a script to modify an existing file instead of replacing it.

**Source**: `modify_dot_gitconfig`
**Target**: Script modifies existing `~/.gitconfig`

**Script receives**: Original file content on stdin
**Script outputs**: Modified content on stdout

## Script Prefixes

### `run_` - Run Scripts
Executes every time `chezmoi apply` is run.

**Source**: `run_after_10-restart-service.sh`
**Target**: Runs after applying changes

### `run_once_` - Run Once Scripts
Executes only once per machine (tracks in state).

**Source**: `run_once_install-docker.sh`
**Target**: Runs once, then skipped

**Re-run**: Delete from state with `chezmoi state delete-bucket --bucket=scriptState`

### `run_onchange_` - Run on Change Scripts
Executes when the script content changes (hash-based).

**Source**: `run_onchange_install-packages.sh`
**Target**: Runs when script is modified

**Triggers**: Change to script content or template variables it uses

### `run_before_` - Run Before Apply
Executes before chezmoi applies changes.

**Source**: `run_before_backup.sh`
**Target**: Runs before applying dotfiles

### `run_after_` - Run After Apply
Executes after chezmoi applies changes.

**Source**: `run_after_reload-shell.sh`
**Target**: Runs after applying dotfiles

## Suffixes

### `.tmpl` - Template Files
File is processed as a Go template before being written.

**Source**: `dot_gitconfig.tmpl`
**Target**: `~/.gitconfig` (template processed, `.tmpl` removed)

**Template example**:
```gitconfig
[user]
    name = {{ .name }}
    email = {{ .email }}
```

### `.age` - Age Encryption
File is encrypted with age encryption.

**Source**: `encrypted_dot_ssh_key.age`
**Target**: `~/.ssh_key` (decrypted)

**Configuration** in `.chezmoi.toml.tmpl`:
```toml
encryption = "age"
[age]
    identity = "~/.config/age/key.txt"
    recipient = "age1..."
```

### `.literal` - Literal Names
Preserves exact filename (no prefix interpretation).

**Source**: `dot_git.literal`
**Target**: `.git` (directory/file, not interpreted as git repo)

**Use case**: When you need exact names that would otherwise be interpreted.

## Prefix Ordering Rules

Prefixes must appear in this order:

1. `exact_` (for directories)
2. `private_` / `readonly_` / `executable_`
3. `symlink_` / `modify_` / `create_` / `remove_`
4. `encrypted_`
5. `dot_` / `literal_`
6. `run_` / `run_once_` / `run_onchange_` / `run_before_` / `run_after_`

## Common Combinations

### Private Encrypted SSH Key
```
encrypted_private_dot_ssh/encrypted_private_id_rsa.age
→ ~/.ssh/id_rsa (decrypted, chmod 600)
```

### Executable Script with Template
```
executable_dot_local/bin/backup.sh.tmpl
→ ~/.local/bin/backup.sh (processed template, chmod 755)
```

### Exact Directory with Dotfile
```
exact_dot_config/nvim/lua/plugins/
→ ~/.config/nvim/lua/plugins/ (exact sync, untracked files removed)
```

### Run Once Executable Script
```
run_once_executable_install-docker.sh
→ Runs once with execute permissions
```

### Run on Change with Template
```
run_onchange_install-packages.sh.tmpl
→ Runs when script or template variables change
```

### Private Readonly Config
```
private_readonly_dot_gnupg/gpg.conf
→ ~/.gnupg/gpg.conf (chmod 400)
```

### Encrypted Exact Directory
```
encrypted_exact_dot_ssh/
→ ~/.ssh/ (all files decrypted, exact sync)
```

## Special Files

### `.chezmoiignore`
Lists files/patterns to ignore (like `.gitignore`).

**Example**:
```
README.md
*.bak
{{ if ne .chezmoi.hostname "workstation" }}
.config/work-specific/
{{ end }}
```

### `.chezmoiremove`
Lists files to remove from target directory.

**Example**:
```
# Remove old config
.oldconfig
{{ if .personal }}
.config/work/
{{ end }}
```

### `.chezmoiexternal.toml`
Defines external dependencies (archives, files from URLs).

**Example**:
```toml
[".oh-my-zsh"]
    type = "archive"
    url = "https://github.com/ohmyzsh/ohmyzsh/archive/master.tar.gz"
    exact = true
    stripComponents = 1
    refreshPeriod = "168h"
```

### `.chezmoitemplates/`
Directory for reusable template fragments.

**Source**: `.chezmoitemplates/helpers.tmpl`
**Usage**: `{{ template "helpers.tmpl" }}`

### `.chezmoiscripts/`
Directory for reusable script fragments.

**Source**: `.chezmoiscripts/lib.sh`
**Usage**: Source from run scripts

### `.chezmoiversion`
Specifies minimum required chezmoi version.

**Example**:
```
2.30.0
```

## Machine-Specific Patterns

### Conditional Files Based on OS
```
dot_bashrc_{{ .chezmoi.os }}.tmpl
→ .bashrc_linux.tmpl or .bashrc_darwin.tmpl
```

### Hostname-Specific Configs
```
dot_config/app/config_{{ .chezmoi.hostname }}.yaml.tmpl
→ .config/app/config_workstation.yaml
```

### Architecture-Specific Binaries
```
bin/tool_{{ .chezmoi.os }}_{{ .chezmoi.arch }}
→ bin/tool_linux_amd64
```

## Escaping Underscores

To include a literal underscore in the target filename, use `_` in source:

**Source**: `dot_my_file`
**Target**: `.my_file`

For directories, underscores in names work normally:
**Source**: `dot_config/my_app/`
**Target**: `.config/my_app/`

## Hidden Prefixes

### `once_` (deprecated, use `run_once_`)
Kept for backward compatibility.

### `onchange_` (deprecated, use `run_onchange_`)
Kept for backward compatibility.

## Debugging File Names

Use `chezmoi source-path <target-path>` to find the source file:
```bash
chezmoi source-path ~/.config/nvim/init.lua
# Output: /path/to/source/dot_config/nvim/init.lua
```

Use `chezmoi target-path <source-path>` for reverse:
```bash
chezmoi target-path dot_gitconfig.tmpl
# Output: /home/user/.gitconfig
```

## Validation

Check if your file naming is correct:
```bash
chezmoi verify
```

Preview what files will be created:
```bash
chezmoi diff
chezmoi apply --dry-run --verbose
```

## Common Mistakes

### ❌ Wrong Order
```
dot_private_config  # Wrong: dot_ should come after private_
```
**Correct**: `private_dot_config`

### ❌ Missing Underscore
```
dotconfig  # Wrong: missing underscore
```
**Correct**: `dot_config`

### ❌ Wrong Suffix
```
file.template  # Wrong: should be .tmpl
```
**Correct**: `file.tmpl`

### ❌ Combining Incompatible Prefixes
```
symlink_modify_file  # Wrong: can't be both symlink and modify
```
**Pick one**: Either `symlink_` or `modify_`

## Best Practices

1. **Use `exact_` carefully** - it deletes untracked files
2. **Encrypt sensitive files** - always use `encrypted_private_` for keys
3. **Use templates for machine-specific configs** - add `.tmpl` suffix
4. **Use `run_onchange_` for package installs** - avoids re-running unnecessarily
5. **Order prefixes correctly** - follow the ordering rules
6. **Test with `diff` first** - always preview before applying
7. **Use descriptive script names** - include priority in run scripts (e.g., `run_after_10-restart.sh`)
