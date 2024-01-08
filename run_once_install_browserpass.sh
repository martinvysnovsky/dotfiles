#!/bin/bash

# download
cd ~
curl -LJO https://github.com/browserpass/browserpass-native/releases/download/3.1.0/browserpass-linux64-3.1.0.tar.gz
tar -xzf browserpass-linux64-3.1.0.tar.gz
cd browserpass-linux64-3.1.0

# install
make BIN=browserpass-linux64 configure
sudo make BIN=browserpass-linux64 install

# configure
cd /usr/lib/browserpass/
make hosts-chrome-user

# cleanup
rm ~/browserpass-linux64-3.1.0.tar.gz
rm -rf ~/browserpass-linux64-3.1.0
