#!/usr/bin/env bash
# Adds nodes from nodes.txt to /etc/hosts.
# Must be run as root or with sudo.
#
# Usage: ./add-nodes-to-hosts.sh [nodes-file]
# Default nodes file: nodes.txt (in the same directory as this script)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODES_FILE="${1:-$SCRIPT_DIR/nodes.txt}"

if [ ! -f "$NODES_FILE" ]; then
  echo "Error: nodes file not found: $NODES_FILE"
  exit 1
fi

while IFS= read -r ENTRY || [ -n "$ENTRY" ]; do
  # Skip empty lines and comments
  [[ -z "$ENTRY" || "$ENTRY" == \#* ]] && continue

  if grep -qF "$ENTRY" /etc/hosts; then
    echo "Already exists, skipping: $ENTRY"
  else
    echo "$ENTRY" >> /etc/hosts
    echo "Added: $ENTRY"
  fi
done < "$NODES_FILE"

echo ""
echo "Done. Current entries from $NODES_FILE in /etc/hosts:"
grep -Ff "$NODES_FILE" /etc/hosts
