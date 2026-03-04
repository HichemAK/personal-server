# Personal Server Setup

Deploy self-hosted services over SSH from your local machine with a single command.

## Services

| Service | Description |
|---|---|
| [VaultWarden](https://github.com/dani-garcia/vaultwarden) | Unofficial Bitwarden-compatible password manager server |
| [Mailcow](https://github.com/mailcow/mailcow-dockerized) | Full-featured mail server suite (SMTP, IMAP, webmail, spam filtering) |
| [Nextcloud AIO](https://github.com/nextcloud/all-in-one) | Self-hosted cloud storage and collaboration platform |
| [Chhoto URL](https://github.com/SinTan1729/chhoto-url) | Minimal self-hosted URL shortener |

## Prerequisites

- A Debian-based VM accessible as `root` over SSH (both password and passwordless are required)
- Local commands: `ssh`, `rsync`
- DNS records pointing each service's domain to the server — refer to the official documentation of each service for the required records

## Quick Start
0. Remove `*.example` extension from dot files (`.install`, `.backup`, `.security`).
1. Fill in `.install` with your server IP, domains, and the services to install. All options are documented inside the file.
2. Fill in `.backup` with your backup schedule and remote storage credentials. All options are documented inside the file.
3. Run the setup:
```bash
./setup.sh
```

Credentials for installed services are displayed once at the end of the run. Save them — they will not be shown again.

## Actions

Each service is controlled by an `ACTION_<SERVICE>` variable in `.install`:

| Value | Effect |
|---|---|
| `install` | Install the service |
| `uninstall` | **Remove the service and all its data** |
| `reinstall` | **Remove everything (including data), then reinstall** |
| *(empty)* | Skip this service |

> ⚠️ **`uninstall` and `reinstall` permanently delete all service data.** There is no confirmation prompt.

## Backup & Restore

> ⚠️ **Backup is strongly recommended.** If the server is lost or data is corrupted, data that has not been backed up cannot be recovered.

Backup requires a remote storage accessible over **SFTP** (recommended), WebDAV, or SMB. Configure the connection credentials under `MOUNT_N_*` in `.install`, then set the mount index in `.backup` to enable backup for each service.

Backup settings are configured in `.backup` — schedule, remote path, and retention period. All options are documented inside the file.

### Restoring a service

> A fresh install of the service is recommended before restoring. The service must be installed and running.

Run the corresponding restore script directly on the server:

```bash
# VaultWarden
bash ~/scripts/setup-vaultwarden/restore.sh

# Mailcow
bash ~/scripts/setup-mailcow/restore.sh
```

The script fetches the list of available backups from the configured remote, lets you pick one, and restores it.



## Notes per service

### Nextcloud

To access admin page, use SSH tunneling. Execute this command:

```bash
ssh -L 9909:localhost:8080 root@IP
```

And then visit https://127.0.0.1:9909. 

There you can **enable backup** by providing a Borg remote storage. This is unfortunately not automatable at the moment and you need to look for the official documentation at https://github.com/nextcloud/all-in-one?tab=readme-ov-file#backup


### Security

Fail2ban + Cockpit is automatically setuped in addition to automatic security updates. Look in `.security` for more information. You can access Cockpit using SSH tunneling:

```
ssh -L 9909:127.0.0.1:9909 root@IP
```