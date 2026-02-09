echo ""
echo "🔓 Opening web access..."
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
echo "✓ Web accessible from anywhere"
echo ""