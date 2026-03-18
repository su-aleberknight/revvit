#!/usr/bin/env bash
# Creates an SSH tunnel for VNC access to angie.
# Usage: ./vnc-tunnel.sh <port>
# Example: ./vnc-tunnel.sh 5900

set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage: $0 <port>"
  echo "Example: $0 5900"
  exit 1
fi

PORT="$1"
REMOTE_HOST="angie"
USER="root"

echo "Opening SSH tunnel: localhost:${PORT} -> ${REMOTE_HOST}:${PORT}"
echo "Press Ctrl+C to close the tunnel."

ssh -L "${PORT}:localhost:${PORT}" "${USER}@${REMOTE_HOST}"
