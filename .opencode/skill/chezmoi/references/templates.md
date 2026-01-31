# Chezmoi Templates Reference

Complete guide to Go template syntax and chezmoi-specific template features.

## Overview

Chezmoi uses Go's `text/template` syntax with additional functions. Any file with `.tmpl` suffix is processed as a template before being written to the target directory.

**Example**:
- Source: `dot_gitconfig.tmpl`
- Target: `~/.gitconfig` (template processed, `.tmpl` removed)

## Basic Template Syntax

### Variables: `{{ .variable }}`
Access data from `.chezmoi.toml.tmpl` or built-in variables.

```
Hello, {{ .name }}!
Your email is {{ .email }}
```

### Comments: `{{/* comment */}}`
Comments are removed from output.

```
{{/* This is a comment */}}
{{/* 
Multi-line
comment
*/}}
```

### Whitespace Control: `{{- -}}`
Remove whitespace before/after template actions.

```
{{- .name -}}     # Removes whitespace before and after
{{ .name -}}      # Removes whitespace after only
{{- .name }}      # Removes whitespace before only
```

## Chezmoi Built-in Variables

### `.chezmoi` Namespace

#### `.chezmoi.os`
Operating system (linux, darwin, windows, etc.).

```toml
{{ if eq .chezmoi.os "linux" }}
export PATH="$HOME/.local/bin:$PATH"
{{ else if eq .chezmoi.os "darwin" }}
export PATH="/opt/homebrew/bin:$PATH"
{{ end }}
```

#### `.chezmoi.osRelease`
OS release information (Linux only, from `/etc/os-release`).

```
{{ if hasKey .chezmoi.osRelease "id" }}
# Detected: {{ .chezmoi.osRelease.id }}
{{ if eq .chezmoi.osRelease.id "arch" }}
# Arch Linux specific config
{{ end }}
{{ end }}
```

#### `.chezmoi.arch`
Architecture (amd64, arm64, etc.).

```
{{ if eq .chezmoi.arch "amd64" }}
ARCH=x86_64
{{ else if eq .chezmoi.arch "arm64" }}
ARCH=aarch64
{{ end }}
```

#### `.chezmoi.hostname`
Machine hostname.

```yaml
{{ if eq .chezmoi.hostname "workstation" }}
theme: catppuccin-mocha
{{ else if eq .chezmoi.hostname "laptop" }}
theme: catppuccin-latte
{{ end }}
```

#### `.chezmoi.username`
Current username.

```
# User: {{ .chezmoi.username }}
HOME=/home/{{ .chezmoi.username }}
```

#### `.chezmoi.homeDir`
Home directory path.

```
DATA_DIR={{ .chezmoi.homeDir }}/.local/share/myapp
```

#### `.chezmoi.sourceDir`
Chezmoi source directory path.

```bash
# Source: {{ .chezmoi.sourceDir }}
```

#### `.chezmoi.version`
Chezmoi version.

```
# Managed by chezmoi {{ .chezmoi.version.version }}
```

#### `.chezmoi.group`
Primary group name.

```
chown {{ .chezmoi.username }}:{{ .chezmoi.group }} /path/to/file
```

#### `.chezmoi.gid`
Primary group ID.

```
GID={{ .chezmoi.gid }}
```

#### `.chezmoi.uid`
User ID.

```
UID={{ .chezmoi.uid }}
```

#### `.chezmoi.kernel`
Kernel information (Linux/Unix).

```
{{ if .chezmoi.kernel }}
# Kernel: {{ .chezmoi.kernel.osrelease }}
{{ end }}
```

#### `.chezmoi.fqdnHostname`
Fully qualified domain name.

```
FQDN={{ .chezmoi.fqdnHostname }}
```

### Environment Variables: `env` Function

Access environment variables with `env` function.

```bash
{{ if env "CI" }}
# Running in CI environment
{{ end }}

PATH={{ env "PATH" }}

{{ $editor := env "EDITOR" | default "vim" }}
EDITOR={{ $editor }}
```

## Custom Variables from `.chezmoi.toml.tmpl`

Define custom variables in `.chezmoi.toml.tmpl`:

