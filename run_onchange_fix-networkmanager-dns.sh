#!/bin/bash
# Fix broken NetworkManager DNS: `dns=none` in conf.d disables resolv.conf management,
# but no local resolver (systemd-resolved/dnsmasq/unbound) is installed -> DNS breaks.
# Only act if the bad state exists AND no working local resolver is present.
# version: 1

set -e

NM_DNS_CONF=/etc/NetworkManager/conf.d/dns.conf

# Nothing to do if the file doesn't exist
if [ ! -f "$NM_DNS_CONF" ]; then
  exit 0
fi

# Only act if it actually sets dns=none
if ! grep -Eq '^\s*dns\s*=\s*none\s*$' "$NM_DNS_CONF"; then
  exit 0
fi

# If a local resolver is actually running, dns=none is intentional/valid -> leave it.
if systemctl is-active --quiet systemd-resolved.service \
  || systemctl is-active --quiet dnsmasq.service \
  || systemctl is-active --quiet unbound.service; then
  echo "dns=none present but a local resolver is active; leaving NetworkManager DNS config untouched."
  exit 0
fi

echo "Broken NetworkManager dns=none detected with no local resolver. Removing and restarting NetworkManager..."

# Remove the offending drop-in so NetworkManager reverts to default DNS handling
sudo rm -f "$NM_DNS_CONF"

# Remove a stale static resolv.conf (e.g. only 'nameserver 127.0.0.1') so NM can repopulate it.
# Skip removal if it's a symlink (managed by systemd-resolved or similar).
if [ -f /etc/resolv.conf ] && [ ! -L /etc/resolv.conf ]; then
  sudo rm -f /etc/resolv.conf
fi

sudo systemctl restart NetworkManager
