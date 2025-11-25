# Dotfiles

Personal dotfiles for Arch Linux with Hyprland, managed with [chezmoi](https://www.chezmoi.io/).

## Installation

### Prerequisites

- Arch Linux
- GPG key ([backup/restore guide](https://www.jwillikers.com/backup-and-restore-a-gpg-key))

### Setup

1. **Install chezmoi**

   ```bash
   yay -S chezmoi
   ```

2. **Initialize dotfiles**

   ```bash
   chezmoi init --apply --exclude=externals,scripts martinvysnovsky
   ```

3. **Complete setup**

   ```bash
   chezmoi update
   ```

## Usage

```bash
# Preview changes
chezmoi diff

# Apply changes
chezmoi apply

# Edit a config file
chezmoi edit ~/.zshrc

# Add new file to management
chezmoi add ~/.config/app/config
```

## Package Management

Add packages to `.chezmoidata/packages.yaml` by category (pacman, yay, npm). They'll be auto-installed on next `chezmoi apply`.

## Update

```bash
# Update chezmoi and system packages
yay -Syu

# Update dotfiles from repo
chezmoi update
```

## File Conventions

- `dot_` → `.filename` in home directory
- `run_onchange_` → runs when file changes
- `run_once_` → runs once per machine
- `encrypted_` → GPG encrypted
- `.tmpl` → template with variables
