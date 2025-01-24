#!/usr/bin/env bash

#===============================================================================
# TruckersMP Installer for Linux
# Version: 1.0.0
# Author: rs189
# License: MIT
# Description: Installs and configures TruckersMP for Euro Truck Simulator 2 using Wine
#===============================================================================

IFS=$'\n\t'

export WINEPREFIX="$HOME/.local/share/Steam/steamapps/compatdata/227300/pfx" 
export WINEFSYNC=1

# Configuration
readonly VERSION="1.0.0"
readonly REQUIRED_WINE_VERSION="9.15"

# Paths
readonly LOG_FILE="/tmp/truckersmp_installer.log"
readonly UMU_BASE="$HOME/.steam/steam/compatibilitytools.d/UMU-Proton-9.0-3.2/files/bin"
readonly WINESERVER="$UMU_BASE/wineserver"
readonly WINE64="$UMU_BASE/wine64"
readonly DEFAULT_STEAM_PATH="$HOME/.local/share/Steam"
readonly DEFAULT_ETS2_PATH="$DEFAULT_STEAM_PATH/steamapps/common"
readonly TRUCKERSMP_PATH="$WINEPREFIX/dosdevices/c:/users/$USER/AppData/Local/TruckersMP/app-1.3.13"

# Logger
log() {
    local level=$1
    shift
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "$LOG_FILE"
}

error() {
    log "ERROR" "$*"
    if command -v zenity >/dev/null 2>&1; then
        zenity --error --text="$*"
    fi
}

info() {
    log "INFO" "$*"
    if command -v zenity >/dev/null 2>&1; then
        zenity --info --text="$*"
    fi
}

# Cleanup handler
cleanup() {
    log "INFO" "Cleaning up..."
    $WINESERVER -k
    rm -f tmp.$$.json

    # Remove the setup file if it exists
    #if [ -f "TruckersMP-Setup.exe" ]; then
    #    rm "TruckersMP-Setup.exe"
    #fi
}

# Check dependencies
check_dependencies() {
    local deps=(wine zenity jq wget bc)
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            error "Required dependency '$dep' is not installed"
            exit 1
        fi
    done
}

check_umu_proton() {
    if [ ! -f "$WINESERVER" ] || [ ! -f "$WINE64" ]
    then
        # info "UMU-Proton-9.0 or higher is required. Downloading UMU-Proton-9.0-3.2"
        log "INFO" "Downloading UMU-Proton-9.0-3.2"
        wget https://github.com/Open-Wine-Components/umu-proton/releases/download/UMU-Proton-9.0-3.2/UMU-Proton-9.0-3.2.tar.gz -P /tmp
        tar -xvf /tmp/UMU-Proton-9.0-3.2.tar.gz -C ~/.steam/steam/compatibilitytools.d
        rm /tmp/UMU-Proton-9.0-3.2.tar.gz
    fi
}

check_wine_version() {
    local wine_version
    # Extract only numeric part and handle rc versions
    wine_version=$(wine --version | grep -oP '\d+\.\d+(?=-rc|\b)' || echo "0.0")
    
    log "INFO" "Detected Wine version: $wine_version"
    
    if ! awk -v ver="$wine_version" -v req="$REQUIRED_WINE_VERSION" 'BEGIN{exit !(ver >= req)}'; then
        # error "Wine version $wine_version is lower than required version $REQUIRED_WINE_VERSION, please upgrade"
        echo "ERROR:Wine version $wine_version is lower than required version $REQUIRED_WINE_VERSION."
        exit 1
    fi
}

install_winetricks() {
    # Define the path to the winetricks script
    script_path="/tmp/winetricks"
    
    # Check if the winetricks script exists
    if [ ! -f "$script_path" ]; then
        echo "INFO: Downloading winetricks"
        wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks -P /tmp
    fi
    
    chmod +x "$script_path"
    $WINESERVER -k
    "$script_path" --force -q corefonts
    $WINESERVER -k
}

