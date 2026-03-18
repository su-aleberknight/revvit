#!/usr/bin/env bash
# Renames the NIC that holds the given IP address to eno1 using a systemd
# .link file. If eno1 is already in use by a different interface, that
# interface is renamed to eno1_prev first.
#
# Changes take effect after reboot.
#
# Usage:
#   sudo ./configure-nic-name.sh <ip-address>
#
# Example:
#   sudo ./configure-nic-name.sh 192.168.1.201

set -euo pipefail

TARGET_NAME="eno1"
LINK_DIR="/etc/systemd/network"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <ip-address>"
  exit 1
fi

TARGET_IP="$1"

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root."
  exit 1
fi

# Find the interface currently holding the target IP
TARGET_IFACE=$(ip -o addr show | awk -v ip="$TARGET_IP" '$4 ~ "^"ip"/" {print $2}')

if [[ -z "$TARGET_IFACE" ]]; then
  echo "ERROR: No interface found with IP address $TARGET_IP"
  exit 1
fi

echo "Found interface '$TARGET_IFACE' with IP $TARGET_IP"

# If the interface is already named eno1 nothing to do
if [[ "$TARGET_IFACE" == "$TARGET_NAME" ]]; then
  echo "Interface is already named '$TARGET_NAME' — nothing to do."
  exit 0
fi

# Get the MAC address of the target interface
TARGET_MAC=$(cat /sys/class/net/"$TARGET_IFACE"/address 2>/dev/null)

if [[ -z "$TARGET_MAC" ]]; then
  echo "ERROR: Could not read MAC address for interface '$TARGET_IFACE'"
  exit 1
fi

echo "MAC address of '$TARGET_IFACE': $TARGET_MAC"

# Check if eno1 is already in use by a different interface
if ip link show "$TARGET_NAME" &>/dev/null; then
  EXISTING_MAC=$(cat /sys/class/net/"$TARGET_NAME"/address 2>/dev/null)
  echo "WARNING: '$TARGET_NAME' already exists (MAC: $EXISTING_MAC) — renaming it to '${TARGET_NAME}_prev'"

  EXISTING_LINK_FILE="$LINK_DIR/10-rename-${TARGET_NAME}_prev.link"
  cat > "$EXISTING_LINK_FILE" <<EOF
[Match]
MACAddress=$EXISTING_MAC

[Link]
Name=${TARGET_NAME}_prev
EOF
  echo "Created: $EXISTING_LINK_FILE"
fi

# Create the .link file to rename the target interface to eno1
TARGET_LINK_FILE="$LINK_DIR/10-rename-${TARGET_NAME}.link"
cat > "$TARGET_LINK_FILE" <<EOF
[Match]
MACAddress=$TARGET_MAC

[Link]
Name=$TARGET_NAME
EOF

echo "Created: $TARGET_LINK_FILE"
echo ""
echo "Summary:"
echo "  Interface '$TARGET_IFACE' (MAC: $TARGET_MAC) will be renamed to '$TARGET_NAME' after reboot."
echo ""
echo "Reboot the system to apply the change:"
echo "  reboot"
