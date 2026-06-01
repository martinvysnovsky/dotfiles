#!/bin/bash
# Enable TCP MTU probing to work around UPC/Horizon router MTU 1460 + PMTUD black-hole
# version: 2

set -e

CONF=/etc/sysctl.d/99-mtu-probing.conf

sudo tee "$CONF" > /dev/null <<'EOF'
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_base_mss = 1024
EOF

sudo sysctl --system
