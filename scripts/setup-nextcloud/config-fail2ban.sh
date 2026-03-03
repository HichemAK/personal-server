#!/bin/bash
# config-fail2ban.sh — Install Nextcloud fail2ban filter + jail drop-in.
# Requires harden.sh to have already installed and started fail2ban.
set -euo pipefail

source ~/scripts/.install
source ~/scripts/.security

NEXTCLOUD_JAIL="${NEXTCLOUD_JAIL:-no}"
[[ "$NEXTCLOUD_JAIL" != "yes" ]] && exit 0

NC_LOG="/var/lib/docker/volumes/nextcloud_aio_nextcloud/_data/data/nextcloud.log"

cat > /etc/fail2ban/filter.d/nextcloud.local <<'EOF'
[Definition]
_groupsre = (?:(?:,?\s*"\w+":(?:"[^"]+"|\w+))*)
failregex = ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Login failed:
            ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Two-factor challenge failed:
            ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Trusted domain error.
datepattern = ,?\s*"time"\s*:\s*"%%Y-%%m-%%d[T ]%%H:%%M:%%S(%%z)?"
ignoreregex =
EOF

cat > /etc/fail2ban/jail.d/nextcloud.local <<EOF
[nextcloud]
enabled  = true
port     = http,https
filter   = nextcloud
logpath  = ${NC_LOG}
backend  = auto
EOF

fail2ban-client reload
echo "✓ Nextcloud fail2ban jail configured"
