#!/bin/bash
# graphify version: 0.8.45
# Bump the version above to re-run this script and upgrade the graphify skill.

set -e

# Install or upgrade the graphify package.
if command -v uv >/dev/null 2>&1; then
	uv tool install --upgrade graphifyy -q 2>/dev/null || true
else
	pip install --upgrade graphifyy -q 2>/dev/null || pip install --upgrade graphifyy -q --break-system-packages 2>/dev/null || true
fi

# Run the installer from a temp dir: `graphify install` writes stray project-local
# .opencode/ files into the CWD, which we don't want polluting the chezmoi source tree.
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
(cd "$tmp_dir" && graphify install --platform opencode 2>/dev/null) || true
