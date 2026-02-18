#!/bin/bash
# config-caddy.sh
set -euo pipefail

echo "=== Caddy Configuration for Nextcloud ==="
echo ""
echo -n "Enter the domain you use for MailCow (format: domain.com): "
read NC_FQDN

cat <<EOF | sudo tee -a /etc/caddy/Caddyfile > /dev/null

# Mailcow
mail.${NC_FQDN} autodiscover.${NC_FQDN} autoconfig.${NC_FQDN} {
        log {
                output file /var/log/caddy/${NC_FQDN}.log {
                        roll_disabled
                        roll_size 512M
                        roll_uncompressed
                        roll_local_time
                        roll_keep 3
                        roll_keep_for 48h
                }
        }

        reverse_proxy 127.0.0.1:8090
}
EOF


MAILCOW_HOSTNAME=mail.${NC_FQDN}
CADDY_CERTS_DIR=/var/lib/caddy/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory
MD5SUM_CURRENT_CERT=($(md5sum /opt/mailcow-dockerized/data/assets/ssl/cert.pem))
MD5SUM_NEW_CERT=($(md5sum $CADDY_CERTS_DIR/$MAILCOW_HOSTNAME/$MAILCOW_HOSTNAME.crt))

if [ $MD5SUM_CURRENT_CERT != $MD5SUM_NEW_CERT ]; then
        cp $CADDY_CERTS_DIR/$MAILCOW_HOSTNAME/$MAILCOW_HOSTNAME.crt /opt/mailcow-dockerized/data/assets/ssl/cert.pem
        cp $CADDY_CERTS_DIR/$MAILCOW_HOSTNAME/$MAILCOW_HOSTNAME.key /opt/mailcow-dockerized/data/assets/ssl/key.pem
        cp $CADDY_CERTS_DIR/$MAILCOW_HOSTNAME/$MAILCOW_HOSTNAME.crt /opt/mailcow-dockerized/data/assets/ssl/$MAILCOW_HOSTNAME/cert.pem
        cp $CADDY_CERTS_DIR/$MAILCOW_HOSTNAME/$MAILCOW_HOSTNAME.key /opt/mailcow-dockerized/data/assets/ssl/$MAILCOW_HOSTNAME/key.pem
        postfix_c=$(docker ps -qaf name=postfix-mailcow)
        dovecot_c=$(docker ps -qaf name=dovecot-mailcow)
        nginx_c=$(docker ps -qaf name=nginx-mailcow)
        docker restart ${postfix_c} ${dovecot_c} ${nginx_c}

else
        echo "Certs not copied from Caddy (Not needed)"
fi

sudo systemctl reload caddy
echo "✓ Caddy configured for MailCow"


