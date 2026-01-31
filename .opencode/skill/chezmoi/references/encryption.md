# Chezmoi Encryption Reference

Complete guide to encrypting sensitive files in chezmoi using GPG and age encryption.

## Overview

Chezmoi supports encrypting sensitive files in the source directory. Files are stored encrypted in source control and decrypted when applied to the target system.

**Supported encryption methods**:
- **GPG** (GnuPG) - Asymmetric encryption with public/private keys
- **age** - Modern, simple encryption tool

## Why Encrypt?

Encrypt sensitive files like:
- SSH private keys
- GPG private keys
- API tokens and credentials
- Password files
- TLS certificates
- Application secrets

**Benefits**:
- Safe to commit to public repositories
- Encrypted at rest in source control
- Decrypted only on target systems
- No plaintext secrets in git history

## GPG Encryption

### Setup GPG Encryption

**1. Configure in `.chezmoi.toml.tmpl`**:

```toml
encryption = "gpg"

[gpg]
    recipient = "your-gpg-key-id"
    # Or use email associated with key
    # recipient = "you@example.com"
```

**2. Find Your GPG Key ID**:

```bash
# List GPG keys
gpg --list-keys

# Output example:
# pub   rsa4096 2025-01-01 [SC]
#       1E11F93142FE863643D6998EBBC2AD2A4E6B0BE5
# uid           [ultimate] Your Name <you@example.com>
```

Use the long key ID (40 characters) as recipient.

**3. Verify GPG Key**:

```bash
# Check public key exists
gpg --list-keys 1E11F93142FE863643D6998EBBC2AD2A4E6B0BE5

# Check private key exists (required for decryption)
gpg --list-secret-keys 1E11F93142FE863643D6998EBBC2AD2A4E6B0BE5
```

### Current Repository Configuration

This repository uses GPG encryption:

```toml
encryption = "gpg"

[gpg]
    recipient = "1E11F93142FE863643D6998EBBC2AD2A4E6B0BE5"
```

### Encrypt a File with GPG

**Method 1: Use `chezmoi encrypt` command**:

```bash
# Encrypt file in-place
chezmoi encrypt ~/.ssh/id_rsa

# This creates: encrypted_private_dot_ssh/encrypted_private_id_rsa
```

**Method 2: Manual process**:

```bash
# 1. Copy file to source directory with encrypted_ prefix
cp ~/.ssh/id_rsa ~/.local/share/chezmoi/encrypted_private_dot_ssh/encrypted_private_id_rsa

# 2. Encrypt in place
chezmoi encrypt ~/.local/share/chezmoi/encrypted_private_dot_ssh/encrypted_private_id_rsa

# Result: File is now GPG encrypted in source
```

**Method 3: Add encrypted file directly**:

```bash
# Add file with automatic encryption
chezmoi add --encrypt ~/.ssh/id_rsa

# Chezmoi automatically:
# - Adds encrypted_ prefix
# - Encrypts content with GPG
# - Stores in source directory
```

### Decrypt Files

Decryption happens automatically during `chezmoi apply`:

```bash
# Apply all changes (includes decrypting files)
chezmoi apply

# Preview decrypted content (without applying)
chezmoi cat ~/.ssh/id_rsa

# Decrypt to stdout
chezmoi decrypt ~/.local/share/chezmoi/encrypted_private_dot_ssh/encrypted_private_id_rsa
```

### Edit Encrypted Files

```bash
# Edit encrypted file (automatically decrypts, re-encrypts on save)
chezmoi edit ~/.ssh/id_rsa

# Opens in $EDITOR with decrypted content
# Saves back encrypted when you exit
```

### GPG File Naming

Encrypted files use `encrypted_` prefix:

```
encrypted_private_dot_ssh/encrypted_private_id_rsa
→ ~/.ssh/id_rsa (decrypted, chmod 600)

encrypted_dot_gnupg/encrypted_gpg.conf
→ ~/.gnupg/gpg.conf (decrypted)

encrypted_private_dot_env
→ ~/.env (decrypted, chmod 600)
```

### Multiple GPG Recipients

Encrypt for multiple keys (e.g., personal + work):

```toml
[gpg]
    recipient = ["key-id-1", "key-id-2", "you@example.com"]
```

Anyone with these keys can decrypt.

### Symmetric GPG Encryption

Encrypt with password instead of key:

```toml
[gpg]
    symmetric = true
```

**Note**: Less convenient, requires entering password for each file.

## age Encryption

### Setup age Encryption

