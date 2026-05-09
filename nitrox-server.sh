#!/bin/bash

# Colors
RED="\e[1;31m"
GREEN="\e[1;32m"
BLUE="\e[1;34m"
ORANGE="\e[1;33m"
PURPLE="\e[1;35m"
CYAN="\e[1;36m"
ENDCOLOR="\e[0m"

# Define some variables
HOME_DIR=/var/lib/nitrox-server
STEAMCMD="$HOME_DIR/steamcmd/steamcmd.sh"
LOG_FILE="$HOME_DIR/nitrox-server.log"

# Function for consistent error messages
error_exit() {
    echo -e "${RED}[ERROR] $1${ENDCOLOR}"
    exit 1
}

# Function for consistent info messages
info_msg() { echo -e "${BLUE}[INFO] $1${ENDCOLOR}"; }

# Function for consistent success messages
success_msg() { echo -e "${GREEN}[SUCCESS] $1${ENDCOLOR}"; }

# Function for consistent warning messages
warning_msg() { echo -e "${ORANGE}[WARNING] $1${ENDCOLOR}"; }

# Update / Validate server
info_msg "Updating / Validating server..."
bash "$STEAMCMD" +runscript "$HOME_DIR/steam-game.script" || error_exit "Failed to update/validate server"

# Start server and hold the process
info_msg "Starting server..."
cd "$HOME_DIR/nitrox" || error_exit "Failed to cd to $HOME_DIR/nitrox"

# Start the game server
"$HOME_DIR/nitrox/Nitrox.Server.Subnautica" > "$LOG_FILE" 2>&1 || error_exit "Failed to start Nitrox server"
