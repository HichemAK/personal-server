#!/usr/bin/env bash
# VPS Security Setup — Cockpit + Fail2Ban
# Configure options in ~/scripts/.security before running.
# Needs to be idempotent

set -euo pipefail

[[ $EUID -ne 0 ]] && echo "Run as root." && exit 1

source ~/scripts/.security

AUTO_UPGRADES="${AUTO_UPGRADES:-unattended}"
UPGRADE_PERIOD="${UPGRADE_PERIOD:-1}"
IGNORE_IPS="${IGNORE_IPS:-}"
BANTIME="${BANTIME:-3600}"
MAXRETRY="${MAXRETRY:-3}"
FINDTIME="${FINDTIME:-600}"
NGINX_JAIL="${NGINX_JAIL:-no}"

# --- Upgrades ---
echo "==> Updating package lists..."
apt-get update -qq

if [[ "$AUTO_UPGRADES" != "no" ]]; then
    # 'yes'        → always run apt-get upgrade when this script is invoked
    # 'unattended' → run apt-get upgrade once (first time only, guarded by sentinel)
    if [[ "$AUTO_UPGRADES" == "yes" ]] || \
       [[ "$AUTO_UPGRADES" == "unattended" ]]; then
        echo "==> Applying all pending upgrades..."
        apt-get upgrade -y -qq
    fi

    echo "==> Configuring unattended-upgrades..."
    apt-get install -y -qq unattended-upgrades

    cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::Unattended-Upgrade "${UPGRADE_PERIOD}";
APT::Periodic::AutocleanInterval "7";
EOF

    cat > /etc/apt/apt.conf.d/50unattended-upgrades <<'EOF'
Unattended-Upgrade::Origins-Pattern {
    "origin=*";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

    systemctl enable --now unattended-upgrades
    echo "✓ Unattended upgrades configured (period: every ${UPGRADE_PERIOD} day(s))"
fi

# --- Cockpit ---
echo "==> Installing Cockpit..."
apt install cockpit sscg -y -qq

mkdir -p /etc/cockpit
cat > /etc/cockpit/cockpit.conf <<EOF
[WebService]
Origins = https://localhost:9909 https://127.0.0.1:9909
AllowUnencrypted = false
[Session]
IdleTimeout = 15
EOF

mkdir -p /etc/systemd/system/cockpit.socket.d/
cat > /etc/systemd/system/cockpit.socket.d/listen.conf <<EOF
[Socket]
ListenStream=
ListenStream=127.0.0.1:9909
EOF

sed -i '/^root$/d' /etc/cockpit/disallowed-users 2>/dev/null || true

systemctl daemon-reload
systemctl enable cockpit.socket
systemctl restart cockpit.socket

# --- Fail2Ban ---
echo "==> Installing Fail2Ban..."
apt install fail2ban -y -qq

IGNORE="127.0.0.1/8 ::1${IGNORE_IPS:+ $IGNORE_IPS}"

{
    cat <<EOF
[DEFAULT]
ignoreip  = ${IGNORE}
bantime   = ${BANTIME}
findtime  = ${FINDTIME}
maxretry  = ${MAXRETRY}
backend   = systemd

[sshd]
enabled = true
EOF
    if [[ "$NGINX_JAIL" == "yes" ]]; then
        cat <<EOF

[nginx-http-auth]
enabled  = true
port     = http,https
logpath  = /var/log/nginx/error.log
EOF
    fi
    cat <<'EOF'

[recidive]
enabled    = true
logpath    = /var/log/fail2ban.log
banaction  = iptables-allports
bantime    = -1
findtime   = -1
maxretry   = 2
EOF
} > /etc/fail2ban/jail.local

systemctl enable fail2ban
systemctl restart fail2ban

echo "==> Enabling SSH password authentication..."
sed -i 's/^#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#\?\s*KbdInteractiveAuthentication.*/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
systemctl reload ssh
echo "✓ SSH password login enabled"

# --- Done ---
VPS_IP=$(hostname -I | awk '{print $1}')
echo ""
echo "=== Done ==="
echo "Cockpit:  ssh -L 9909:127.0.0.1:9909 root@${VPS_IP}"
echo "          then open https://127.0.0.1:9909"
echo "Fail2Ban: sudo fail2ban-client status sshd"
