#!/bin/bash
set -e
echo "Initializing Wine prefix at: $WINEPREFIX"

export WINEDEBUG=-all
export WINEDLLOVERRIDES="mscoree=d"
export WINEARCH=win64

wineboot --init /nogui

# Core runtime packages (ignore SHA mismatch or conflicts)
winetricks -q corefonts
winetricks -q sound=disabled
winetricks -q --force vcrun2019
winetricks -q --force dotnet48
winetricks -q d3dcompiler_47

# Registry tweaks
wine reg add 'HKCU\Software\Wine\DllOverrides' /f /v 'd3d9' /t 'REG_SZ' /d 'native'
wine reg add "HKCU\\SOFTWARE\\Microsoft\\Avalon.Graphics" /v DisableHWAcceleration /t REG_DWORD /d 1 /f

echo "✅ Wine environment initialized in $WINEPREFIX"