```toml
[data]
    name = "John Doe"
    email = "john@example.com"
    
[data.theme]
    dark = true
    font = "JetBrains Mono"

[data.packages]
    [data.packages.pacman]
        cli = ["git", "vim", "tmux"]
        gui = ["firefox", "kitty"]
```

**Usage in templates**:
```yaml
user:
  name: {{ .name }}
  email: {{ .email }}

theme:
  dark_mode: {{ .theme.dark }}
  font: {{ .theme.font }}

packages:
{{ range .packages.pacman.cli }}
  - {{ . }}
{{ end }}
```

## Conditional Logic

### `if` / `else if` / `else`

```
{{ if eq .chezmoi.os "linux" }}
Linux configuration
{{ else if eq .chezmoi.os "darwin" }}
macOS configuration
{{ else }}
Other OS configuration
{{ end }}
```

### Comparison Operators

```
{{ if eq .var "value" }}equal{{ end }}
{{ if ne .var "value" }}not equal{{ end }}
{{ if lt .num 5 }}less than{{ end }}
{{ if le .num 5 }}less than or equal{{ end }}
{{ if gt .num 5 }}greater than{{ end }}
{{ if ge .num 5 }}greater than or equal{{ end }}
```

### Boolean Logic

```
{{ if and (eq .chezmoi.os "linux") (eq .theme.dark true) }}
Dark theme on Linux
{{ end }}

{{ if or (eq .chezmoi.hostname "laptop") (eq .chezmoi.hostname "desktop") }}
Personal machine
{{ end }}

{{ if not .production }}
Development settings
{{ end }}
```

### Check if Variable Exists

```
{{ if hasKey . "optional_var" }}
Value: {{ .optional_var }}
{{ else }}
Variable not set
{{ end }}
```

## Loops

### Range Over Array

```yaml
packages:
{{ range .packages.pacman.cli }}
  - {{ . }}
{{ end }}
```

**Output**:
```yaml
packages:
  - git
  - vim
  - tmux
```

### Range with Index

```
{{ range $index, $value := .packages.pacman.cli }}
{{ $index }}: {{ $value }}
{{ end }}
```

### Range Over Map

```
{{ range $key, $value := .theme }}
{{ $key }}: {{ $value }}
{{ end }}
```

### Range with Condition

```
{{ range .packages.pacman.cli }}
{{ if ne . "vim" }}
  - {{ . }}
{{ end }}
{{ end }}
```

## Variables

### Assign Variables: `:=`

```
{{ $name := .name }}
{{ $email := .email }}

[user]
    name = {{ $name }}
    email = {{ $email }}
```

### Reassign Variables: `=`

```
{{ $value := "initial" }}
{{ if .override }}
{{ $value = "overridden" }}
{{ end }}
Value: {{ $value }}
```

### Variable Scope

Variables are scoped to their block:

```
{{ $outer := "outer" }}

{{ if true }}
  {{ $inner := "inner" }}
  Outer: {{ $outer }}
  Inner: {{ $inner }}
{{ end }}

{{/* $inner not accessible here */}}
Outer: {{ $outer }}
```

## Functions

### String Functions

#### `lower` / `upper`
```
{{ .name | lower }}          # john doe
{{ .email | upper }}         # JOHN@EXAMPLE.COM
```

#### `title`
```
{{ "hello world" | title }}  # Hello World
```

#### `trim` / `trimPrefix` / `trimSuffix`
```
{{ "  hello  " | trim }}                    # "hello"
{{ "hello-world" | trimPrefix "hello-" }}   # "world"
{{ "hello-world" | trimSuffix "-world" }}   # "hello"
```

#### `replace`
```
{{ .path | replace "/" "-" }}   # Replace / with -
```

#### `split` / `join`
```
{{ $parts := split .path "/" }}
{{ join $parts "-" }}
```

#### `contains` / `hasPrefix` / `hasSuffix`
```
{{ if contains .email "@" }}Valid email{{ end }}
{{ if hasPrefix .path "/" }}Absolute path{{ end }}
{{ if hasSuffix .file ".txt" }}Text file{{ end }}
```

### List Functions

#### `list`
Create a list:
```
{{ $mylist := list "a" "b" "c" }}
```