create_desktop_entry() {
    local desktop_path="$HOME/.local/share/applications/wine/Programs/TruckersMP/TruckersMP.desktop"
    if [ -f "$desktop_path" ]; then
        rm "$desktop_path"
    fi
    desktop_path="$HOME/.local/share/applications/TruckersMP.desktop"

    #local exec="env WINEPREFIX=\"$WINEPREFIX\" wine C:\\\\users\\\\$USER\\\\AppData\\\\Roaming\\\\Microsoft\\\\Windows\\\\Start\\\\ Menu\\\\Programs\\\\TruckersMP\\\\TruckersMP.lnk"

    # Create a shell script to launch the TruckersMP launcher
    cat <<EOF > "$TRUCKERSMP_PATH/truckersmp-launcher.sh"
#!/bin/bash
export WINEPREFIX="$WINEPREFIX"
export WINESERVER="$WINESERVER"
export WINE64="$WINE64"
export WINEFSYNC=1
export TRUCKERSMP_PATH="$TRUCKERSMP_PATH"

cd "\$TRUCKERSMP_PATH"
\$WINESERVER -k
\$WINE64 "\$TRUCKERSMP_PATH/TruckersMP-Launcher.exe" &
TRUCKERSMP_LAUNCHER_PID=\$!

# Function to launch winediscordipcbridge
launch_ipcbridge() {
    \$WINE64 \$TRUCKERSMP_PATH/winediscordipcbridge.exe &
    IPCBRIDGE_PID=\$!
}

exit_count=0
max_exit_count=3

while true; do
    if ! kill -0 \$IPCBRIDGE_PID 2>/dev/null; then
        echo "winediscordipcbridge.exe not running, restarting..."
        launch_ipcbridge
    fi

    if ps aux | grep -i "eurotrucks2.exe" > /dev/null; then
        exit_count=0
    fi

    if ps aux | ps aux | grep "TruckersMP-Launcher.exe" > /dev/null; then
        exit_count=0
    fi

    if ! ps aux | grep -i "eurotrucks2.exe" > /dev/null && ! ps aux | grep "TruckersMP-Launcher.exe" > /dev/null; then
        exit_count=$((exit_count + 1))
        echo "Both applications have exited \$exit_count times consecutively."
        
        if [ \$exit_count -ge \$max_exit_count ]; then
            echo "Both applications have exited 3 times consecutively. Exiting loop..."
            kill 2>/dev/null
            break
        fi
    else
        exit_count=0
    fi

    sleep 5
done

echo "TruckersMP Launcher has exited, killing winediscordipcbridge.exe"
kill \$IPCBRIDGE_PID 2>/dev/null

EOF
    chmod +x "$TRUCKERSMP_PATH/truckersmp-launcher.sh"
    
    echo "Creating desktop file"
    mkdir -p "$(dirname "$desktop_path")"
    cat <<EOF > "$desktop_path"
[Desktop Entry]
Name=TruckersMP
Exec=$TRUCKERSMP_PATH/truckersmp-launcher.sh
Type=Application
StartupNotify=true
Comment=Launcher for TruckersMP
Path=$TRUCKERSMP_PATH
Icon=F0C0_TruckersMP-Launcher.0
StartupWMClass=truckersmp-launcher.exe
EOF
}

