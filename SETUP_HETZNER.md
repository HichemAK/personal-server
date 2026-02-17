# Setup
Date: 9 February 2026

Use-case: You want to setup a server in Hetzner whose main storage is a Storage Box. Here are the requirements of each of the scenatios below. 

Once they are met, launch `setup.sh` at the root of this project, select a scenario, and follow the instructions.


## Requirements

All of following scenarios suppose you have the following hardware:
- 1TB Hetzner Storage Box (BX11): Enable access through password and enable one of SMB Support/WebDAV/SSH Support 
- VM - 4vCPUs + 8GB RAM + 80GB SSD (CX33): Use Debian as an OS. Grant your local machine SSH access to this VM (passwordless).

You need a **setuped domain** with the approriate DNS records. Look at the official documentation of the tool you want to install.
