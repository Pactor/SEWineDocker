#!/bin/bash
set -euo pipefail
BASE="${1:-/home/$(whoami)/DedicatedServer64}"
test -f "$BASE/SpaceEngineersDedicated.exe" || { echo "SpaceEngineersDedicated.exe not found in $BASE"; exit 1; }

WINE_BASE="Z:\\$(echo "$BASE" | sed 's#^/##; s#/#\\#g')"
cd "$BASE"
echo "Starting SpaceEngineersDedicated.exe from ${WINE_BASE}"
env WINEDEBUG=-all wine SpaceEngineersDedicated.exe -console &
