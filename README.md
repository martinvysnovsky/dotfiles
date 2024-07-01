# Dotfiles

## Install

### Set GPG key

https://www.jwillikers.com/backup-and-restore-a-gpg-key

### Initialize Chezmoi

First setup configuration of machine

```
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply --exclude=externals,scripts martinvysnovsky
```

Configure the rest

```
./bin/chezmoi update
```
