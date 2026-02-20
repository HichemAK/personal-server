# Setup OpenMediaVault
# Commands fetched directly from OMV doc (https://docs.openmediavault.org/en/latest/installation/on_debian.html)

export DEBIAN_FRONTEND=noninteractive
export LANG=C.UTF-8
export APT_LISTCHANGES_FRONTEND=none

debconf-set-selections <<EOF
resolvconf resolvconf/reboot-recommended note 
resolvconf resolvconf/reboot-recommended seen true
EOF
sudo apt-get install --yes systemd-resolved psmisc
sudo systemctl enable --now systemd-resolved.service
sudo systemctl restart systemd-resolved.service

# Using Cloudflare as DNS
sudo resolvectl dns eth0 1.1.1.1 1.0.0.1

sudo apt-get install --yes gnupg
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


# Pre-filliung postfix options
echo "postfix postfix/main_mailer_type select Internet with smarthost" | sudo debconf-set-selections
echo "postfix postfix/mailname string $(hostname -f)" | sudo debconf-set-selections
echo "postfix postfix/relayhost string " | sudo debconf-set-selections  # Empty!
echo 'openmediavault openmediavault/run-initsystem-tools note' | debconf-set-selections
echo 'openmediavault openmediavault/run-initsystem-tools seen true' | debconf-set-selections

sudo apt-get update
sudo apt-get --yes --auto-remove --show-upgraded \
    --allow-downgrades --allow-change-held-packages \
    --no-install-recommends \
    --option DPkg::Options::="--force-confdef" \
    --option DPkg::Options::="--force-confold" \
    install openmediavault

sudo omv-confdbadm populate

echo -e "\n\n\n\n"
echo "VERY IMPORTANT"
echo "=============="
echo "The access to the HTTP server is deactivated using a firewall and you can access this machine exclusively through SSH."
echo "I strongly advise you to update the password of the OpenMediaVault admin and setup HTTPS in the WebUI"
echo "To do that visit http://localhost:9909 in your local machine (not this one) to get access to the WebUI. The default username and password should be \"admin\" and \"openmediavault\" "
echo -e "\n\n"
echo "Once the configuration is completed. Interrupt this execution using Ctrl-C"
echo "WARNING: Once Ctrl-C is pressed YOUR SERVER WILL BE ACCESSIBLE BY THE WHOLE INTERNET!"

trap ':' INT
sleep infinity &
wait $!

./allow-connections.sh
