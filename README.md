# TruckersMP Installer for Linux

A bash script to automate the installation and configuration of TruckersMP for Euro Truck Simulator 2 on Linux using UMU-Proton and Wine.

## Features

- Automatic installation of TruckersMP inside of Euro Truck Simulator 2 prefix using Wine and UMU-Proton.
- Automatic configuration of path to the Euro Truck Simulator 2 inside of TruckersMP launcher.
- Automatic desktop entry creation.
- Discord Rich Presence support.

## Requirements

### System Dependencies
- Wine 9.15 or higher
- UMU-Proton-9.0-3.2 or higher (Installed automatically)
- zenity
- wget
- jq

### Supported Games
- Euro Truck Simulator 2 (Steam version under UMU-Proton-9.0-3.2 or higher)

## Installation

1. Download the TruckersMP installer from the official website:
   - Visit the [TruckersMP Download page.](https://truckersmp.com/download)
   - Save the installer as `TruckersMP-Setup.exe` in the same directory as the script.

2. Run the installer:
   ```bash
   wget -qO truckersmp-installer.sh https://github.com/rs189/TruckersMP-Linux/raw/main/truckersmp-installer.sh && chmod +x truckersmp-installer.sh && ./truckersmp-installer.sh
   ```

During installation, you will be prompted to select your Euro Truck Simulator 2 installation directory

## Troubleshooting

Common issues and solutions:
- If the installer doesn't start, please install all dependencies.
- If the Wine version check fails, upgrade Wine to version 9.15 or higher.

## Uninstallation

To uninstall TruckersMP:
1. Uninstall TruckersMP Launcher using Protontricks.
2. Delete the desktop entry from `~/.local/share/applications/wine/Programs/TruckersMP/`.

# Licence

This project is licensed under the MIT licence.
