# Adding a New Service

This guide explains how to integrate a new self-hosted service into this tool.

**Start by copying an existing setup folder** and adapting it rather than writing from scratch. Use `setup-vaultwarden` as the reference for services that need backup/restore. Remove what you don't need.

---

## Folder structure

```
scripts/setup-myservice/
  start.sh          # Local launcher — required
  setup.sh          # Server-side install — required
  remove.sh         # Server-side uninstall — required
  backup.sh         # Server-side backup — required unless the service stores no data
  restore.sh        # Server-side restore — required unless the service stores no data
  config-nginx.sh   # Nginx reverse proxy config — recommended but optional
```

---

## Required files

### `start.sh` — local launcher

Runs on the **local machine**. It reads `.install`, handles the `install / uninstall / reinstall` action, and SSHes into the server to run `setup.sh` or `remove.sh`.

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
source "$SCRIPT_DIR/../.install"

case "${ACTION_MYSERVICE:-}" in
    uninstall)
        ssh root@"$SERVER_IP" 'bash ~/scripts/setup-myservice/remove.sh'
        exit 0
        ;;
    reinstall)
        ssh root@"$SERVER_IP" 'bash ~/scripts/setup-myservice/remove.sh'
        ;;
    install)
        # Optional: skip if already installed
        if ssh root@"$SERVER_IP" 'docker ps -a --format "{{.Names}}" | grep -q "^myservice$"'; then
            echo "MyService is already installed. Skipping."
            exit 0
        fi
        ;;
    *) echo "Error: ACTION_MYSERVICE must be install, uninstall, or reinstall"; exit 1 ;;
esac

ssh -t root@"$SERVER_IP" 'bash ~/scripts/setup-myservice/setup.sh'
```

Use `ssh -t` (allocate a TTY) if `setup.sh` may wait for user input (e.g. a Ctrl-C prompt). **The script should however aim to automate as best as possible the process.**

---

### `setup.sh` — server-side install

Runs on the **server** via SSH. Sources `.install` and `.backup`. Installs the service, configures Nginx, and ends by writing credentials to a temp file (if any).

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
cd "$SCRIPT_DIR"

source ~/scripts/.install
source ~/scripts/.backup

./commons/install-docker.sh
./commons/install-nginx.sh

# ... install service ...

# Write credentials (if any) to a temp file — they will be displayed at the end of setup.sh (local)
CREDS_FILE=/root/.credentials-myservice
{
    echo "=== MyService ==="
    echo "  Admin URL : https://${MYSERVICE_FQDN}/admin"
    echo "  Password  : ${MYSERVICE_PASSWORD}"
} > "${CREDS_FILE}"
chmod 600 "${CREDS_FILE}"
```

**Credential files** (`/root/.credentials-*`) are collected and displayed once at the end of the root `setup.sh`, then deleted. `/root/` is mode 700 by default; the explicit `chmod 600` adds an extra layer. Do not echo credentials directly to the terminal — write them only to this file.

**Backup.** The backup mechanism is setuped in this file as well if enabled by the user in `.backup` file. The backup implementation is up to you — direct write to a mount point (like Mailcow), rclone (like VaultWarden), or any other approach.

---

### `remove.sh` — server-side uninstall

Runs on the **server**. Must clean up everything the service creates: containers, volumes, data directories, Nginx config, cron jobs. Use `|| true` on every removal command so the script is idempotent.

```bash
#!/bin/bash
set -euo pipefail

source ~/scripts/.install

docker stop myservice 2>/dev/null || true
docker rm myservice 2>/dev/null || true
docker volume rm myservice-data 2>/dev/null || true
rm -rf "${MYSERVICE_DATA_DIR:-}"
rm -f /etc/nginx/conf.d/myservice.conf
rm -f /etc/cron.d/myservice-backup
systemctl reload nginx 2>/dev/null || true

echo "✓ MyService removed"
```

---

### `restore.sh` — server-side restore

This file is required for all services that store persistent data. The implementation is up to you, but it must satisfy the **backup/restore contract** below. See `setup-vaultwarden/restore.sh` for an example

---

## The backup/restore contract

> This is the only requirement on the backup/restore implementation. How you satisfy it is your choice.

Given:
1. The service is **freshly installed** with backup enabled in `.backup`
2. At least one backup exists on the configured remote

Running `restore.sh` must:
- Present the available backups
- Let the user select one
- **Successfully restore the service to the state captured in that backup**

