#!/bin/bash
# config-fail2ban.sh — Install Chhoto URL fail2ban filter + jail drop-in.
# Requires harden.sh to have already installed and started fail2ban.
# Uses nginx access logs since Chhoto's own logs contain no IP address.
set -euo pipefail

source ~/scripts/.security

CHHOTO_JAIL="${CHHOTO_JAIL:-no}"
[[ "$CHHOTO_JAIL" != "yes" ]] && exit 0

cat > /etc/fail2ban/filter.d/chhoto.local <<'EOF'
[INCLUDES]
before = common.conf

[Definition]
failregex = ^<ADDR> -.*"POST /api/login HTTP[^"]*" 401
ignoreregex =
EOF

cat > /etc/fail2ban/jail.d/chhoto.local <<'EOF'
[chhoto]
enabled  = true
port     = http,https
filter   = chhoto
logpath  = /var/log/nginx/chhoto-access.log
backend  = auto
EOF

fail2ban-client reload
echo "✓ Chhoto URL fail2ban jail configured"
