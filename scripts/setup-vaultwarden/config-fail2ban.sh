#!/bin/bash
# config-fail2ban.sh — Install Vaultwarden fail2ban filter + jail drop-in.
# Requires harden.sh to have already installed and started fail2ban.
set -euo pipefail

source ~/scripts/.install
source ~/scripts/.security

VAULTWARDEN_JAIL="${VAULTWARDEN_JAIL:-no}"
[[ "$VAULTWARDEN_JAIL" != "yes" ]] && exit 0

cat > /etc/fail2ban/filter.d/vaultwarden.local <<'EOF'
[INCLUDES]
before = common.conf

[Definition]
failregex = ^.*?Username or password is incorrect\. Try again\. IP: <ADDR>\. Username:.*$
            ^.*?Invalid admin token\. IP: <ADDR>$
ignoreregex =
EOF

VW_LOG="/data/vw/vaultwarden.log"

cat > /etc/fail2ban/jail.d/vaultwarden.local <<EOF
[vaultwarden]
enabled  = true
port     = http,https
filter   = vaultwarden
logpath  = ${VW_LOG}
backend  = auto
EOF

fail2ban-client reload
echo "✓ Vaultwarden fail2ban jail configured"
