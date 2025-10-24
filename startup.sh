
#!/bin/bash
set -e

USERDIR="/home/wine"
SAVEDIR="$USERDIR/.wine/drive_c/users/wine/AppData/Roaming/SpaceEngineersDedicated/Saves"

clear
echo "────────────────────────────────────────────"
echo "   🚀 Server Environment Loaded"
echo "────────────────────────────────────────────"
echo "Working directory: $USERDIR"
echo

if [ ! -d "$SAVEDIR" ] || [ -z "$(ls -A "$SAVEDIR" 2>/dev/null)" ]; then
    echo "⚠️  No worlds detected in:"
    echo "   $SAVEDIR"
    echo
    echo "You can always changes settings"
    echo "   the scripts directory contains the tools you need"
    echo "   install_world.sh will run them all "
    echo "   select_senario.sh  "
    echo "   configure_game.sh "
    echo "   setup_mods.sh "
    echo "   select_plugins.sh"
    echo "   run.sh"
    echo " "
    echo
else
    echo "✅ ServerGame found at $SAVEDIR"
    echo "You can start Server now using:"
    echo "/home/$(whoami)/scripts/run.sh"
    echo "You can always changes settings"
    echo "   the scripts directory contains the tools you need"
    echo "   install_world.sh will run them all "
    echo "   select_senario.sh  "
    echo "   configure_game.sh "
    echo "   setup_mods.sh "
    echo "   select_plugins.sh"
    echo "   run.sh"
    echo " "

fi

echo "────────────────────────────────────────────"
