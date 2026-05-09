#!/bin/bash

# Colors
RED="\e[1;31m"
GREEN="\e[1;32m"
BLUE="\e[1;34m"
ORANGE="\e[1;33m"
ENDCOLOR="\e[0m"

# Define some variables
HOME_DIR=/var/lib/nitrox-server
STEAMCMD="$HOME_DIR/steamcmd/steamcmd.sh"
GAME_DIR="$HOME_DIR/game"
USER="nitrox-server"
GROUP="nitrox-server"

# Function for consistent error messages
error_exit() { echo -e "${RED}[ERROR] $1${ENDCOLOR}"; exit 1; }
info_msg()   { echo -e "${BLUE}[INFO] $1${ENDCOLOR}"; }
success_msg(){ echo -e "  ${GREEN}[SUCCESS] $1${ENDCOLOR}"; }
warning_msg(){ echo -e "${ORANGE}[WARNING] $1${ENDCOLOR}"; }

# Check root
if [[ $EUID -ne 0 ]]; then
    error_exit "This script must be run as root."
fi

# Check SteamCMD exists
if [[ ! -f "$STEAMCMD" ]]; then
    error_exit "SteamCMD not found at $STEAMCMD. Have you run install.sh?"
fi

# Prompt for credentials
echo ""
read -rp  "  Steam username: "                    STEAM_USER
read -rsp "  Steam password: "                    STEAM_PASS
echo ""

# Stop the server if it's running
if systemctl is-active --quiet nitrox-server; then
    warning_msg "nitrox-server is running — stopping it before update"
    systemctl stop nitrox-server || error_exit "Failed to stop nitrox-server"
fi

# Run install/update
info_msg "Installing / Updating / Validating Subnautica..."
bash "$STEAMCMD" \
    +force_install_dir "$GAME_DIR" \
    +login "$STEAM_USER" "$STEAM_PASS" \
    +app_update 264710 validate \
    +quit || error_exit "Failed to install / update Subnautica"
success_msg "Subnautica updated successfully"

if [[ "$1" == "install" ]]; then
    info_msg "Installing Nitrox Server"
    mkdir $HOME_DIR/nitrox
    wget -qO /tmp/nitrox.zip 'https://.../Nitrox_1.8.1.0_linux_x64.zip' \
        && unzip -q /tmp/nitrox.zip -d $HOME_DIR/nitrox \
        && rm /tmp/nitrox.zip
    success_msg "Installed Nitrox Server successfully"
fi

# Fix ownership in case SteamCMD wrote files as root
chown -R $USER:$GROUP "$HOME_DIR" || warning_msg "Failed to fix ownership on $HOME_DIR"

success_msg "Server installed / updated successfully"
