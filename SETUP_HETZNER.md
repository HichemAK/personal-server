# Setup
Date: 9 February 2026


1. Open these two resources in Hetzner:
    - 1TB Hetzner Storage Box (BX11): Use Debian as an OS
    - VM - 2vCPUs + 4GB RAM + 40GB SSD (CX23): Enable SMB Support + WebDAV + SSH Support

2. Copy all files in this folder to `/root/setup` in the Hetzner VM using `rsync -avz --exclude='.git' . root@XXX.XXX.XXX.XXX:/root/server`
3. SSH into VM, `cd /root/server` and launch `setup.sh` and enter the required information
4. Enjoy!