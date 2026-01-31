# Chezmoi External Dependencies Reference

Complete guide to managing external dependencies with `.chezmoiexternal.toml`.

## Overview

`.chezmoiexternal.toml` allows chezmoi to download and manage files from external sources (archives, git repos, files from URLs). This is useful for:

- Installing oh-my-zsh, vim plugins, themes
- Downloading fonts, binaries, configuration files
- Managing external tools and dependencies
- Keeping external resources in sync

**Location**: `.chezmoiexternal.toml` in source directory

## File Format

`.chezmoiexternal.toml` uses TOML format with sections for each external resource:

```toml
[target-path]
    type = "archive" | "file" | "archive-file"
    url = "https://example.com/resource"
    # Additional options...
```

## Basic Examples

### Download Single File

```toml
[".local/bin/kubectl"]
    type = "file"
    url = "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl"
    executable = true
    refreshPeriod = "168h"  # Refresh weekly
```

**Result**: Downloads kubectl to `~/.local/bin/kubectl` with execute permissions.

### Extract Archive

```toml
[".oh-my-zsh"]
    type = "archive"
    url = "https://github.com/ohmyzsh/ohmyzsh/archive/master.tar.gz"
    exact = true
    stripComponents = 1
    refreshPeriod = "168h"
```

**Result**: Downloads, extracts to `~/.oh-my-zsh`, removes top-level directory.

### Extract Specific File from Archive

```toml
[".local/bin/docker-compose"]
    type = "archive-file"
    url = "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-linux-x86_64.tar.gz"
    path = "docker-compose"
    executable = true
```

**Result**: Extracts only `docker-compose` binary from archive.

## Field Reference

### `type` (required)

Specifies resource type:

- **`"file"`**: Single file download
- **`"archive"`**: Archive (tar.gz, zip) to extract
- **`"archive-file"`**: Single file from archive

### `url` (required)

URL to download from. Supports:
- HTTP/HTTPS
- GitHub release shortcuts (see GitHub functions)

```toml
url = "https://example.com/file.tar.gz"
url = "{{ gitHubLatestRelease \"user/repo\" }}"
```

### `executable`

Make downloaded file executable (chmod +x).

```toml
[".local/bin/script"]
    type = "file"
    url = "https://example.com/script.sh"
    executable = true
```

### `exact`

For archives: remove files in target that aren't in archive (like `exact_` prefix).

```toml
[".oh-my-zsh"]
    type = "archive"
    url = "https://..."
    exact = true  # Remove untracked files
```

**Warning**: Use carefully, deletes files not in archive.

### `stripComponents`

For archives: remove leading path components (like tar `--strip-components`).

```toml
[".oh-my-zsh"]
    type = "archive"
    url = "https://github.com/ohmyzsh/ohmyzsh/archive/master.tar.gz"
    stripComponents = 1  # Remove top-level "ohmyzsh-master" directory
```

### `path`

For `archive-file`: path to specific file within archive.

```toml
[".local/bin/binary"]
    type = "archive-file"
    url = "https://example.com/release.tar.gz"
    path = "bin/binary"  # Extract only this file
```

### `refreshPeriod`

How often to check for updates (Go duration format).

```toml
refreshPeriod = "168h"    # 1 week
refreshPeriod = "24h"     # 1 day
refreshPeriod = "720h"    # 30 days
refreshPeriod = "0"       # Never refresh (download once)
```

**Units**: `h` (hours), `m` (minutes), `s` (seconds)

**Default**: Never refresh (download once)

### `include` / `exclude`

Filter files when extracting archives (glob patterns).

```toml
[".fonts"]
    type = "archive"
    url = "https://example.com/fonts.zip"
    include = ["*.ttf", "*.otf"]       # Only font files
    exclude = ["*-Bold.ttf"]           # Except bold variants
```

### `filter`

Command to filter/transform file content (receives data on stdin, outputs to stdout).

```toml
[".config/app/config.json"]
    type = "file"
    url = "https://example.com/config.json"
    filter.command = "jq"
    filter.args = [".settings"]  # Extract .settings field
```

### `checksum`

Verify downloaded file integrity (SHA256 hex string).

```toml
[".local/bin/tool"]
    type = "file"
    url = "https://example.com/tool"
    checksum.sha256 = "abcdef1234567890..."
```

**Generate checksum**:
```bash
sha256sum file
```

### Template Support

External files can use templates (`.chezmoiexternal.toml.tmpl`):

```toml
{{ if eq .chezmoi.os "linux" }}
[".local/bin/kubectl"]
    type = "file"
    url = "https://dl.k8s.io/release/v1.28.0/bin/linux/{{ .chezmoi.arch }}/kubectl"
    executable = true
{{ else if eq .chezmoi.os "darwin" }}
[".local/bin/kubectl"]
    type = "file"
    url = "https://dl.k8s.io/release/v1.28.0/bin/darwin/{{ .chezmoi.arch }}/kubectl"
    executable = true
{{ end }}
```

