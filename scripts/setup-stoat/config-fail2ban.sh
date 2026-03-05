#!/bin/bash
# config-fail2ban.sh — Stoat fail2ban jail.
# Log format for auth failures is not yet documented; jail implementation is deferred.
# Set STOAT_JAIL=yes in .security once a filter has been added.
set -euo pipefail

source ~/scripts/.security

STOAT_JAIL="${STOAT_JAIL:-no}"
[[ "$STOAT_JAIL" != "yes" ]] && exit 0

echo "Warning: Stoat fail2ban jail not yet implemented." >&2
echo "Set STOAT_JAIL=no in .security until a filter is configured." >&2
exit 1
