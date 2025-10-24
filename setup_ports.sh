#!/bin/bash
set -euo pipefail

# === Host-side port setup ===
ENV_FILE="ports.env"

echo
echo "=============================================="
echo " ⚙️  Space Engineers Port Configuration"
echo "=============================================="
echo
echo "This script defines the network ports that will be used"
echo "for your Space Engineers dedicated server."
echo "They are saved in $ENV_FILE and reused by future scripts."
echo

read -p "Game Port [27016]: " GAME_PORT
read -p "Steam Port [8766]: " STEAM_PORT
read -p "Remote API (RCON) Port [8080]: " RCON_PORT

GAME_PORT=${GAME_PORT:-27016}
STEAM_PORT=${STEAM_PORT:-8766}
RCON_PORT=${RCON_PORT:-8080}

cat > "$ENV_FILE" <<EOF
# Generated $(date)
export GAME_PORT=$GAME_PORT
export STEAM_PORT=$STEAM_PORT
export RCON_PORT=$RCON_PORT
EOF

echo
echo "✅ Ports saved:"
cat "$ENV_FILE"
echo
echo "Next step:"
echo "  1️⃣ Build your Docker image if not already built:"
echo "      docker build -t wine-server ."
echo
echo "  2️⃣ Run: ./init_docker.sh  (to create and start the container)"
echo