## GitHub Functions

Chezmoi provides template functions for GitHub releases:

### `gitHubLatestRelease`

Get latest release version:

```toml
[".local/bin/tool"]
    type = "file"
    url = "https://github.com/user/repo/releases/download/{{ gitHubLatestRelease \"user/repo\" }}/tool-linux-amd64"
    executable = true
```

### `gitHubLatestTag`

Get latest git tag:

```toml
url = "https://github.com/user/repo/archive/{{ gitHubLatestTag \"user/repo\" }}.tar.gz"
```

### `gitHubReleases`

Get list of releases:

```toml
{{ $releases := gitHubReleases "user/repo" }}
{{ $latest := index $releases 0 }}
url = "{{ $latest.url }}"
```

## Common Patterns

### Install Oh My Zsh

```toml
[".oh-my-zsh"]
    type = "archive"
    url = "https://github.com/ohmyzsh/ohmyzsh/archive/master.tar.gz"
    exact = true
    stripComponents = 1
    refreshPeriod = "168h"
```

### Install Vim Plugin Manager

```toml
[".vim/autoload/plug.vim"]
    type = "file"
    url = "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
    refreshPeriod = "168h"
```

### Download Font

```toml
[".local/share/fonts/JetBrainsMono"]
    type = "archive"
    url = "https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip"
    exact = true
    include = ["fonts/ttf/*.ttf"]
    stripComponents = 1
    refreshPeriod = "720h"  # 30 days
```

### Install Binary from GitHub Releases

```toml
{{ $arch := .chezmoi.arch }}
{{ if eq $arch "amd64" }}{{ $arch = "x86_64" }}{{ end }}

[".local/bin/gh"]
    type = "archive-file"
    url = "https://github.com/cli/cli/releases/download/{{ gitHubLatestRelease \"cli/cli\" }}/gh_{{ gitHubLatestRelease \"cli/cli\" | trimPrefix \"v\" }}_linux_{{ $arch }}.tar.gz"
    path = "gh_*/bin/gh"
    executable = true
    refreshPeriod = "168h"
```

### Install Multiple Binaries from Same Archive

```toml
{{ $version := "1.28.0" }}
{{ $baseUrl := printf "https://dl.k8s.io/release/v%s/bin/linux/amd64/" $version }}

[".local/bin/kubectl"]
    type = "file"
    url = "{{ $baseUrl }}kubectl"
    executable = true

[".local/bin/kubeadm"]
    type = "file"
    url = "{{ $baseUrl }}kubeadm"
    executable = true
```

### OS-Specific Downloads

```toml
{{ if eq .chezmoi.os "linux" }}
[".local/bin/docker-compose"]
    type = "file"
    url = "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-linux-x86_64"
    executable = true
{{ else if eq .chezmoi.os "darwin" }}
[".local/bin/docker-compose"]
    type = "file"
    url = "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-darwin-{{ .chezmoi.arch }}"
    executable = true
{{ end }}
```

### Download and Transform JSON Config

```toml
[".config/app/settings.json"]
    type = "file"
    url = "https://example.com/default-config.json"
    filter.command = "jq"
    filter.args = [
        "--arg", "user", "{{ .chezmoi.username }}",
        '.user = $user'
    ]
```

### Conditional External Dependencies

```toml
{{ if .development }}
[".local/bin/dev-tool"]
    type = "file"
    url = "https://example.com/dev-tool"
    executable = true
{{ end }}
```

### Version-Specific Downloads

```toml
{{ $nodeVersion := "v20.10.0" }}

[".local/lib/node"]
    type = "archive"
    url = "https://nodejs.org/dist/{{ $nodeVersion }}/node-{{ $nodeVersion }}-linux-x64.tar.gz"
    stripComponents = 1
    exact = true
    include = ["bin/*", "lib/*"]
```

## Refresh Externals

### Manual Refresh

Force refresh external dependencies:

```bash
# Refresh all externals
chezmoi apply --refresh-externals

# Force refresh (ignore refreshPeriod)
chezmoi apply --refresh-externals --force
```

### Check Refresh Status

```bash
# Preview what would be refreshed
chezmoi diff --refresh-externals

# Dry run
chezmoi apply --refresh-externals --dry-run --verbose
```

### Automatic Refresh

Externals automatically refresh when:
1. `refreshPeriod` has elapsed since last check
2. Running `chezmoi apply --refresh-externals`
3. URL or configuration changes

## Advanced Patterns

### Multi-Platform Binary

