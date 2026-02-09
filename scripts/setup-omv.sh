# Setup OpenMediaVault
# Commands fetched directly from OMV doc (https://docs.openmediavault.org/en/latest/installation/on_debian.html)

sudo apt install --yes systemd-resolved psmisc
sudo systemctl enable --now systemd-resolved.service
sudo systemctl restart systemd-resolved.service

# Using Cloudflare as DNS
sudo resolvectl dns eth0 1.1.1.1 1.0.0.1

sudo apt install --yes gnupg
sudo wget --quiet --output-document=- https://packages.openmediavault.org/public/archive.key | gpg --dearmor --yes --output "/usr/share/keyrings/openmediavault-archive-keyring.gpg"

sudo cat <<EOF >> /etc/apt/sources.list.d/openmediavault.list
deb [signed-by=/usr/share/keyrings/openmediavault-archive-keyring.gpg] https://packages.openmediavault.org/public synchrony main
deb [signed-by=/usr/share/keyrings/openmediavault-archive-keyring.gpg] https://downloads.sourceforge.net/project/openmediavault/packages synchrony main
# Uncomment the following line to add software from the proposed repository.
deb [signed-by=/usr/share/keyrings/openmediavault-archive-keyring.gpg] https://packages.openmediavault.org/public synchrony-proposed main
deb [signed-by=/usr/share/keyrings/openmediavault-archive-keyring.gpg] https://downloads.sourceforge.net/project/openmediavault/packages synchrony-proposed main
# This software is not part of OpenMediaVault, but is offered by third-party
# developers as a service to OpenMediaVault users.
deb [signed-by=/usr/share/keyrings/openmediavault-archive-keyring.gpg] https://packages.openmediavault.org/public synchrony partner
deb [signed-by=/usr/share/keyrings/openmediavault-archive-keyring.gpg] https://downloads.sourceforge.net/project/openmediavault/packages synchrony partner
EOF

export LANG=C.UTF-8
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none
sudo apt update
sudo apt --yes --auto-remove --show-upgraded \
    --allow-downgrades --allow-change-held-packages \
    --no-install-recommends \
    --option DPkg::Options::="--force-confdef" \
    --option DPkg::Options::="--force-confold" \
    install openmediavault

sudo omv-confdbadm populate

echo "\n\n\n\n"
echo "VERY IMPORTANT"
echo "=============="
echo "The access to the HTTP server is deactivated using a firewall and you can access this machine exclusively through SSH."
echo "I strongly advise you to update the password of the OpenMediaVault admin and setup HTTPS in the WebUI"
echo "To do that visit http://localhost:9909 in your local machine (not this one) to get access to the WebUI. The default username and password should be \"admin\" and \"openmediavault\" "
echo "\n\n"
echo "Once the configuration is completed. Interrupt this execution (using Ctrl-C), then execute the following script to grant to the internet the access to your server : /root/server/allow-connections.sh" 
echo "This script will run indefinitely. DO NOT CLOSE IT UNTIL ABOVE INSTRUCTIONS ARE COMPLETED."

sleep infinity