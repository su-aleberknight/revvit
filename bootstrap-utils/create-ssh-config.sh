#!/usr/bin/env bash
# Creates or updates ~/.ssh/config with:
#   - A default IdentityFile set to susecon-ssh
#   - A GitHub host entry using susecon-git-secret

set -euo pipefail

SSH_DIR="$HOME/.ssh"
CONFIG_FILE="$SSH_DIR/config"

# Ensure .ssh directory exists
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Check if config already contains our entries
if grep -q "susecon-ssh" "$CONFIG_FILE" 2>/dev/null; then
  echo "SSH config already contains susecon-ssh entries. Skipping."
  cat "$CONFIG_FILE"
  exit 0
fi

echo "Writing SSH config to $CONFIG_FILE ..."

cat >> "$CONFIG_FILE" <<EOF

# Default identity for all hosts
Host *
  IdentityFile ~/.ssh/susecon-ssh
  AddKeysToAgent yes

# GitHub
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/susecon-git-secret
  AddKeysToAgent yes
EOF

chmod 600 "$CONFIG_FILE"

echo "Done. SSH config:"
echo ""
cat "$CONFIG_FILE"

