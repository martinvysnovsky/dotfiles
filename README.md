# Dotfiles

## Install

### Generate GitHub SSH key

https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent

### Initialize Chezmoi

```
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --ssh --apply martinvysnovsky
```