update_game_path() {
    # Default ets2 path
    ets2_path="$HOME/.local/share/Steam/steamapps/common/"

    # Show a file dialog to select the ETS2 path
    echo "Select the ETS2 path"
    # Folder selection dialog using zenity
    selected_folder=$(zenity --file-selection --directory --title="Path to the Euro Truck Simulator 2 directory" --filename=$ets2_path)
    #selected_folder=$(python3 select_folder.py "$ets2_path")

    # Check if the user canceled the dialog
    if [ $? -ne 0 ]; then
        # zenity --error --text="No folder selected. Exiting..."
        echo "ERROR:No folder selected."
        exit 1
    fi

    echo "Selected folder: $selected_folder"
    ets2_path=$selected_folder
    # Add bin\\win_x64\\eurotrucks2.exe
    ets2_path="$ets2_path/bin/win_x64/eurotrucks2.exe"
    ets2_path=$(winepath -w "$ets2_path")
    ets2_path=$(echo "$ets2_path" | sed 's/U:/Z:/')
    ets2_path=$(echo "$ets2_path" | sed 's|Z:|Z:\\home\\'"$USER"'|')

    json_file=$WINEPREFIX/dosdevices/c:/users/$USER/AppData/Roaming/TruckersMP/launcher-options.json
    jq --arg new_path "$ets2_path" '.games.ets2.path = $new_path' "$json_file" > tmp.$$.json && mv tmp.$$.json "$json_file"
    json_file2=$WINEPREFIX/dosdevices/c:/users/steamuser/AppData/Roaming/TruckersMP/launcher-options.json
    jq --arg new_path "$ets2_path" '.games.ets2.path = $new_path' "$json_file2" > tmp.$$.json && mv tmp.$$.json "$json_file2"

    # Set the games.ets2.consoleOpts to ["-nointro", "-rdevice", "gl"]
    jq --argjson new_opts '["-nointro", "-rdevice", "gl"]' '.games.ets2.consoleOpts = $new_opts' "$json_file" > tmp.$$.json && mv tmp.$$.json "$json_file"
    jq --argjson new_opts '["-nointro", "-rdevice", "gl"]' '.games.ets2.consoleOpts = $new_opts' "$json_file2" > tmp.$$.json && mv tmp.$$.json "$json_file2"
}

main() {
    trap cleanup EXIT

    log "INFO" "Starting TruckersMP installer v$VERSION"

    check_dependencies
    check_wine_version
    check_umu_proton

    echo "PROGRESS:10"

    echo "Installing TruckersMP"

    install_winetricks

    echo "PROGRESS:60"
    
    if [ ! -f "TruckersMP-Setup.exe" ]; then
        # info "TruckersMP-Setup.exe not found in the current directory. Please download the TruckersMP installer from the website and re-run the script"
        # xdg-open "https://truckersmp.com/download"
        # exit 1
        log "INFO" "Downloading TruckersMP-Setup.exe"
        wget https://files.launcher.truckersmp.com/truckersmp-launcher/win/x64/TruckersMP-Setup.exe -P /tmp
        sleep 1
    fi

    echo "PROGRESS:70"

    $WINESERVER -k
    wineserver -k

    wine winecfg /v win10
    wine "/tmp/TruckersMP-Setup.exe"

    echo "PROGRESS:80"

    # Wait for the installer to finish and launch the app
    echo "Waiting for the launcher to start..."
    timeout=3
    elapsed=0
    while :; do
        if pgrep -f "TruckersMP-Launcher.exe" > /dev/null; then
            echo "Launcher detected. Closing it now."
            pkill -f "TruckersMP-Launcher.exe"
            break
        fi
        sleep 1
        elapsed=$((elapsed + 1))
        if [ $elapsed -ge $timeout ]; then
            echo "Timeout reached. Exiting loop."
            break
        fi
    done

    # Download winediscordipcbridge.exe and place it in the wine prefix root
    log "INFO" "Downloading WineDiscordIPCBridge"
    wget https://raw.githubusercontent.com/rs189/truckersmp-linux/main/winediscordipcbridge.exe -P "$TRUCKERSMP_PATH"

    echo "PROGRESS:90"

    create_desktop_entry

    update_game_path

    echo "PROGRESS:100"

    echo "Starting TruckersMP Launcher"
    $WINESERVER -k
    #$WINE64 "$TRUCKERSMP_PATH/TruckersMP-Launcher.exe"
    echo $TRUCKERSMP_PATH
    chmod +x $TRUCKERSMP_PATH/truckersmp-launcher.sh
    bash $TRUCKERSMP_PATH/truckersmp-launcher.sh

    log "INFO" "TruckersMP installation completed"
}

main "$@"