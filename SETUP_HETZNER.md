# Setup
Date: 9 February 2026

Use-case: You want to setup a server in Hetzner whose main storage is a Storage Box. Here are the requirements of each of the scenatios below. 

Once they are met, launch `setup.sh` at the root of this project, select a scenario, and follow the instructions.

## Scenario 1: Install OpenMediaVault
1. Open these two resources in Hetzner:
    - 1TB Hetzner Storage Box (BX11): Use Debian as an OS
    - VM - 2vCPUs + 4GB RAM + 40GB SSD (CX23): Enable SMB Support + WebDAV + SSH Support
2. Grant your local machine SSH access to the VM (passwordless).
3. If you want to mount the Storage Box as SFTP, make it accessible through an SSH key whose public and private part should be located in `scripts/commons` (they will be copied to the VM).

## Scenario 2: Install NextCloud
1. Open these two resources in Hetzner:
    - 1TB Hetzner Storage Box (BX11): Use Debian as an OS
    - VM - 2vCPUs + 4GB RAM + 40GB SSD (CX23): Enable SMB Support + WebDAV + SSH Support
2. Grant your local machine SSH access to the VM (passwordless).
3. Make the Storage Box accessible through an SSH key whose public and private part should be located in `scripts/commons` (they will be copied to the VM).
