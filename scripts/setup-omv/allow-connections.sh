echo ""
echo "🔓 Opening web access..."
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
echo "✓ Web accessible from anywhere"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
cd $SCRIPT_DIR
echo "Deactivate SSH forwarding..."
./commons/toggle-ssh-forwarding.sh no
echo "✓ Done"
