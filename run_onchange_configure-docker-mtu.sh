#!/bin/bash
# Set Docker daemon MTU to 1460 (UPC/Horizon router limit), merging with existing daemon.json
# version: 2

set -e

DAEMON=/etc/docker/daemon.json

# Ensure /etc/docker exists (absent when dockerd runs with defaults)
sudo mkdir -p /etc/docker

if [ -f "$DAEMON" ]; then
  EXISTING=$(sudo cat "$DAEMON")
else
  EXISTING='{}'
fi

# Merge mtu key into existing JSON (requires jq)
echo "$EXISTING" | jq '. + {mtu: 1460}' | sudo tee "$DAEMON" > /dev/null

# Apply: restart docker if running
if systemctl is-active --quiet docker; then
  sudo systemctl restart docker
fi
