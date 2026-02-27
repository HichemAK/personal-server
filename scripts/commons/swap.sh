#!/bin/bash

set -euo pipefail

# ─── Usage ────────────────────────────────────────────────────────────────────
usage() {
    echo "Usage: $0 <required_mb> <swapfile_path>"
    echo "  required_mb   : Minimum required swap in MB (e.g. 2048)"
    echo "  swapfile_path : Path to the swap file (e.g. /swapfile)"
    echo ""
    echo "Example: sudo $0 2048 /swapfile"
    exit 1
}

# ─── Input validation ─────────────────────────────────────────────────────────
if [[ $# -ne 2 ]]; then
    echo "Error: Expected 2 arguments, got $#." >&2
    usage
fi

REQUIRED_MB="$1"
SWAPFILE="$2"

if ! [[ "$REQUIRED_MB" =~ ^[0-9]+$ ]] || [[ "$REQUIRED_MB" -eq 0 ]]; then
    echo "Error: required_mb must be a positive integer." >&2
    usage
fi

if [[ "$SWAPFILE" != /* ]]; then
    echo "Error: swapfile_path must be an absolute path (e.g. /swapfile)." >&2
    usage
fi

# Must run as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root." >&2
    exit 1
fi

# ─── Check current swap ───────────────────────────────────────────────────────
CURRENT_MB=$(free -m | awk '/^Swap:/ { print $2 }')

echo "Required swap : ${REQUIRED_MB} MB"
echo "Current swap  : ${CURRENT_MB} MB"

if [[ "$CURRENT_MB" -ge "$REQUIRED_MB" ]]; then
    echo "✔ Swap is sufficient. Nothing to do."
    exit 0
fi

MISSING_MB=$(( REQUIRED_MB - CURRENT_MB ))
echo "✘ Swap is insufficient. Need ${MISSING_MB} MB more."

# ─── Extend existing swapfile or create a new one ────────────────────────────
if [[ -f "$SWAPFILE" ]]; then
    echo "Extending existing swapfile: $SWAPFILE"
    swapoff "$SWAPFILE"
    dd if=/dev/zero bs=1M count="$MISSING_MB" >> "$SWAPFILE" status=progress
    mkswap "$SWAPFILE"
    swapon "$SWAPFILE"
    echo "✔ Swapfile extended to $(( CURRENT_MB + MISSING_MB )) MB."
else
    echo "Creating new swapfile: $SWAPFILE (${MISSING_MB} MB)"
    dd if=/dev/zero of="$SWAPFILE" bs=1M count="$MISSING_MB" status=progress
    chmod 600 "$SWAPFILE"
    mkswap "$SWAPFILE"
    swapon "$SWAPFILE"
    echo "✔ Swapfile created and enabled (${MISSING_MB} MB)."
fi

# ─── Persist across reboots ───────────────────────────────────────────────────
if ! grep -q "^$SWAPFILE " /etc/fstab; then
    echo "$SWAPFILE none swap sw 0 0" >> /etc/fstab
    echo "✔ Added $SWAPFILE to /etc/fstab."
fi

echo ""
echo "Current swap status:"
swapon --show