#!/bin/bash
# setup-mount.sh
# Provides the mount_drives function. Source this file, then call mount_drives.
# All mount configuration is read from MOUNT_N_* environment variables
# (already sourced from ~/scripts/.install by the calling script).

mount_drives() {
    local n=1

    while true; do
        local type_var="MOUNT_${n}_TYPE"
        local type="${!type_var:-}"

        # Stop iterating when no more slots are defined
        if [ -z "$type" ]; then
            break
        fi

        # Skip explicitly disabled slots
        if [ "$type" = "none" ] || [ "$type" = "skip" ]; then
            echo "Skipping mount slot $n (type=none)"
            n=$((n + 1))
            continue
        fi

        local user_var="MOUNT_${n}_USER"
        local addr_var="MOUNT_${n}_ADDRESS"
        local point_var="MOUNT_${n}_POINT"
        local pass_var="MOUNT_${n}_PASS"
        local port_var="MOUNT_${n}_PORT"

        local MOUNT_USER="${!user_var:-}"
        local MOUNT_ADDRESS="${!addr_var:-}"
        local MOUNT_POINT="${!point_var:-}"
        local MOUNT_PASS="${!pass_var:-}"
        local MOUNT_PORT="${!port_var:-}"

        if [ -z "$MOUNT_POINT" ]; then
            echo "Error: MOUNT_${n}_POINT is not set. Skipping slot $n."
            n=$((n + 1))
            continue
        fi

        echo "=== Mount $n: $type → $MOUNT_POINT ==="

        sudo mkdir -p "$MOUNT_POINT"

        # Idempotency: unmount if already mounted
        if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
            echo "⚠  $MOUNT_POINT is already mounted — unmounting for remount..."
            if [ "$type" = "sftp" ]; then
                fusermount -u "$MOUNT_POINT" || sudo umount "$MOUNT_POINT" || sudo umount -l "$MOUNT_POINT"
            else
                sudo umount "$MOUNT_POINT" || sudo umount -l "$MOUNT_POINT"
            fi
        fi

        case "$type" in
            sftp)
                echo "--- SFTP mount ---"
                local SSH_PORT="${MOUNT_PORT:-22}"

                sudo apt-get install -y sshfs

                local FSTAB_ENTRY="${MOUNT_USER}@${MOUNT_ADDRESS}:/home ${MOUNT_POINT} fuse.sshfs port=${SSH_PORT},password_stdin,StrictHostKeyChecking=no,_netdev,allow_other,default_permissions 0 0"
                if ! grep -qF "$MOUNT_POINT" /etc/fstab; then
                    echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab
                    echo "✓ Added to /etc/fstab"
                fi

                echo "$MOUNT_PASS" | sudo sshfs \
                    "${MOUNT_USER}@${MOUNT_ADDRESS}:/home" "$MOUNT_POINT" \
                    -o port="$SSH_PORT",password_stdin,StrictHostKeyChecking=no,allow_other,default_permissions
                echo "✓ SFTP mounted at $MOUNT_POINT (port $SSH_PORT)"

                local copy_key_var="MOUNT_${n}_COPY_SSH_KEY"
                if [ "${!copy_key_var:-}" = "true" ]; then
                    echo "--- Copying SSH key to remote (passwordless access) ---"
                    sudo apt-get install -y sshpass
                    if [ ! -f /root/.ssh/id_ed25519 ]; then
                        ssh-keygen -t ed25519 -N "" -f /root/.ssh/id_ed25519
                        echo "✓ Generated new SSH keypair at /root/.ssh/id_ed25519"
                    fi
                    sshpass -p "$MOUNT_PASS" ssh-copy-id \
                        -i /root/.ssh/id_ed25519.pub \
                        -p "$SSH_PORT" \
                        -s \
                        -o StrictHostKeyChecking=no \
                        "${MOUNT_USER}@${MOUNT_ADDRESS}"
                    echo "✓ SSH key registered on remote — passwordless access enabled for ${MOUNT_USER}@${MOUNT_ADDRESS}:${SSH_PORT}"
                fi
                ;;

            smb)
                echo "--- SMB mount ---"
                sudo apt-get install -y cifs-utils

                local CRED_FILE="/etc/samba/credentials_mount${n}"
                sudo mkdir -p /etc/samba
                sudo tee "$CRED_FILE" > /dev/null <<EOF
username=$MOUNT_USER
password=$MOUNT_PASS
EOF
                sudo chmod 600 "$CRED_FILE"
                echo "✓ Credentials stored at $CRED_FILE"

                if ! grep -qF "$MOUNT_POINT" /etc/fstab; then
                    echo "//${MOUNT_ADDRESS}/backup ${MOUNT_POINT} cifs credentials=${CRED_FILE},_netdev 0 0" | sudo tee -a /etc/fstab
                    echo "✓ Added to /etc/fstab"
                fi

                sudo mount "$MOUNT_POINT"
                echo "✓ SMB mounted at $MOUNT_POINT"
                ;;

            webdav)
                echo "--- WebDAV mount ---"
                sudo apt-get install -y davfs2

                local WEBDAV_URL="https://${MOUNT_ADDRESS}"
                local DAVFS_SECRETS="/etc/davfs2/secrets"

                if ! grep -qF "$WEBDAV_URL" "$DAVFS_SECRETS" 2>/dev/null; then
                    echo "$WEBDAV_URL $MOUNT_USER $MOUNT_PASS" | sudo tee -a "$DAVFS_SECRETS" > /dev/null
                    sudo chmod 600 "$DAVFS_SECRETS"
                    echo "✓ WebDAV credentials stored"
                fi

                if ! grep -qF "$MOUNT_POINT" /etc/fstab; then
                    echo "${WEBDAV_URL} ${MOUNT_POINT} davfs _netdev,auto 0 0" | sudo tee -a /etc/fstab
                    echo "✓ Added to /etc/fstab"
                fi

                sudo mount "$MOUNT_POINT"
                echo "✓ WebDAV mounted at $MOUNT_POINT"
                ;;

            *)
                echo "Error: Unknown mount type '$type' for slot $n. Valid types: sftp, smb, webdav, none."
                exit 1
                ;;
        esac

        n=$((n + 1))
    done

    sudo systemctl daemon-reload
    echo "✓ All mounts configured and will auto-mount on boot"
}
