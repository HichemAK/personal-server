#!/bin/bash
# config-backup.sh — Configure the rclone remote for VaultWarden backup
# using the MOUNT_N_* credentials already defined in .install.
set -euo pipefail

source ~/scripts/.install
source ~/scripts/.backup

if [ -z "${VW_BACKUP_MOUNT:-}" ]; then
    echo "VW_BACKUP_MOUNT is not set in .backup — skipping backup configuration."
    exit 0
fi

if [ -z "${VW_BACKUP_ZIP_PASSWORD:-}" ]; then
    echo "Error: VW_BACKUP_ZIP_PASSWORD is not set in .backup"
    exit 1
fi

N="${VW_BACKUP_MOUNT}"
REMOTE_NAME="VaultWardenBackup"

# Read mount variables dynamically
eval "MOUNT_TYPE=\"\${MOUNT_${N}_TYPE:-}\""
eval "MOUNT_USER=\"\${MOUNT_${N}_USER:-}\""
eval "MOUNT_ADDRESS=\"\${MOUNT_${N}_ADDRESS:-}\""
eval "MOUNT_PASS=\"\${MOUNT_${N}_PASS:-}\""
eval "MOUNT_PORT=\"\${MOUNT_${N}_PORT:-22}\""

if [ -z "$MOUNT_TYPE" ] || [ "$MOUNT_TYPE" = "none" ]; then
    echo "Error: MOUNT_${N}_TYPE is '${MOUNT_TYPE:-unset}' — cannot use as backup remote."
    exit 1
fi

if [ -z "$MOUNT_USER" ] || [ -z "$MOUNT_ADDRESS" ] || [ -z "$MOUNT_PASS" ]; then
    echo "Error: MOUNT_${N}_USER, MOUNT_${N}_ADDRESS and MOUNT_${N}_PASS must all be set in .install."
    exit 1
fi

echo "=== Configuring rclone remote '${REMOTE_NAME}' from mount ${N} (${MOUNT_TYPE}) ==="

# Obscure the password (rclone requires its own encoding for stored credentials)
RCLONE_PASS="$(docker run --rm \
    ttionya/vaultwarden-backup:latest \
    rclone obscure "${MOUNT_PASS}")"

case "${MOUNT_TYPE}" in
    sftp)
        docker run --rm \
            --mount type=volume,source=vaultwarden-rclone-data,target=/config/ \
            ttionya/vaultwarden-backup:latest \
            rclone config create "${REMOTE_NAME}" sftp \
                host="${MOUNT_ADDRESS}" \
                user="${MOUNT_USER}" \
                pass="${RCLONE_PASS}" \
                port="${MOUNT_PORT}"
        ;;
    smb)
        docker run --rm \
            --mount type=volume,source=vaultwarden-rclone-data,target=/config/ \
            ttionya/vaultwarden-backup:latest \
            rclone config create "${REMOTE_NAME}" smb \
                host="${MOUNT_ADDRESS}" \
                user="${MOUNT_USER}" \
                pass="${RCLONE_PASS}"
        ;;
    webdav)
        docker run --rm \
            --mount type=volume,source=vaultwarden-rclone-data,target=/config/ \
            ttionya/vaultwarden-backup:latest \
            rclone config create "${REMOTE_NAME}" webdav \
                url="${MOUNT_ADDRESS}" \
                user="${MOUNT_USER}" \
                pass="${RCLONE_PASS}"
        ;;
    *)
        echo "Error: mount type '${MOUNT_TYPE}' is not supported for rclone (supported: sftp, smb, webdav)."
        exit 1
        ;;
esac

echo "✓ rclone remote '${REMOTE_NAME}' configured from mount ${N}"
