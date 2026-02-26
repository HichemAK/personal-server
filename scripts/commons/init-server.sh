#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

# Load .install from project root (one level above scripts/)
source "$SCRIPT_DIR/../.install"

if [ -z "${SERVER_IP:-}" ]; then
    echo "Error: SERVER_IP is not set. Please configure it in .install"
    exit 1
fi
IP="$SERVER_IP"

echo "Make sure the SSH access to your VM is granted password-less!"
echo "Connecting to $IP..."

ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$IP" || true
ssh-keyscan -H "$IP" >> ~/.ssh/known_hosts

ssh root@$IP "sudo apt update && sudo apt install rsync -y"

# Sync scripts to the remote server
rsync -avz "$SCRIPT_DIR/" root@"$IP":~/scripts

# Sync .install and .backup (they live one level above scripts/)
rsync -avz "$SCRIPT_DIR/../.install" root@"$IP":~/scripts/.install
rsync -avz "$SCRIPT_DIR/../.backup" root@"$IP":~/scripts/.backup

ssh root@"$IP" 'sudo apt-get update && ~/scripts/commons/secure-folder.sh'

# Configure unattended upgrades (security + all regular updates, no auto-reboot)
echo "=== Configuring unattended upgrades ==="
ssh root@"$IP" bash <<'REMOTE'
apt-get install -y unattended-upgrades

cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::Unattended-Upgrade "1";
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
REMOTE
echo "✓ Unattended upgrades configured (daily, no auto-reboot)"
