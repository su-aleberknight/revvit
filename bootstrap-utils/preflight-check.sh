#!/bin/bash
# Runs run-rancher-manager-plays.yml against the bootstrap node defined in the inventory file.
#
# Before running, copy and fill in each vars file:
#   cp rancher-manager-plays/vars/install-cert-manager.yml.example rancher-manager-plays/vars/install-cert-manager.yml
#   cp rancher-manager-plays/vars/install-rancher.yml.example rancher-manager-plays/vars/install-rancher.yml
#   cp rancher-manager-plays/vars/install-rancher-secrets.yml.example rancher-manager-plays/vars/install-rancher-secrets.yml
#
# Usage:
#   ./rancher-manager.sh [-i inventory]
#
# Defaults to 'inventory' if no -i flag is provided.

set -euo pipefail

INVENTORY="inventory"

# Parse optional -i flag
while getopts "i:" opt; do
  case $opt in
    i) INVENTORY="$OPTARG" ;;
    *) echo "Usage: $0 [-i inventory]"; exit 1 ;;
  esac
done

if [[ ! -f "$INVENTORY" ]]; then
  echo "ERROR: Inventory file '$INVENTORY' not found."
  echo "  # edit inventory with your node IPs"
  exit 1
fi

# Check that all required vars files exist
VARS_FILES=(
  "rancher-manager-plays/vars/install-cert-manager.yml"
  "rancher-manager-plays/vars/install-rancher.yml"
  "rancher-manager-plays/vars/install-rancher-secrets.yml"
)

for VAR_FILE in "${VARS_FILES[@]}"; do
  if [[ ! -f "$VAR_FILE" ]]; then
    echo "ERROR: Missing vars file: $VAR_FILE"
    echo "  cp ${VAR_FILE}.example ${VAR_FILE}"
    echo "  # then edit ${VAR_FILE}"
    exit 1
  fi
done

# Extract the Rancher hostname (VIP) from the install-rancher vars file
RANCHER_HOSTNAME=$(awk '/^rancher_hostname:/{print $2}' rancher-manager-plays/vars/install-rancher.yml | tr -d '"')

if [[ -z "$RANCHER_HOSTNAME" ]]; then
  echo "ERROR: Could not read rancher_hostname from rancher-manager-plays/vars/install-rancher.yml"
  exit 1
fi

echo "Installing Rancher Manager"
echo "Rancher UI will be available at: https://$RANCHER_HOSTNAME"
echo "Using inventory: $INVENTORY"
echo ""
echo "Plays to be run in order:"
echo "  1. rancher-manager-plays/install-helm.yml"
echo "  2. rancher-manager-plays/install-rancher-secrets.yml"
echo "  3. rancher-manager-plays/install-cert-manager.yml"
echo "  4. rancher-manager-plays/install-rancher.yml"
echo ""

ansible-playbook run-rancher-manager-plays.yml -i "$INVENTORY"
