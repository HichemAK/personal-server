#!/bin/bash
# port-traffic.sh — Block or allow ports (SSH tunneling still works)
# Usage:
#   ./port-traffic.sh block 8080 9909       # Block ports 8080 and 9909
#   ./port-traffic.sh allow 8080 9909       # Allow ports 8080 and 9909
set -euo pipefail

ACTION="${1:-}"
shift || true
PORTS=("$@")

if [ -z "$ACTION" ] || [ ${#PORTS[@]} -eq 0 ]; then
    echo "Usage: $0 <block|allow> <port1> [port2] ..."
    exit 1
fi

sudo apt install -y iptables-persistent -qq

case "$ACTION" in
    block)
        for PORT in "${PORTS[@]}"; do
            sudo iptables -I INPUT -p tcp --dport "$PORT" ! -i lo -j DROP
            sudo iptables -I DOCKER -p tcp --dport "$PORT" -j DROP 2>/dev/null || true
            echo "✓ Port $PORT blocked (SSH tunneling still allowed)"
        done
        ;;
    allow)
        for PORT in "${PORTS[@]}"; do
            sudo iptables -D INPUT -p tcp --dport "$PORT" ! -i lo -j DROP 2>/dev/null || true
            sudo iptables -D DOCKER -p tcp --dport "$PORT" -j DROP 2>/dev/null || true
            echo "✓ Port $PORT allowed"
        done
        ;;
    *)
        echo "Unknown action: $ACTION (use 'block' or 'allow')"
        exit 1
        ;;
esac

sudo netfilter-persistent save