**1. Install age**:

```bash
# Arch Linux
pacman -S age

# macOS
brew install age

# Other
https://github.com/FiloSottile/age#installation
```

**2. Generate age key**:

```bash
# Generate new key pair
age-keygen -o ~/.config/age/key.txt

# Output shows public key:
# Public key: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
```

**3. Configure in `.chezmoi.toml.tmpl`**:

```toml
encryption = "age"

[age]
    identity = "~/.config/age/key.txt"
    recipient = "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p"
```

### Encrypt with age

```bash
# Add and encrypt file
chezmoi add --encrypt ~/.ssh/id_rsa

# Creates: encrypted_private_dot_ssh/encrypted_private_id_rsa.age
```

### age File Naming

Encrypted files use `encrypted_` prefix and `.age` suffix:

```
encrypted_private_dot_ssh/encrypted_private_id_rsa.age
→ ~/.ssh/id_rsa (decrypted, chmod 600)

encrypted_dot_env.age
→ ~/.env (decrypted)
```

### Multiple age Recipients

```toml
[age]
    identity = "~/.config/age/key.txt"
    recipient = [
        "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p",
        "age1h6z3c9yqwvvq0k8l5f5p7z9y8x7w6v5u4t3s2r1q0p9o8n7m6l5k4j3i2h1"
    ]
```

### age vs GPG

| Feature | age | GPG |
|---------|-----|-----|
| **Setup** | Simple, one command | More complex, requires GPG key management |
| **Performance** | Faster | Slower |
| **File size** | Smaller overhead | Larger overhead |
| **Key format** | Single text file | Keyring management |
| **Compatibility** | Newer tool | Widely supported |
| **Best for** | Modern setups, simple encryption | Existing GPG workflows, multiple keys |

**Recommendation**: Use **age** for new setups, **GPG** if you already use GPG keys.

## Common Encryption Workflows

### Add Encrypted SSH Key

```bash
# Add private key with encryption
chezmoi add --encrypt ~/.ssh/id_rsa

# File created: encrypted_private_dot_ssh/encrypted_private_id_rsa
# Permissions: private_ prefix ensures chmod 600
```

### Add Encrypted Environment Variables

```bash
# Create .env file
echo "API_KEY=secret123" > ~/.env
echo "DB_PASSWORD=pass456" >> ~/.env

# Add with encryption
chezmoi add --encrypt ~/.env

# Result: encrypted_private_dot_env
```

### Encrypt Entire Directory

```bash
# Add entire .ssh directory encrypted
chezmoi add --encrypt ~/.ssh/

# Or use exact_ for exact sync + encryption
# Source: encrypted_exact_private_dot_ssh/
# Target: ~/.ssh/ (all files encrypted)
```

### Convert Existing File to Encrypted

**Current state**: File already in chezmoi, unencrypted

```bash
# 1. Remove from chezmoi
chezmoi forget ~/.ssh/id_rsa

# 2. Re-add with encryption
chezmoi add --encrypt ~/.ssh/id_rsa

# 3. Apply to verify
chezmoi diff
chezmoi apply
```

### Migrate Between Encryption Methods

**From GPG to age**:

```bash
# 1. Export decrypted files
chezmoi cat ~/.ssh/id_rsa > /tmp/id_rsa

# 2. Update .chezmoi.toml.tmpl to use age
# (change encryption = "age", add [age] section)

# 3. Remove old encrypted files
chezmoi forget ~/.ssh/id_rsa

# 4. Re-add with new encryption
chezmoi add --encrypt /tmp/id_rsa

# 5. Clean up temp files
shred -u /tmp/id_rsa
```

### Share Encrypted Dotfiles

**Scenario**: Multiple machines, different GPG keys

**Solution 1: Multiple recipients**:
```toml
[gpg]
    recipient = [
        "workstation-key-id",
        "laptop-key-id",
        "server-key-id"
    ]
```

**Solution 2: Master key**:
- Use same GPG key on all machines
- Store private key securely (encrypted USB, password manager)

**Solution 3: age with shared identity**:
```toml
[age]
    identity = "~/.config/age/key.txt"
    recipient = "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p"
```
- Copy `key.txt` to all machines
- Same key decrypts on all systems

## Template + Encryption

Encrypted files can be templates:

```bash
# File: encrypted_private_dot_env.tmpl

API_KEY={{ .api_key }}
DB_HOST={{ .db_host }}
{{ if .production }}
DEBUG=false
{{ else }}
DEBUG=true
{{ end }}
```

