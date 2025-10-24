#!/bin/bash
set -e

BASE_DIR="/home/wine"
INSTANCE_DIR="$BASE_DIR/.wine/drive_c/users/wine/AppData/Roaming/SpaceEngineersDedicated"
CFG_FILE="$INSTANCE_DIR/SpaceEngineers-Dedicated.cfg"
ENV_FILE="/home/wine/scripts/ports.env"
SAVES_DIR="$INSTANCE_DIR/Saves"

echo "=== Space Engineers Configuration ==="

# --- Select savegame ---
echo "🔍 Searching for valid savegames..."
mapfile -t WORLDS < <(find "$SAVES_DIR" -maxdepth 1 -type d -exec test -f '{}/Sandbox_config.sbc' \; -print)
if [ ${#WORLDS[@]} -eq 0 ]; then
  echo "❌ No valid savegames found."
  exit 1
fi

echo "📂 Available savegames:"
select WORLD in "${WORLDS[@]}"; do
  if [ -n "$WORLD" ]; then
    SANDBOX_FILE="$WORLD/Sandbox_config.sbc"
    echo "✅ Selected world: $WORLD"
    break
  else
    echo "Invalid choice, try again."
  fi
done

# --- Load ports ---
if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE"
else
  echo "⚠️ No $ENV_FILE — using defaults."
  GAME_PORT=27016
  STEAM_PORT=8766
  RCON_PORT=8080
fi

mkdir -p "$INSTANCE_DIR"
cp "$CFG_FILE" "${CFG_FILE}.bak"

update_tag() {
  local tag="$1" value="$2"
  if grep -q "<$tag>" "$CFG_FILE"; then
    sed -i "s|<$tag>.*</$tag>|<$tag>$value</$tag>|" "$CFG_FILE"
  else
    sed -i "/<\/MyConfigDedicated>/i \  <$tag>$value</$tag>" "$CFG_FILE"
  fi
  if grep -q "<$tag>" "$SANDBOX_FILE"; then
    sed -i "s|<$tag>.*</$tag>|<$tag>$value</$tag>|" "$SANDBOX_FILE"
  fi
}

# --- Validators ---
ask() {
  local prompt="$1" def="$2" type="$3" val
  while true; do
    read -p "$prompt [$def]: " val
    val="${val:-$def}"

    # reject unsafe characters (/ \ &)
    if [[ "$val" =~ [\/\\\&] ]]; then
      echo "❌ Invalid input: contains /, \\ or & — please try again."
      continue
    fi

    case "$type" in
      bool)
        [[ "$val" =~ ^(true|false)$ ]] && break ;;
      int)
        [[ "$val" =~ ^[0-9]+$ ]] && break ;;
      float)
        [[ "$val" =~ ^[0-9]*\.?[0-9]+$ ]] && break ;;
      text)
        [ -n "$val" ] && break ;;
    esac
    echo "❌ Invalid input for $prompt"
  done
  echo "$val"
}

echo
echo "=== Configure Game Settings ==="
echo "Press Enter to keep default values."

GAME_MODE=$(ask "Game mode (Creative/Survival)" "Survival" text)
INV_MULTI=$(ask "Inventory size multiplier (1-100)" "3" int)
BLK_INV_MULTI=$(ask "Blocks inventory size multiplier (1-100)" "1" int)
ASM_SPEED=$(ask "Assembler speed multiplier (1-100)" "3" int)
ASM_EFF=$(ask "Assembler efficiency multiplier (1-100)" "3" int)
REF_SPEED=$(ask "Refinery speed multiplier (1-100)" "3" int)
ONLINE_MODE=$(ask "Online mode (OFFLINE/PUBLIC/FRIENDS/PRIVATE)" "PUBLIC" text)
MAX_PLAYERS=$(ask "Max players" "4" int)
WELDER_SPEED=$(ask "Welder speed multiplier (1-100)" "2" int)
GRINDER_SPEED=$(ask "Grinder speed multiplier (1-100)" "2" int)
ENABLE_O2=$(ask "Enable oxygen (true/false)" "true" bool)
ENABLE_PRESS=$(ask "Enable oxygen pressurization (true/false)" "true" bool)
ENABLE_DRONES=$(ask "Enable drones (true/false)" "true" bool)
ENABLE_WOLFS=$(ask "Enable wolfs (true/false)" "false" bool)
ENABLE_SPIDERS=$(ask "Enable spiders (true/false)" "false" bool)
EXPERIMENTAL=$(ask "Enable experimental mode (true/false)" "false" bool)
ENABLE_SCRIPTS=$(ask "Enable scripting (true/false)" "false" bool)
CROSSPLATFORM=$(ask "Enable cross-platform (true/false)" "false" bool)
IP_ADDR=$(ask "Server IP (0.0.0.0 for all)" "0.0.0.0" text)
REMOTE_API=$(ask "Enable remote API (true/false)" "true" bool)
FOOD_RATE=$(ask "Food consumption rate (0.1–1.0)" "0.5" float)
PHYSICS=$(ask "Set PhysicsIterations" "8" int)
SYNC=$(ask "Set SyncDistance" "3000" int)
VIEW=$(ask "Set ViewDistance" "1500" int)

update_tag "GameMode" "$GAME_MODE"
update_tag "InventorySizeMultiplier" "$INV_MULTI"
update_tag "BlocksInventorySizeMultiplier" "$BLK_INV_MULTI"
update_tag "AssemblerSpeedMultiplier" "$ASM_SPEED"
update_tag "AssemblerEfficiencyMultiplier" "$ASM_EFF"
update_tag "RefinerySpeedMultiplier" "$REF_SPEED"
update_tag "OnlineMode" "$ONLINE_MODE"
update_tag "MaxPlayers" "$MAX_PLAYERS"
update_tag "WelderSpeedMultiplier" "$WELDER_SPEED"
update_tag "GrinderSpeedMultiplier" "$GRINDER_SPEED"
update_tag "EnableOxygen" "$ENABLE_O2"
update_tag "EnableOxygenPressurization" "$ENABLE_PRESS"
update_tag "EnableDrones" "$ENABLE_DRONES"
update_tag "EnableWolfs" "$ENABLE_WOLFS"
update_tag "EnableSpiders" "$ENABLE_SPIDERS"
update_tag "ExperimentalMode" "$EXPERIMENTAL"
update_tag "EnableIngameScripts" "$ENABLE_SCRIPTS"
update_tag "CrossPlatform" "$CROSSPLATFORM"
update_tag "IP" "$IP_ADDR"
update_tag "SteamPort" "$STEAM_PORT"
update_tag "ServerPort" "$GAME_PORT"
update_tag "RemoteApiEnabled" "$REMOTE_API"
update_tag "RemoteApiPort" "$RCON_PORT"
update_tag "FoodConsumptionRate" "$FOOD_RATE"
update_tag "NetworkType" "steam"
update_tag "ConsoleCompatibility" "false"
update_tag "PhysicsIterations" "$PHYSICS"
update_tag "SyncDistance" "$SYNC"
update_tag "ViewDistance" "$VIEW"

echo
echo "✅ Configuration complete!"
echo "Dedicated server: $CFG_FILE (backup: ${CFG_FILE}.bak)"
echo "World updated: $SANDBOX_FILE"

read -p "Start server now? (y/n): " START_NOW
if [[ "$START_NOW" =~ ^[Yy]$ ]]; then
  bash /home/wine/scripts/torch_run.sh
else
  echo
  echo "⚙️ Setup complete. Start later with:"
  echo "   bash /home/wine/scripts/torch_run.sh"
fi
