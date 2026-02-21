#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Hetzner Server Setup ==="
echo ""
echo "Select a scenario:"
echo "  1) Install OpenMediaVault"
echo "  2) Install NextCloud"
echo "  3) Install MailCow"
echo "  4) Install VaultWarden"
echo ""
echo -n "Choice [1-4]: "
read SCENARIO

case "$SCENARIO" in
    1) SCENARIO_DIR="setup-omv" ;;
    2) SCENARIO_DIR="setup-nextcloud" ;;
    3) SCENARIO_DIR="setup-mailcow" ;;
    4) SCENARIO_DIR="setup-vaultwarden" ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

"$SCRIPT_DIR/scripts/$SCENARIO_DIR/start.sh"
