#!/bin/bash

cd ~/.nvm
git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`

# activate nvm
. ~/.nvm/nvm.sh

# install latest node
nvm install node
nvm install-latest-npm
