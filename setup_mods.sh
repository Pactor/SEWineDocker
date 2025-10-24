#!/bin/bash
set -e

BASE_DIR="/home/wine"
INSTANCE_DIR="$BASE_DIR/.wine/drive_c/users/wine/AppData/Roaming/SpaceEngineersDedicated"
DEDICATED_CFG="$INSTANCE_DIR/SpaceEngineers-Dedicated.cfg"

echo "=== Space Engineers Mod & Config Sync ==="
echo

if [ ! -f "$DEDICATED_CFG" ]; then
  echo "❌ SpaceEngineers-Dedicated.cfg not found in $INSTANCE_DIR"
  exit 1
fi
sed -i 's/\r$//' "$DEDICATED_CFG"

# --- Locate valid worlds ---
SAVE_BASE="$INSTANCE_DIR/Saves"
WORLD_DIRS=()
while IFS= read -r -d '' dir; do
  if [ -f "$dir/Sandbox_config.sbc" ]; then
    WORLD_DIRS+=("$dir")
  fi
done < <(find "$SAVE_BASE" -mindepth 1 -maxdepth 1 -type d -print0)

if [ ${#WORLD_DIRS[@]} -eq 0 ]; then
  echo "❌ No valid worlds found in $SAVE_BASE"
  exit 1
fi

echo "Available worlds with Sandbox_config.sbc:"
for i in "${!WORLD_DIRS[@]}"; do
  printf "  [%d] %s\n" "$i" "$(basename "${WORLD_DIRS[$i]}")"
done

read -p "Select a world number: " choice
if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -ge "${#WORLD_DIRS[@]}" ]; then
  echo "Invalid selection."
  exit 1
fi

SAVE_DIR="${WORLD_DIRS[$choice]}"
SANDBOX_CFG="$SAVE_DIR/Sandbox_config.sbc"
WORLD_NAME="$(basename "$SAVE_DIR")"

echo
echo "Selected world: $WORLD_NAME"
echo "Config file: $SANDBOX_CFG"
sed -i 's/\r$//' "$SANDBOX_CFG"

# --- Helper: update or insert XML tag ---
update_tag() {
  local tag="$1"
  local value="$2"
  if grep -q "<$tag>" "$SANDBOX_CFG"; then
    sed -i "s|<$tag>.*</$tag>|<$tag>$value</$tag>|" "$SANDBOX_CFG"
  else
    sed -i "/<\/MyObjectBuilder_SessionComponent>/i \  <$tag>$value</$tag>" "$SANDBOX_CFG"
  fi
}

# --- Helper: insert mod entry ---
insert_mod() {
  local id="$1"
  local name="$2"

  if [ ! -f "$SANDBOX_CFG" ]; then
    echo "❌ Sandbox_config.sbc not found at $SANDBOX_CFG"
    return
  fi

  echo "Adding mod: \"$name\" ($id)"

  # Ensure Mods block exists
  sed -i 's|<Mods[[:space:]]*/>|<Mods>\n  </Mods>|' "$SANDBOX_CFG"
  if ! grep -q "<Mods>" "$SANDBOX_CFG"; then
    sed -i "/<\/MyObjectBuilder_SessionSettings>/i \  <Mods>\n  </Mods>" "$SANDBOX_CFG"
  fi

  # Skip duplicates
  if grep -q "<PublishedFileId>$id</PublishedFileId>" "$SANDBOX_CFG"; then
    echo "  ↳ Mod $id already present."
    return
  fi

  # Insert new ModItem
  tmp=$(mktemp)
  awk -v mid="$id" -v mname="$name" '
    /<\/Mods>/ {
      print "    <ModItem FriendlyName=\"" mname "\">"
      print "      <Name>" mid ".sbm</Name>"
      print "      <PublishedFileId>" mid "</PublishedFileId>"
      print "      <PublishedServiceName>Steam</PublishedServiceName>"
      print "    </ModItem>"
    }
    { print }
  ' "$SANDBOX_CFG" > "$tmp" && mv "$tmp" "$SANDBOX_CFG"

  echo "  ↳ Added mod: $mname ($id)"
}

# --- Sync settings from Dedicated.cfg ---
echo
echo "Syncing settings from SpaceEngineers-Dedicated.cfg..."
SERVER_NAME=$(grep -oP '(?<=<ServerName>)[^<]+' "$DEDICATED_CFG" | head -n1)

SYNC_TAGS=(
  GameMode InventorySizeMultiplier BlocksInventorySizeMultiplier
  AssemblerSpeedMultiplier AssemblerEfficiencyMultiplier
  RefinerySpeedMultiplier OnlineMode MaxPlayers
  WelderSpeedMultiplier GrinderSpeedMultiplier
  EnableOxygen EnableOxygenPressurization
  EnableDrones EnableWolfs EnableSpiders
  ExperimentalMode CrossPlatform
  SteamPort ServerPort RemoteApiPort RemoteApiEnabled
  FoodConsumptionRate
)
for tag in "${SYNC_TAGS[@]}"; do
  val=$(grep -oP "(?<=<$tag>)[^<]+" "$DEDICATED_CFG" | head -n1)
  [ -n "$val" ] && update_tag "$tag" "$val"
done

# Fix or create SessionName to match folder name
if grep -q "<SessionName>" "$SANDBOX_CFG"; then
  sed -i "s|<SessionName>.*</SessionName>|<SessionName>$WORLD_NAME</SessionName>|" "$SANDBOX_CFG"
else
  sed -i "/<\/MyObjectBuilder_SessionSettings>/i \  <SessionName>$WORLD_NAME</SessionName>" "$SANDBOX_CFG"
fi

echo "✅ Configuration synced."

# --- Mod handling loop ---
echo
echo "=== Add Steam Mods ==="
while true; do
  echo
  read -p "Enter Steam Workshop ID (or 'q' to quit): " ID
  [ "$ID" = "q" ] && break
  [ -z "$ID" ] && continue

  # Validate numeric-only input
  if ! [[ "$ID" =~ ^[0-9]+$ ]]; then
    echo "❌ Invalid ID. Please enter digits only."
    continue
  fi

  echo "Fetching mod name for ID $ID ..."
  MOD_NAME=$(curl -s "https://steamcommunity.com/sharedfiles/filedetails/?id=$ID" |
    grep -oP '(?<=<title>).*?(?=</title>)' |
    sed 's/Steam Workshop:://; s/^[[:space:]]*//; s/[[:space:]]*$//')

  [ -z "$MOD_NAME" ] && MOD_NAME="Mod_$ID"
  insert_mod "$ID" "$MOD_NAME"
done

echo
echo "✅ Mods and configuration updated:"
echo "  $SANDBOX_CFG"
