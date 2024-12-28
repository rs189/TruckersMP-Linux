<div align="center">

<img src="https://truckersmp.com/assets/img/truckersmp-logo-sm.png" width="369" height="80"/>

</div>

## A Bash and Python script packaged as an AppImage to automate the installation and configuration of TruckersMP for Euro Truck Simulator 2 on Linux, utilising UMU-Proton and Wine.

## Features

- Automatic TruckersMP installation inside Euro Truck Simulator 2 prefix using UMU-Proton and Wine.
- Automatic Euro Truck Simulator 2 path configuration within the TruckersMP launcher.
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

Run the AppImage installer provided in the [releases](https://github.com/rs189/TruckersMP-Linux/releases) section.

## Troubleshooting

Common issues and solutions:
- If the installer doesn't start, please install all required dependencies.
- If the Wine version check fails, please upgrade Wine to version 9.15 or higher.

For further troubleshooting, please run the installer from the terminal and provide the output.

## Uninstallation

To uninstall TruckersMP:
1. Uninstall TruckersMP Launcher using Protontricks.
2. Delete the desktop entry from `~/.local/share/applications/wine/Programs/TruckersMP/`.

## Development

To build the AppImage installer, run the following commands:
```bash
git clone https://github.com/rs189/TruckersMP-Linux.git
cd TruckersMP-Linux
./package_appimage.sh
```

# Licence

This project is licensed under the MIT licence.