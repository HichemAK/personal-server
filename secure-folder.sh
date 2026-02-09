#!/bin/bash
# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change ownership recursively
sudo chown -R root:root "$SCRIPT_DIR"

# Set permissions: 700 for directories, 600 for files
sudo find "$SCRIPT_DIR" -type d -exec chmod 700 {} \;
sudo find "$SCRIPT_DIR" -type f -exec chmod 600 {} \;