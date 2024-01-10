#!/bin/bash

sudo dnf install -y neovim python3-neovim g++ ripgrep zsh pass pass-otp fzf

sudo dnf copr enable -y atim/lazygit
sudo dnf install -y lazygit