#### `append`
```
{{ $list := list "a" "b" }}
{{ $list = append $list "c" }}
```

#### `concat`
```
{{ $list1 := list "a" "b" }}
{{ $list2 := list "c" "d" }}
{{ $combined := concat $list1 $list2 }}
```

#### `first` / `rest`
```
{{ $first := first .packages.pacman.cli }}    # First item
{{ $rest := rest .packages.pacman.cli }}      # All except first
```

#### `has`
```
{{ if has "vim" .packages.pacman.cli }}
Vim is installed
{{ end }}
```

### Dictionary Functions

#### `dict`
Create a dictionary:
```
{{ $mydict := dict "key1" "value1" "key2" "value2" }}
```

#### `get`
```
{{ $value := get $mydict "key1" }}
```

#### `set`
```
{{ $dict := dict }}
{{ $dict = set $dict "newkey" "newvalue" }}
```

#### `hasKey`
```
{{ if hasKey $dict "key1" }}
Key exists
{{ end }}
```

#### `keys` / `values`
```
{{ range keys $dict }}
Key: {{ . }}
{{ end }}

{{ range values $dict }}
Value: {{ . }}
{{ end }}
```

### Default Values

#### `default`
Provide default if value is empty/nil:
```
{{ $editor := env "EDITOR" | default "vim" }}
{{ $theme := .theme | default "dark" }}
```

### Type Conversions

#### `toString`
```
{{ .number | toString }}
```

#### `toJson` / `toPrettyJson`
```
{{ .data | toJson }}
{{ .data | toPrettyJson }}
```

#### `toYaml`
```
{{ .data | toYaml }}
```

#### `toToml`
```
{{ .data | toToml }}
```

### File Functions

#### `include`
Include another template file from `.chezmoitemplates/`:

```
{{ include "header.tmpl" }}
```

#### `includeTemplate`
Include and process template:

```
{{ includeTemplate "config.tmpl" . }}
```

### Chezmoi-Specific Functions

#### `output`
Run command and capture output:

```bash
{{ $hostname := output "hostname" }}
# Host: {{ $hostname }}
```

#### `lookPath`
Find executable in PATH:

```
{{ if lookPath "nvim" }}
export EDITOR=nvim
{{ else if lookPath "vim" }}
export EDITOR=vim
{{ end }}
```

#### `stat`
Get file information:

```
{{ $file := stat "/etc/os-release" }}
{{ if $file }}
File size: {{ $file.size }}
{{ end }}
```

#### `joinPath`
Join path components:

```
{{ $configDir := joinPath .chezmoi.homeDir ".config" "myapp" }}
CONFIG_DIR={{ $configDir }}
```

#### `promptBool` / `promptString` / `promptInt`
Prompt user for input (interactive):

```toml
{{ $personal := promptBool "Is this a personal machine" }}
[data]
    personal = {{ $personal }}

{{ $email := promptString "Email address" }}
    email = "{{ $email }}"
```

#### `onepassword` / `onepasswordRead`
Read from 1Password:

```
{{ onepassword "item-id" }}
{{ onepasswordRead "op://vault/item/field" }}
```

#### `bitwarden` / `bitwardenFields`
Read from Bitwarden:

```
{{ bitwarden "item-id" }}
{{ bitwardenFields "item-id" }}
```

#### `keepassxc` / `keepassxcAttribute`
Read from KeePassXC:

```
{{ keepassxc "entry-name" }}
{{ keepassxcAttribute "entry-name" "password" }}
```

#### `vault`
Read from HashiCorp Vault:

```
{{ vault "secret/path" }}
```

## Escaping Nested Templates

When files contain template syntax (e.g., mise, Jinja2), use `{{` `"{{" }}` patterns:

**For mise config** (`.mise.toml.tmpl`):
```toml
[env]
# Chezmoi template (processed)
USER = "{{ .chezmoi.username }}"

# Mise template (literal, not processed by chezmoi)
PATH = "{{ "{{" }} config_root {{ "}}" }}/bin:$PATH"
```

**For Jinja2 templates**:
```jinja
{# Chezmoi processes this #}
user: {{ .ansible_user }}

{# Jinja2 will process this (escaped from chezmoi) #}
hostname: {{ "{{" }} inventory_hostname {{ "}}" }}
```

