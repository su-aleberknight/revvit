#!/usr/bin/env bash
# Generates an ed25519 SSH key named susecon-ssh on the local machine and
# distributes the public key to the specified node.
# You will be prompted for the root password.
#
# Usage: ./distribute-bootstrap-key.sh <ip-address>

set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage: $0 <ip-address>"
  echo "Example: $0 192.168.1.201"
  exit 1
fi

KEY_PATH="$HOME/.ssh/susecon-ssh"
NODE="$1"
USER="root"

# Generate the key if it doesn't already exist
if [ ! -f "$KEY_PATH" ]; then
  echo "Generating SSH key pair at $KEY_PATH ..."
  ssh-keygen -t ed25519 -f "$KEY_PATH" -C "susecon ssh lab key" -N ""
else
  echo "SSH key already exists at $KEY_PATH, skipping generation."
fi

PUB_KEY=$(cat "${KEY_PATH}.pub")

echo ""
echo "Distributing key to $USER@$NODE (enter root password when prompted)..."
ssh -o StrictHostKeyChecking=no "$USER@$NODE" \
  "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '$PUB_KEY' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

echo ""
echo "Done. You can now connect with: ssh -i $KEY_PATH $USER@$NODE"