A restore is only successful if the service is fully operational and its data matches the backup after the script exits. If the service needs to be stopped, restarted, or have stale files cleaned up (e.g. WAL files for SQLite), `restore.sh` is responsible for all of that.

---

### `config-nginx.sh`

Source this from `setup.sh` if the service sits behind the shared Nginx reverse proxy which is highly recommended. It should write the Nginx config to `/etc/nginx/conf.d/myservice.conf` and obtain a TLS certificate via certbot. See `setup-vaultwarden/config-nginx.sh` for a reference.

---

## Wiring up to the root `setup.sh`

Add a block to the root `setup.sh` following the same pattern as the other services:

```bash
if [ -n "${ACTION_MYSERVICE:-}" ]; then
    _installed=true
    "$SCRIPT_DIR/scripts/setup-myservice/start.sh"
fi
```

---

## Configuration variables

### `.install`

Add an `ACTION_MYSERVICE` variable and any service-specific settings. Follow the existing comment style:

```bash
# =============================================================================
# [MyService]
#
# ACTION_MYSERVICE : install | uninstall | reinstall | (empty to skip)
# MYSERVICE_FQDN   : fully qualified domain name
# MYSERVICE_DATA_DIR : host path for persistent data
# =============================================================================

ACTION_MYSERVICE=
MYSERVICE_FQDN=my.yourdomain.com
MYSERVICE_DATA_DIR=/data/myservice
```

### `.backup`

Add a section only if the service has backup-related settings. Use a consistent prefix (e.g. `MY_`):

```bash
# =============================================================================
# [MyService]
#
# MY_BACKUP_MOUNT    : mount slot index from .install (empty → backup disabled)
# MY_BACKUP_SUBDIR   : path within the mount for backups
# MY_BACKUP_CRON     : cron schedule
# MY_BACKUP_KEEP_DAYS: retention in days
# =============================================================================

MY_BACKUP_MOUNT=
MY_BACKUP_SUBDIR=backups/myservice
MY_BACKUP_CRON="0 4 * * *"
MY_BACKUP_KEEP_DAYS=30
```

---

## Commons scripts

These scripts live in `scripts/commons/` and are available to all services on the server.

| Script | What it does |
|---|---|
| `install-docker.sh` | Installs Docker via the official get-docker.sh; no-op if already installed |
| `install-nginx.sh` | Installs Nginx from the official nginx.org repo + certbot; no-op if already installed |
| `setup-mount.sh` | Provides the `mount_drives` function — source this to mount all `MOUNT_N_*` drives defined in `.install` |
| `run-mount.sh` | Thin wrapper that sources `.install` + `setup-mount.sh` and calls `mount_drives` |
| `secure-folder.sh` | Sets `~/scripts/` to `root:root 700/600` with `chmod u+x` on `.sh` files |
| `swap.sh` | Creates a swap file of a given size; no-op if already present |
| `init-server.sh` | Runs locally — rsyncs `scripts/`, `.install`, `.backup` to the server and runs `apt update` + `secure-folder.sh` |
| `toggle-ssh-forwarding.sh` | Enables/disables SSH local port forwarding; used by services that expose a local management UI |
| `port-traffic.sh` | Allows/blocks a port in the firewall |

Call them using relative paths from `$SCRIPT_DIR` (the `scripts/` directory):

```bash
./commons/install-docker.sh
./commons/install-nginx.sh
source ./commons/setup-mount.sh   # only when you need mount_drives directly
```

---

## Checklist

- [ ] `start.sh` handles `install`, `uninstall`, `reinstall`; `uninstall` exits after `remove.sh`
- [ ] `setup.sh` sources `.install` (and `.backup` if needed)
- [ ] Credentials are written to `/root/.credentials-myservice` with `chmod 600`, not echoed directly
- [ ] `remove.sh` cleans up containers, volumes, data dirs, Nginx config, and cron jobs
- [ ] `restore.sh` exist unless the service stores no persistent data
- [ ] Backup is opt-in via a variable in `.backup`; `setup.sh` installs the cron only when it is set
- [ ] The backup/restore contract is satisfied: `restore.sh` on a fresh install with existing backups restores successfully
- [ ] `.install` has `ACTION_MYSERVICE` and all service variables documented in a comment block
- [ ] `.backup` has a section with a consistent prefix if the service needs backup config
- [ ] Root `setup.sh` has an `if [ -n "${ACTION_MYSERVICE:-}" ]` block
