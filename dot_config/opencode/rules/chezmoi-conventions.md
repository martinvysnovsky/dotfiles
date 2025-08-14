# Chezmoi Conventions

## File Naming Rules

- Files prefixed with `dot_` become `.filename` in home directory
- Files prefixed with `run_onchange_` are scripts that execute when changed  
- Files prefixed with `run_once_` execute only once per machine
- `exact_` directories are managed exactly (no extra files allowed)
- Encrypted files use `.asc` extension and GPG encryption
- Templates use `.tmpl` extension for variable substitution

## Template Variables

- Use `{{ .chezmoi.hostname }}` for hostname-specific configs
- Use `{{ .chezmoi.os }}` for OS-specific configurations
- Store sensitive data encrypted with GPG recipient: 1E11F93142FE863643D6998EBBC2AD2A4E6B0BE5

## Package Management

- Add new packages to `.chezmoidata/packages.yaml` by category (pacman, yay, npm)
- External dependencies go in `.chezmoiexternal.toml`
- Use template scripts for conditional package installation

## Configuration Structure

- System configs go in `dot_config/`
- Private files (SSH keys, etc.) go in `private_dot_ssh/`
- Wallpapers and assets go in dedicated directories
- Scripts should be executable and follow bash conventions