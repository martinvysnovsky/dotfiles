# Chezmoi Troubleshooting Reference

Common errors, issues, and solutions when working with chezmoi.

## General Debugging

### Enable Verbose Output

```bash
# See detailed operations
chezmoi apply --verbose

# Very verbose (debug level)
chezmoi apply -v -v

# Dry run to preview
chezmoi apply --dry-run --verbose
```

### Check State

```bash
# View current state
chezmoi state dump

# View specific bucket
chezmoi state get --bucket=scriptState
```

### Verify Repository

```bash
# Check for issues
chezmoi verify

# Doctor command (diagnostic info)
chezmoi doctor
```

## Template Errors

### Error: `template: ... unexpected "{{"`

**Cause**: Template syntax error or unescaped nested templates

**Example**:
```
ERROR template: .bashrc.tmpl:10: unexpected "{{" in operand
```

**Solution**: Escape nested templates (e.g., for mise, Jinja2):

```bash
# ❌ Wrong
PATH={{ config_root }}/bin

# ✅ Correct
PATH={{ "{{" }} config_root {{ "}}" }}/bin
```

### Error: `template: ... undefined variable`

**Cause**: Using variable that doesn't exist in `.chezmoi.toml.tmpl`

**Example**:
```
ERROR template: .gitconfig.tmpl:3: executing ".gitconfig.tmpl" at <.git_name>: undefined variable "git_name"
```

**Solution**: Define variable or use `hasKey` check:

```toml
# .chezmoi.toml.tmpl
[data]
    git_name = "Your Name"
```

Or:
```
{{ if hasKey . "git_name" }}
name = {{ .git_name }}
{{ end }}
```

### Error: `wrong type for value; expected string; got bool`

**Cause**: Trying to output boolean/number directly in template

**Example**:
```bash
DEBUG={{ .debug }}  # .debug is boolean
```

**Solution**: Convert to string:

```bash
DEBUG={{ .debug | toString }}
```

### Template Produces Wrong Output

**Debugging**:
```bash
# Test template rendering
chezmoi execute-template '{{ .chezmoi.os }}'

# Test specific file
chezmoi cat ~/.gitconfig

# Dump all data
chezmoi execute-template '{{ . | toPrettyJson }}'
```

## File Naming Errors

### Error: `invalid source state entry name`

**Cause**: Incorrect prefix order or invalid combination

**Example**:
```
ERROR invalid source state entry name "dot_private_config"
```

**Solution**: Fix prefix order (private_ before dot_):

```
# ❌ Wrong
dot_private_config

# ✅ Correct
private_dot_config
```

### File Not Applied

**Cause**: Missing `dot_` prefix or `.tmpl` suffix

**Debugging**:
```bash
# Check what chezmoi sees
chezmoi source-path ~/.config/nvim/init.lua

# If shows nothing, file naming is wrong
```

**Solution**: Verify naming:
```
~/.config/nvim/init.lua → dot_config/nvim/init.lua
```

### Permissions Wrong

**Cause**: Missing `private_`, `readonly_`, or `executable_` prefix

**Solution**: Add appropriate prefix:

```bash
# For private files (chmod 600)
private_dot_ssh/private_id_rsa

# For executables (chmod 755)
executable_dot_local/bin/script.sh

# For readonly (chmod 444)
readonly_dot_config/immutable.conf
```

## Encryption Errors

### Error: `gpg: decryption failed: No secret key`

**Cause**: GPG private key not available

**Solution**:
```bash
# Import private key
gpg --import private-key.asc

# Verify key exists
gpg --list-secret-keys

# Trust key
gpg --edit-key KEY_ID
# Type: trust, then 5 (ultimate), then quit
```

### Error: `age: error: identity file not found`

**Cause**: age identity file doesn't exist or wrong path

**Solution**:
```bash
# Create identity file
mkdir -p ~/.config/age
age-keygen -o ~/.config/age/key.txt

# Verify path in .chezmoi.toml.tmpl
[age]
    identity = "~/.config/age/key.txt"
```

### Encrypted File Shows as Plaintext

**Cause**: File not actually encrypted

**Verification**:
```bash
# Check file type
file ~/.local/share/chezmoi/encrypted_private_dot_ssh/encrypted_private_id_rsa

# Should show: GPG encrypted data
# NOT: ASCII text or OpenSSH private key
```

**Solution**: Re-encrypt file:
```bash
chezmoi forget ~/.ssh/id_rsa
chezmoi add --encrypt ~/.ssh/id_rsa
```

### Error: `gpg: public key decryption failed: Bad passphrase`

**Cause**: Incorrect GPG passphrase or key not unlocked

