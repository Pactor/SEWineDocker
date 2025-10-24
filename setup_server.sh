#!/bin/bash
set -euo pipefail

BASE_DIR="/home/wine"
STEAMCMD_DIR="${BASE_DIR}/steamcmd"
SERVER_ID="298740"  # Space Engineers Dedicated Server App ID

echo "🔧 Space Engineers setup..."

# 1️⃣ Ensure directories exist
mkdir -p "$STEAMCMD_DIR"
cd "$BASE_DIR"

# 4️⃣ Install SteamCMD if missing
if [ ! -f "${STEAMCMD_DIR}/steamcmd.sh" ]; then
  echo "⬇️ Installing SteamCMD..."
  mkdir -p "$STEAMCMD_DIR"
  cd "$STEAMCMD_DIR"
  wget -qO- https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar -xz
fi

# 5️⃣ Install or update Space Engineers Dedicated Server
echo "🚀 Installing / Updating Space Engineers Dedicated Server via SteamCMD..."
cd "$STEAMCMD_DIR"
xvfb-run --auto-servernum ./steamcmd.sh +@sSteamCmdForcePlatformType windows \
  +force_install_dir "${BASE_DIR}" \
  +login anonymous \
  +app_update ${SERVER_ID} validate +quit


echo "✅ Setup complete."
echo "Space Engineers server: ${BASE_DIR}/DedicatedServer64"
