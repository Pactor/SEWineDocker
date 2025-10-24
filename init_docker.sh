#!/bin/bash
set -euo pipefail

ENV_FILE="ports.env"
CONTAINER_NAME="sewine"
IMAGE_NAME="wine-server"

if [ ! -f "$ENV_FILE" ]; then
  echo "❌ Missing $ENV_FILE. Run ./setup_ports.sh first."
  exit 1
fi
source "$ENV_FILE"

echo
echo "=============================================="
echo "  🚀 Docker Initializer"
echo "=============================================="
echo
echo "Container : $CONTAINER_NAME"
echo "Image     : $IMAGE_NAME"
echo "Game Port : $GAME_PORT/udp"
echo "Steam Port: $STEAM_PORT/udp"
echo "RCON Port : $RCON_PORT/tcp"
echo

# 1️⃣ Ensure Docker is available
if ! command -v docker &>/dev/null; then
  echo "❌ Docker not installed or not in PATH."
  exit 1
fi

# 2️⃣ Check if container already exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "✅ Container '${CONTAINER_NAME}' already exists."
  echo "Use: docker start -ai ${CONTAINER_NAME} to start it."
  exit 0
fi

# 3️⃣ Create container
echo "🚀 Creating and running new '${CONTAINER_NAME}' container..."
docker run -dit --name "${CONTAINER_NAME}" \
  -p "${GAME_PORT}:${GAME_PORT}/udp" \
  -p "${STEAM_PORT}:${STEAM_PORT}/udp" \
  -p "${RCON_PORT}:${RCON_PORT}/tcp" \
  "${IMAGE_NAME}"

# 4️⃣ Copy environment file and make read-only
docker cp "$ENV_FILE" "${CONTAINER_NAME}:/home/wine/scripts/ports.env"

# 5️⃣ Run setup inside container before attaching
echo
echo "⚙️ Running initial Space Engineers setup inside container..."
docker exec -it "${CONTAINER_NAME}" bash -c "/home/wine/scripts/setup_server.sh"

# 6️⃣ Attach interactively
echo
echo "📡 Attaching to container for interactive session..."
docker attach "${CONTAINER_NAME}"