**Solution**:
```bash
# Unlock key manually
echo "test" | gpg --encrypt --recipient YOUR_KEY_ID | gpg --decrypt

# Restart GPG agent
gpgconf --kill gpg-agent
gpgconf --launch gpg-agent

# Try again
chezmoi apply
```

## Script Errors

### Script Doesn't Execute

**Cause 1**: Missing shebang

**Solution**: Add shebang:
```bash
#!/bin/bash
# run_script.sh
```

**Cause 2**: Not executable (for `run_` scripts without `executable_` prefix)

**Solution**: Add `executable_` prefix or make file executable in source:
```bash
chmod +x ~/.local/share/chezmoi/run_script.sh
```

### Script Runs Every Time (Should Run Once)

**Cause**: Using `run_` instead of `run_once_`

**Solution**: Rename script:
```bash
# Move/rename file
mv run_install.sh run_once_install.sh

# Or add comment to change hash (for run_onchange_)
# Updated: 2025-01-31
```

### Script Doesn't Re-run After Changes

**Cause**: Using `run_once_` for script that should detect changes

**Solution**: Use `run_onchange_` and optionally `.tmpl`:
```bash
# Rename
mv run_once_install-packages.sh run_onchange_install-packages.sh.tmpl
```

### Error: `script failed with exit status 1`

**Cause**: Script returned non-zero exit code

**Debugging**:
```bash
# Run script directly
bash ~/.local/share/chezmoi/run_script.sh

# Check script with debug
bash -x ~/.local/share/chezmoi/run_script.sh
```

**Solution**: Fix script errors or add error handling:
```bash
#!/bin/bash
set -e  # Exit on error

# Or handle errors explicitly
if ! command; then
    echo "Error: command failed" >&2
    exit 1
fi
```

## External Dependencies Errors

### External File Not Downloaded

**Cause**: Never ran with `--refresh-externals`

**Solution**:
```bash
chezmoi apply --refresh-externals
```

### Error: `archive extraction failed`

**Cause**: Wrong `stripComponents` value or invalid archive

**Debugging**:
```bash
# Download archive manually
curl -L "URL_FROM_TOML" -o /tmp/test.tar.gz

# Inspect structure
tar -tzf /tmp/test.tar.gz | head -20

# Check top-level directories
tar -tzf /tmp/test.tar.gz | cut -d/ -f1 | sort -u
```

**Solution**: Adjust `stripComponents`:
```toml
stripComponents = 1  # Increase/decrease based on archive structure
```

### Error: `checksum mismatch`

**Cause**: Downloaded file doesn't match expected checksum

**Solution 1**: Update checksum to actual value:
```bash
# Download file
curl -L "URL" -o /tmp/file

# Get actual checksum
sha256sum /tmp/file

# Update .chezmoiexternal.toml
checksum.sha256 = "NEW_HASH"
```

**Solution 2**: Remove checksum validation (less secure):
```toml
# Remove checksum line
# checksum.sha256 = "..."
```

### GitHub Rate Limit

**Error**: `API rate limit exceeded`

**Solution**: Add GitHub token:
```bash
export GITHUB_TOKEN="ghp_YOUR_TOKEN"
chezmoi apply --refresh-externals
```

## Git Integration Errors

### Error: `dirty working tree`

**Cause**: Uncommitted changes when using auto-commit

**Solution**:
```bash
# Commit changes
cd ~/.local/share/chezmoi
git add .
git commit -m "Update dotfiles"

# Or disable auto-commit temporarily
chezmoi apply --no-auto-commit
```

### Error: `failed to push`

**Cause**: Auto-push enabled but remote not configured or rejected

**Solution**:
```bash
# Check remote
cd ~/.local/share/chezmoi
git remote -v

# Configure remote if missing
git remote add origin git@github.com:user/dotfiles.git

# Or disable auto-push
# In .chezmoi.toml.tmpl
[git]
    autoPush = false
```

### Merge Conflicts

**Cause**: Local and remote changes conflict

**Solution**:
```bash
cd ~/.local/share/chezmoi

# Pull with rebase
git pull --rebase

# Resolve conflicts
git status
# Edit conflicting files
git add .
git rebase --continue

# Or abort rebase
git rebase --abort
```

## Performance Issues

### `chezmoi apply` is Slow

**Cause 1**: Many external dependencies refreshing

**Solution**: Skip externals:
```bash
chezmoi apply --exclude=externals
```

**Cause 2**: Large number of files

**Solution**: Apply specific files/directories:
```bash
chezmoi apply ~/.config/nvim
```

**Cause 3**: Slow scripts

**Debugging**:
```bash
# Run with timing
time chezmoi apply --verbose

# Identify slow scripts from output
```

**Solution**: Optimize scripts, use `run_onchange_` instead of `run_`

### State Database Corruption

**Error**: `database corruption detected`