## Template Debugging

### Print Variables

```
DEBUG: {{ . | toPrettyJson }}
DEBUG chezmoi: {{ .chezmoi | toPrettyJson }}
DEBUG custom: {{ .packages | toPrettyJson }}
```

### Dry Run

Test template rendering:
```bash
chezmoi execute-template '{{ .chezmoi.os }}'
chezmoi execute-template < template.tmpl
```

### Check Template Syntax

```bash
chezmoi diff
chezmoi apply --dry-run --verbose
```

## Common Patterns

### OS-Specific Configuration

```conf
{{ if eq .chezmoi.os "linux" }}
# Linux specific
TERMINAL=kitty
{{ else if eq .chezmoi.os "darwin" }}
# macOS specific
TERMINAL=iTerm
{{ end }}
```

### Multi-Machine Setup

```yaml
{{ if eq .chezmoi.hostname "workstation" }}
monitor_setup: triple
dpi: 144
{{ else if eq .chezmoi.hostname "laptop" }}
monitor_setup: single
dpi: 96
{{ end }}
```

### Environment-Specific Settings

```toml
{{ if .work }}
[work]
    vpn = true
    proxy = "http://proxy.corp.com:8080"
{{ else }}
[personal]
    vpn = false
{{ end }}
```

### Package Lists with Conditions

```bash
{{ range .packages.pacman.cli }}
pacman -S --needed {{ . }}
{{ end }}

{{ if .theme.dark }}
pacman -S --needed dark-theme
{{ end }}
```

### Dynamic File Inclusion

```
{{ if stat (joinPath .chezmoi.sourceDir ".chezmoitemplates/work.tmpl") }}
{{ include "work.tmpl" }}
{{ end }}
```

### SSH Config with Multiple Hosts

```
{{ range .ssh_hosts }}
Host {{ .name }}
    HostName {{ .hostname }}
    User {{ .user }}
    {{ if .port }}Port {{ .port }}{{ end }}
{{ end }}
```

**Data in `.chezmoi.toml.tmpl`**:
```toml
[[data.ssh_hosts]]
    name = "server1"
    hostname = "192.168.1.10"
    user = "admin"

[[data.ssh_hosts]]
    name = "server2"
    hostname = "192.168.1.20"
    user = "admin"
    port = 2222
```

### Git Config with Conditional Includes

```gitconfig
[user]
    name = {{ .name }}
    email = {{ .email }}

{{ if .work }}
[includeIf "gitdir:~/work/"]
    path = ~/.gitconfig-work
{{ end }}
```

## Best Practices

1. **Use `.chezmoi.toml.tmpl` for data** - Keep templates clean, data separate
2. **Test with `execute-template`** - Verify output before applying
3. **Escape nested templates** - Use `{{ "{{" }}` pattern for non-chezmoi templates
4. **Use whitespace control** - Keep output clean with `{{-` and `-}}`
5. **Validate with `diff`** - Always preview before applying
6. **Comment complex logic** - Use `{{/* comments */}}` to explain
7. **Use defaults** - Provide fallback values with `default` function
8. **Check file existence** - Use `stat` before including files
9. **Keep templates simple** - Complex logic should be in scripts
10. **Use template fragments** - Store reusable parts in `.chezmoitemplates/`

## Common Mistakes

### ❌ Missing Dot in Variables
```
{{ chezmoi.os }}          # Wrong
{{ .chezmoi.os }}         # Correct
```

### ❌ Wrong Quote Style in Templates
```
{{ if eq .os 'linux' }}   # Wrong: single quotes
{{ if eq .os "linux" }}   # Correct: double quotes
```

### ❌ Not Escaping Nested Templates
```
PATH={{ config_root }}/bin     # Wrong: chezmoi will fail
PATH={{ "{{" }} config_root {{ "}}" }}/bin    # Correct
```

### ❌ Forgetting `.tmpl` Suffix
If file has template syntax, it needs `.tmpl` suffix or chezmoi won't process it.

### ❌ Using Undefined Variables
Always check with `hasKey` before using optional variables:
```
{{ if hasKey . "optional" }}{{ .optional }}{{ end }}
```