```toml
{{ $os := .chezmoi.os }}
{{ $arch := .chezmoi.arch }}
{{ if eq $os "darwin" }}{{ $os = "macOS" }}{{ end }}
{{ if eq $arch "amd64" }}{{ $arch = "x86_64" }}{{ end }}

[".local/bin/tool"]
    type = "file"
    url = "https://example.com/releases/tool-{{ $os }}-{{ $arch }}"
    executable = true
```

### Nested Archives

For tools distributed as `.tar.gz` inside `.zip`:

```toml
# First: Download outer archive
[".cache/tool.zip"]
    type = "file"
    url = "https://example.com/tool.zip"

# Then: Use run_once script to extract nested archive
# run_once_extract-tool.sh
```

### Custom Extraction with Script

For complex cases, combine external download + script:

```toml
# Download archive
[".cache/complex-tool.tar.gz"]
    type = "file"
    url = "https://example.com/tool.tar.gz"
```

```bash
# run_once_install-complex-tool.sh
tar -xzf ~/.cache/complex-tool.tar.gz -C ~/.local/ --transform 's/^tool-v1.0/tool/'
```

### Conditional Include Based on Machine

```toml
{{ $include := list "*.ttf" }}
{{ if .highDpi }}
{{ $include = append $include "*.otf" }}
{{ end }}

[".local/share/fonts/CustomFont"]
    type = "archive"
    url = "https://example.com/fonts.zip"
    include = {{ $include | toJson }}
```

## Performance Optimization

### Reduce Refresh Frequency

For stable dependencies:
```toml
refreshPeriod = "720h"  # 30 days
```

For rapidly changing dependencies:
```toml
refreshPeriod = "24h"  # Daily
```

### Skip Externals for Quick Apply

```bash
# Apply without checking/refreshing externals
chezmoi apply --exclude=externals
```

### Cache Downloaded Files

Chezmoi caches downloaded files in:
```
~/.cache/chezmoi/
```

Clear cache if needed:
```bash
rm -rf ~/.cache/chezmoi/
```

## Security Considerations

### Verify Checksums

Always use checksums for security-critical downloads:

```toml
[".local/bin/kubectl"]
    type = "file"
    url = "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl"
    executable = true
    checksum.sha256 = "13a...."
```

### HTTPS Only

Only use HTTPS URLs:
```toml
url = "https://example.com/file"  # ✅ Secure
url = "http://example.com/file"   # ❌ Insecure
```

### Trusted Sources

Download only from trusted sources:
- Official GitHub releases
- Official project websites
- Verified package repositories

### Review Before Apply

Always review external downloads:
```bash
chezmoi diff --refresh-externals
```

## Troubleshooting

### External Not Downloaded

**Issue**: File not appearing after `chezmoi apply`

**Solutions**:
```bash
# Force refresh
chezmoi apply --refresh-externals --force

# Check for errors
chezmoi apply --verbose

# Verify URL is accessible
curl -I "URL_FROM_TOML"
```

### Archive Extraction Fails

**Issue**: `stripComponents` incorrect or path mismatch

**Solution**:
```bash
# Download manually and inspect structure
curl -L "URL" -o /tmp/test.tar.gz
tar -tzf /tmp/test.tar.gz | head

# Adjust stripComponents based on output
```

### Permission Denied

**Issue**: Downloaded file not executable

**Solution**: Add `executable = true`

```toml
[".local/bin/tool"]
    type = "file"
    url = "..."
    executable = true  # Add this
```

### GitHub Rate Limiting

**Issue**: Too many requests to GitHub API

**Solution**: Set GITHUB_TOKEN:
```bash
export GITHUB_TOKEN="ghp_..."
chezmoi apply --refresh-externals
```

### Wrong Architecture

**Issue**: Downloaded binary for wrong architecture

**Solution**: Use template to detect architecture:
```toml
{{ $arch := .chezmoi.arch }}
{{ if eq $arch "amd64" }}{{ $arch = "x86_64" }}{{ end }}

url = "https://example.com/tool-linux-{{ $arch }}"
```

## Best Practices

1. **Use `refreshPeriod`** - Avoid unnecessary downloads
2. **Verify with checksums** - For security-critical binaries
3. **Use GitHub functions** - For latest releases
4. **Template for multi-platform** - Support different OS/architectures
5. **Preview with `diff`** - Always check before applying
6. **Exact for themes/plugins** - Keep external directories clean
7. **Include only needed files** - Reduce download size
8. **Test extraction manually** - Verify archive structure first
9. **Use HTTPS** - Never plain HTTP for downloads
10. **Document sources** - Comment complex external configs

## See Also

- [File Naming Reference](file-naming.md) - External file naming conventions
- [Templates Reference](templates.md) - Using templates in .chezmoiexternal.toml
- [Scripts Reference](scripts.md) - Combining externals with scripts
- [Troubleshooting](troubleshooting.md) - Common external dependency errors
