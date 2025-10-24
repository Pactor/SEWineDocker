#!/bin/bash
set -euo pipefail

BASE_DIR="/home/wine"
INSTANCE_DIR="${BASE_DIR}/.wine/drive_c/users/wine/AppData/Roaming/SpaceEngineersDedicated"
DEDICATED_CFG="${INSTANCE_DIR}/SpaceEngineers-Dedicated.cfg"
ENV_FILE="/home/wine/scripts/ports.env"

echo
echo "=============================================="
echo "  🌍 World Installer & Verifier"
echo "=============================================="

mkdir -p "$INSTANCE_DIR"
cp -f "${BASE_DIR}/scripts/SpaceEngineers-Dedicated.cfg" "$DEDICATED_CFG"

# --- Fix env file permissions ---
if [ -f "$ENV_FILE" ]; then
  echo "Fixing env file permissions..."
  (chown wine:wine "$ENV_FILE" 2>/dev/null || true)
  source "$ENV_FILE"
else
  echo "❌ Missing $ENV_FILE. Run setup_ports.sh and init_docker.sh on host first."
  exit 1
fi

echo
echo "SE server verified."
echo "Dedicated : $DEDICATED_CFG"
echo

# === List valid worlds ===
SAVE_BASE="$INSTANCE_DIR/Saves"
mapfile -t WORLDS < <(find "$SAVE_BASE" -mindepth 1 -maxdepth 1 -type d -exec test -f '{}/Sandbox_config.sbc' \; -print)

if [ ${#WORLDS[@]} -eq 0 ]; then
  echo "❌ No valid worlds found (no Sandbox_config.sbc present)."
  read -p "Create a new game world now? (y/n): " CREATE_WORLD
  if [[ "$CREATE_WORLD" =~ ^[Yy]$ ]]; then
    bash /home/wine/scripts/select_scenario.sh
  else
    echo "Exiting."
    exit 0
  fi
else
  echo "📂 Available valid worlds:"
  for i in "${!WORLDS[@]}"; do
    printf "  [%d] %s\n" "$i" "$(basename "${WORLDS[$i]}")"
  done

  while true; do
    read -p "Select a world number (or 'n' to create new): " choice
    if [[ "$choice" =~ ^[Nn]$ ]]; then
      bash /home/wine/scripts/select_scenario.sh
      break
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 0 ] && [ "$choice" -lt "${#WORLDS[@]}" ]; then
      WORLD="${WORLDS[$choice]}"
      echo "✅ Selected existing world: $(basename "$WORLD")"
      break
    else
      echo "❌ Invalid selection. Please try again."
    fi
  done
fi

read -p "Add mods now? (y/n): " ADD_MODS
if [[ "$ADD_MODS" =~ ^[Yy]$ ]]; then
  bash /home/wine/scripts/setup_mods.sh
fi

read -p "Configure game configs now? (y/n): " CONFIG_GAME
if [[ "$CONFIG_GAME" =~ ^[Yy]$ ]]; then
  bash /home/wine/scripts/configure_game.sh
fi
