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
    if [ ! -f "/usr/bin/umu-run" ]; then
        error "UMU-Launcher-1.1.4 or higher is required. Please download the UMU-Launcher from the website and re-run the script"
        xdg-open "https://github.com/Open-Wine-Components/umu-launcher/releases/tag/1.1.4"
        exit 1
    fi
    if [ ! -f "$WINESERVER" ] || [ ! -f "$WINE64" ]
    then
        info "UMU-Proton-9.0 or higher is required. Downloading UMU-Proton-9.0-3.2"
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
        error "Wine version $wine_version is lower than required version $REQUIRED_WINE_VERSION, please upgrade"
        exit 1
    fi
}

install_winetricks() {
    # Download winetricks if it doesn't exist
    if [ ! -f ./winetricks ]; then
        log "INFO" "Downloading winetricks"
        wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
    fi

    chmod +x ./winetricks
}

create_desktop_entry() {
    local desktop_path="$HOME/.local/share/applications/wine/Programs/TruckersMP/TruckersMP.desktop"
    local exec="env WINEPREFIX=\"$WINEPREFIX\" wine C:\\\\users\\\\$USER\\\\AppData\\\\Roaming\\\\Microsoft\\\\Windows\\\\Start\\\\ Menu\\\\Programs\\\\TruckersMP\\\\TruckersMP.lnk"
    
    echo "Creating desktop file"
    mkdir -p "$(dirname "$desktop_path")"
    cat <<EOF > "$desktop_path"
[Desktop Entry]
Name=TruckersMP
Exec=$exec
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

    # Check if the user canceled the dialog
    if [ $? -ne 0 ]; then
        zenity --error --text="No folder selected. Exiting..."
        exit 1
    fi

    echo "Selected folder: $selected_folder"
    ets2_path=$selected_folder
    ets2_path=$(winepath -w "$ets2_path")
    ets2_path=$(echo "$ets2_path" | sed 's/U:/Z:/')
    ets2_path=$(echo "$ets2_path" | sed 's|Z:|Z:\home\\'"$USER"'|')

    json_file=$WINEPREFIX/dosdevices/c:/users/$USER/AppData/Roaming/TruckersMP/launcher-options.json
    jq --arg new_path "$ets2_path" '.games.ets2.path = $new_path' "$json_file" > tmp.$$.json && mv tmp.$$.json "$json_file"
    json_file2=$WINEPREFIX/dosdevices/c:/users/steamuser/AppData/Roaming/TruckersMP/launcher-options.json
    jq --arg new_path "$ets2_path" '.games.ets2.path = $new_path' "$json_file2" > tmp.$$.json && mv tmp.$$.json "$json_file2"
}

main() {
    trap cleanup EXIT

    log "INFO" "Starting TruckersMP installer v$VERSION"

    check_dependencies
    check_wine_version
    check_umu_proton

    echo "Installing TruckersMP"

    $WINESERVER -k
    ./winetricks --force -q corefonts 
    $WINESERVER -k
    
    if [ ! -f "TruckersMP-Setup.exe" ]; then
        info "TruckersMP-Setup.exe not found in the current directory. Please download the TruckersMP installer from the website and re-run the script"
        xdg-open "https://truckersmp.com/download"
        exit 1
    fi

    wine winecfg /v w11
    wine "TruckersMP-Setup.exe" 

    # Wait for the installer to finish and launch the app
    echo "Waiting for the launcher to start..."
    while :; do
        if pgrep -f "TruckersMP-Launcher.exe" > /dev/null; then
            echo "Launcher detected. Closing it now."
            pkill -f "TruckersMP-Launcher.exe"
            break
        fi
        sleep 1
    done

    create_desktop_entry

    update_game_path

    echo "Starting TruckersMP"
    $WINESERVER -k
    $WINE64 "$TRUCKERSMP_PATH/TruckersMP-Launcher.exe"

    log "INFO" "TruckersMP installation completed"
}

main "$@"