**Solution**:
```bash
# Backup state
cp ~/.local/share/chezmoi/.chezmoistate.boltdb ~/.chezmoistate.boltdb.backup

# Delete state (will lose run_once/run_onchange tracking)
rm ~/.local/share/chezmoi/.chezmoistate.boltdb

# Re-apply
chezmoi apply
```

## Common Workflow Issues

### Changes Not Showing in `chezmoi diff`

**Cause**: File not managed by chezmoi

**Verification**:
```bash
# Check if file is managed
chezmoi managed | grep filename

# Check source path
chezmoi source-path ~/.config/nvim/init.lua
```

**Solution**: Add file to chezmoi:
```bash
chezmoi add ~/.config/nvim/init.lua
```

### `chezmoi apply` Changes Wrong Files

**Cause**: Unexpected template evaluation or wrong file naming

**Prevention**: Always preview first:
```bash
chezmoi diff
chezmoi apply --dry-run --verbose
```

### Can't Edit Managed File

**Issue**: Edit made to target file disappears after `chezmoi apply`

**Solution**: Edit source file instead:
```bash
# Don't edit ~/.config/nvim/init.lua
# Edit source:
chezmoi edit ~/.config/nvim/init.lua

# Or edit directly:
$EDITOR ~/.local/share/chezmoi/dot_config/nvim/init.lua
```

### Accidentally Deleted File

**Recovery**:
```bash
# Re-apply specific file
chezmoi apply ~/.config/nvim/init.lua

# Or re-apply everything
chezmoi apply
```

## Platform-Specific Issues

### Linux: Permission Denied

**Cause**: Trying to write to protected directory

**Solution**: Use user-writable locations:
```bash
# Use ~/.local instead of /usr/local
~/.local/bin/tool
~/.local/share/applications/
```

### macOS: `operation not permitted`

**Cause**: System Integrity Protection (SIP)

**Solution**: Don't manage system-protected files:
```
# .chezmoiignore
/System/*
/Library/System/*
```

### Windows: Path Separators

**Cause**: Using `/` in templates on Windows

**Solution**: Use `joinPath`:
```
{{ joinPath .chezmoi.homeDir ".config" "app" }}
```

## Getting Help

### Collect Diagnostic Info

```bash
# Run doctor
chezmoi doctor

# Shows:
# - Chezmoi version
# - Configuration
# - Source directory
# - Destination directory
# - Encryption method
# - Git status
```

### Enable Debug Logging

```bash
# Maximum verbosity
chezmoi apply -v -v

# With stack traces
CHEZMOI_DEBUG=1 chezmoi apply --verbose
```

### File an Issue

When reporting bugs, include:

```bash
# 1. Chezmoi version
chezmoi --version

# 2. Operating system
uname -a

# 3. Configuration (redact sensitive info)
cat ~/.config/chezmoi/chezmoi.toml

# 4. Relevant source file names (not content)
ls -la ~/.local/share/chezmoi/

# 5. Error output
chezmoi apply --verbose 2>&1 | tee chezmoi-error.log
```

## Prevention Best Practices

1. **Always preview**: Use `chezmoi diff` before `apply`
2. **Test in VM**: Test major changes in virtual machine first
3. **Backup first**: Keep backup of important configs
4. **Small commits**: Make incremental changes, not large refactors
5. **Use dry run**: Test with `--dry-run --verbose`
6. **Validate syntax**: Check templates with `execute-template`
7. **Check git status**: Ensure clean state before major operations
8. **Document changes**: Add comments to complex templates/scripts
9. **Version control**: Commit frequently to recover from mistakes
10. **Read errors carefully**: Error messages usually explain the issue

## Quick Reference: Common Fixes

| Issue | Quick Fix |
|-------|-----------|
| Template error | `chezmoi execute-template < file.tmpl` |
| File not applied | Check naming: `dot_` prefix, `.tmpl` suffix |
| Script won't run | Add `#!/bin/bash` shebang |
| Permission wrong | Add `private_`, `readonly_`, or `executable_` prefix |
| GPG error | Check key: `gpg --list-secret-keys` |
| External not downloaded | Run with `--refresh-externals` |
| State issues | Reset: `chezmoi state delete-bucket --bucket=scriptState` |
| Slow apply | Skip externals: `--exclude=externals` |
| Git conflict | `cd source && git pull --rebase` |
| Wrong file changed | Preview first: `chezmoi diff` |

## See Also

- [File Naming Reference](file-naming.md) - Correct file naming conventions
- [Templates Reference](templates.md) - Template syntax and functions
- [Scripts Reference](scripts.md) - Script execution and debugging
- [Encryption Reference](encryption.md) - Encryption setup and issues
- [External Dependencies Reference](external-deps.md) - External file management
