#!/bin/bash
# backup.sh — Back up Chhoto URL's SQLite database to the configured mount.
set -euo pipefail

source ~/scripts/.install
source ~/scripts/.backup

if [ -z "${CU_BACKUP_MOUNT:-}" ]; then
    echo "Error: CU_BACKUP_MOUNT is not set in .backup"
    exit 1
fi

N="${CU_BACKUP_MOUNT}"
eval "MOUNT_POINT=\"\${MOUNT_${N}_POINT:-}\""

if [ -z "${MOUNT_POINT:-}" ]; then
    echo "Error: MOUNT_${N}_POINT is not set in .install"
    exit 1
fi

BACKUP_DIR="${MOUNT_POINT}/${CU_BACKUP_SUBDIR:-backups/chhoto}"
mkdir -p "${BACKUP_DIR}"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTFILE="${BACKUP_DIR}/chhoto_${TIMESTAMP}.sqlite.gz.enc"

echo "=== Backing up Chhoto URL to ${BACKUP_DIR} ==="

cd ~/scripts/setup-chhoto

# Read the auto-generated password from compose.yaml
CHHOTO_PASSWORD=$(yq '.services.chhoto-url.environment.password' ~/scripts/setup-chhoto/compose.yaml)

# Check if the database exists before stopping the container
if ! docker run --rm -v chhoto-db:/db:ro alpine sh -c 'test -f /db/urls.sqlite'; then
    echo "No database file found (no URLs created yet), skipping backup"
    exit 0
fi

# Stop the container to ensure a clean copy with no pending WAL transactions
docker compose stop chhoto-url

docker run --rm \
    -v chhoto-db:/db:ro \
    alpine sh -c 'cat /db/urls.sqlite' \
    | gzip \
    | openssl enc -aes-256-cbc -pbkdf2 -pass pass:"${CHHOTO_PASSWORD}" > "${OUTFILE}"

docker compose start chhoto-url

# Retention: remove dumps older than CU_BACKUP_KEEP_DAYS
find "${BACKUP_DIR}" -name "chhoto_*.sqlite.gz.enc" -mtime "+${CU_BACKUP_KEEP_DAYS:-30}" -delete

echo "✓ Chhoto URL backup complete: ${OUTFILE}"
