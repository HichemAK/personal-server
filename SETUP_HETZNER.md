# Setup
Date: 9 February 2026

Use-case: You want to setup a server in Hetzner whose main storage is a Storage Box

## Scenario 1: Install OpenMediaVault
1. Open these two resources in Hetzner:
    - 1TB Hetzner Storage Box (BX11): Use Debian as an OS
    - VM - 2vCPUs + 4GB RAM + 40GB SSD (CX23): Enable SMB Support + WebDAV + SSH Support
2. Grant your local machine SSH access to the VM.
3. Make the Storage Box accessible through an SSH key whose public and private part should be located in `scripts/setup-omv` (they will be copied to the VM).
3. Launch `scripts/setup-omv/init.sh` (in local machine NOT VM!) and follow carefully the instructions (you will have to provide information)
4. Enjoy!

## Scenario 2: Install NextCloud
1. Open these two resources in Hetzner:
    - 1TB Hetzner Storage Box (BX11): Use Debian as an OS
    - VM - 2vCPUs + 4GB RAM + 40GB SSD (CX23): Enable SMB Support + WebDAV + SSH Support
2. Grant your local machine SSH access to the VM.
3. Make the Storage Box accessible through an SSH key whose public and private part should be located in `scripts/setup-omv` (they will be copied to the VM).
3. Launch `scripts/setup-omv/init.sh` (in local machine NOT VM!) and follow carefully the instructions (you will have to provide information)
4. Enjoy!