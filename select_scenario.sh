#!/bin/bash
set -e

BASE_DIR="/home/wine"
INSTANCE_DIR="$BASE_DIR/.wine/drive_c/users/wine/AppData/Roaming/SpaceEngineersDedicated"
SCENARIOS_DIR="$BASE_DIR/Content/CustomWorlds"
CFG_FILE="$INSTANCE_DIR/SpaceEngineers-Dedicated.cfg"

echo "=== Space Engineers Scenario Selector ==="
echo

# Ensure xmlstarlet if possible
if ! command -v xmlstarlet &>/dev/null; then
  echo "⚠️ xmlstarlet not found, edits will fall back to sed."
fi

# --- Verify paths ---
if [ ! -d "$SCENARIOS_DIR" ]; then
  echo "❌ Scenarios directory not found: $SCENARIOS_DIR"
  echo "Make sure the Space Engineers server files are installed."
  exit 1
fi
mkdir -p "$INSTANCE_DIR/Saves"

# --- List available scenarios ---
echo "Available Scenarios:"
i=0
SCENARIOS=()

# ensure consistent locale and read safely
export LC_ALL=C

# Use mapfile to safely read null-separated names from find
if command -v mapfile &>/dev/null; then
    # Bash 4+ (supported even in Ubuntu docker)
    while IFS= read -r -d '' entry; do
        name=$(basename "$entry")
        SCENARIOS+=("$name")
    done < <(find "$SCENARIOS_DIR" -mindepth 1 -maxdepth 1 -type d -print0)
else
    # fallback if mapfile not available
    while IFS= read -r entry; do
        name=$(basename "$entry")
        SCENARIOS+=("$name")
    done < <(find "$SCENARIOS_DIR" -mindepth 1 -maxdepth 1 -type d)
fi

# print them neatly
for i in "${!SCENARIOS[@]}"; do
    printf "  [%d] %s\n" "$i" "${SCENARIOS[$i]}"
done

if [ ${#SCENARIOS[@]} -eq 0 ]; then
  echo "❌ No scenarios found in $SCENARIOS_DIR"
  exit 1
fi

# --- Choose scenario ---
read -p "Enter the number of the scenario you want: " choice
if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -ge "${#SCENARIOS[@]}" ]; then
  echo "Invalid selection."
  exit 1
fi
SCENARIO="${SCENARIOS[$choice]}"

# --- Ask for world name (storage root) ---
read -p "Enter a unique internal world name (no spaces): " WORLD_NAME
[ -z "$WORLD_NAME" ] && { echo "World name cannot be empty."; exit 1; }

# --- Ask for server name (visible world/session) ---
read -p "Enter a visible server/world name (no spaces): " SERVER_NAME
[ -z "$SERVER_NAME" ] && SERVER_NAME="$WORLD_NAME"

SAVE_ROOT="$INSTANCE_DIR/Saves/$WORLD_NAME"
SAVE_WORLD="$INSTANCE_DIR/Saves/$SERVER_NAME"
LOADWORLD_PATH="Z:\\home\\wine\\.wine\\drive_c\\users\\wine\\AppData\\Roaming\\SpaceEngineersDedicated\\Saves\\$SERVER_NAME"

echo
echo "Creating storage and save directories..."
mkdir -p "$SAVE_ROOT/Storage"
mkdir -p "$SAVE_WORLD"

echo "Copying scenario template..."
cp -r "$SCENARIOS_DIR/$SCENARIO/"* "$SAVE_WORLD/"
chown -R wine:wine "$SAVE_ROOT" "$SAVE_WORLD"


update_tag() {
    local tag="$1"
    local value="$2"

    # escape backslashes for sed
    value_escaped=$(printf '%s\n' "$value" | sed 's/\\/\\\\/g')

    # normalize Windows line endings
    sed -i 's/\r$//' "$CFG_FILE"

    if grep -iq "<$tag>" "$CFG_FILE"; then
        # replace existing tag
        sed -i "s|[[:space:]]*<$tag>.*</$tag>|  <$tag>$value_escaped</$tag>|I" "$CFG_FILE"
    else
        # ensure closing root tag exists
        if ! grep -iq "</MyConfigDedicated>" "$CFG_FILE"; then
            echo "</MyConfigDedicated>" >> "$CFG_FILE"
        fi
        # insert before closing tag
        sed -i "/<\/[Mm]y[Cc]onfig[Dd]edicated>/i \  <$tag>$value_escaped</$tag>" "$CFG_FILE"
    fi
}

echo "Updating SpaceEngineers-Dedicated.cfg..."
update_tag "WorldName" "$WORLD_NAME"
update_tag "ServerName" "$SERVER_NAME"
update_tag "LoadWorld" "$LOADWORLD_PATH"
update_tag "NetworkType" "steam"
update_tag "ConsoleCompatibility" "false"

echo
echo "✅ World setup complete!"
echo "Storage: $SAVE_ROOT/Storage"
echo "World:   $SAVE_WORLD"