**Data in `.chezmoi.toml.tmpl`**:
```toml
[data]
    api_key = "secret123"
    db_host = "localhost"
    production = false
```

**Result**: Template processed, then encrypted in source directory.

## Security Best Practices

### 1. Use Strong Keys

**GPG**:
```bash
# Generate 4096-bit RSA key
gpg --full-generate-key
# Choose: RSA and RSA, 4096 bits
```

**age**:
```bash
# age keys are automatically secure (X25519)
age-keygen -o ~/.config/age/key.txt
```

### 2. Protect Private Keys

```bash
# GPG private key: protected by GPG keyring
# Ensure keyring is encrypted with passphrase

# age private key: protect file permissions
chmod 600 ~/.config/age/key.txt

# Never commit private keys to git
```

### 3. Backup Keys

**GPG**:
```bash
# Export private key (encrypted with passphrase)
gpg --export-secret-keys --armor your-key-id > gpg-private.asc

# Store in password manager or secure location
```

**age**:
```bash
# Copy identity file to secure location
cp ~/.config/age/key.txt /path/to/secure/backup/

# Store in password manager
```

### 4. Verify Encryption

```bash
# Check file is actually encrypted
file ~/.local/share/chezmoi/encrypted_private_dot_ssh/encrypted_private_id_rsa

# Should show: GPG encrypted data or age encrypted file
# Should NOT show: ASCII text or OpenSSH private key
```

### 5. Use .chezmoiignore for Secrets

Don't encrypt files that should never be in source control:

```
# .chezmoiignore
.ssh/known_hosts
.gnupg/random_seed
*.bak
```

### 6. Audit Encrypted Files

```bash
# List all encrypted files
find ~/.local/share/chezmoi -name "encrypted_*"

# Verify all sensitive files are encrypted
chezmoi verify
```

## Troubleshooting Encryption

### GPG Key Not Found

**Error**: `gpg: decryption failed: No secret key`

**Solution**:
```bash
# Import private key
gpg --import private-key.asc

# Trust imported key
gpg --edit-key your-key-id
# Type: trust
# Choose: 5 (ultimate)
# Type: quit
```

### Wrong Recipient

**Error**: `gpg: encrypted with RSA key, ID XXXXXXXX`

**Solution**: Update recipient in `.chezmoi.toml.tmpl` to match available key.

### age Identity Not Found

**Error**: `age: error: identity file not found`

**Solution**:
```bash
# Create identity file
mkdir -p ~/.config/age
age-keygen -o ~/.config/age/key.txt

# Update .chezmoi.toml.tmpl with correct path
```

### File Not Encrypted

**Error**: File appears in plaintext in git

**Solution**:
```bash
# Remove from git history (if committed)
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch path/to/file' \
  --prune-empty --tag-name-filter cat -- --all

# Re-add with encryption
chezmoi add --encrypt path/to/file
```

### Can't Edit Encrypted File

**Error**: `chezmoi edit` opens encrypted content

**Solution**:
```bash
# Ensure GPG agent is running
gpg-agent --daemon

# Unlock key
echo "test" | gpg --encrypt --recipient your-key-id | gpg --decrypt

# Retry edit
chezmoi edit ~/.ssh/id_rsa
```

## Advanced Patterns

### Conditional Encryption by Hostname

```
{{ if eq .chezmoi.hostname "personal-laptop" }}
encrypted_private_dot_ssh/encrypted_private_id_rsa_personal
{{ else if eq .chezmoi.hostname "work-laptop" }}
encrypted_private_dot_ssh/encrypted_private_id_rsa_work
{{ end }}
```

### Encrypted Scripts

```bash
# encrypted_run_once_setup-secrets.sh

#!/bin/bash
# This script is encrypted in source

# Setup sensitive environment
echo "export SECRET_KEY=xyz" >> ~/.bashrc
```

### Partial File Encryption

For files with mixed sensitive/non-sensitive content:

**Option 1**: Template with separate encrypted file
```bash
# dot_config.yaml.tmpl
api_endpoint: https://api.example.com
api_key: {{ include "encrypted-api-key.txt" }}
```

**Option 2**: Split into multiple files
```
dot_config/public-settings.yaml      # Non-encrypted
encrypted_dot_config/encrypted_private-settings.yaml  # Encrypted
```

## See Also

- [File Naming Reference](file-naming.md) - Encryption file naming
- [Templates Reference](templates.md) - Combining templates with encryption
- [Troubleshooting](troubleshooting.md) - Common encryption errors
