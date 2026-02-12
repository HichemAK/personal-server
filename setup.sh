#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Hetzner Server Setup ==="
echo ""
echo "Select a scenario:"
echo "  1) Install OpenMediaVault"
echo "  2) Install NextCloud"
echo ""
echo -n "Choice [1-2]: "
read SCENARIO

case "$SCENARIO" in
    1) SCENARIO_DIR="setup-omv" ;;
    2) SCENARIO_DIR="setup-nextcloud" ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

"$SCRIPT_DIR/scripts/$SCENARIO_DIR/start.sh"
