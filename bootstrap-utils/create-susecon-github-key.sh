#!/usr/bin/env bash
# Generates an ed25519 SSH key named susecon-ssh in ~/.ssh/
# Skips generation if the key already exists.

set -euo pipefail

KEY_PATH="$HOME/.ssh/susecon-git-secret"

if [ -f "$KEY_PATH" ]; then
  echo "SSH key already exists at $KEY_PATH, skipping generation."
  echo "Public key: $(cat ${KEY_PATH}.pub)"
  exit 0
fi

echo "Generating SSH key pair at $KEY_PATH ..."
ssh-keygen -t ed25519 -f "$KEY_PATH" -C "susecon-ssh" -N ""

echo ""
echo "Key generated successfully."
echo "Private key: $KEY_PATH"
echo "Public key:  ${KEY_PATH}.pub"
echo ""
echo "To use this key: ssh -i $KEY_PATH user@host"
