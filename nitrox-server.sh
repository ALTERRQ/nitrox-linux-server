#!/bin/bash

# Colors
RED="\e[1;31m"
GREEN="\e[1;32m"
BLUE="\e[1;34m"
ORANGE="\e[1;33m"
ENDCOLOR="\e[0m"

# Define some variables
HOME_DIR=/var/lib/nitrox-server
GAME_DIR="$HOME_DIR/game"
STEAMCMD="$HOME_DIR/steamcmd/steamcmd.sh"
export SUBNAUTICA_INSTALLATION_PATH="$GAME_DIR"

# Function for consistent error messages
error_exit() { echo -e "${RED}[ERROR] $1${ENDCOLOR}"; exit 1; }
info_msg()   { echo -e "${BLUE}[INFO] $1${ENDCOLOR}"; }
success_msg(){ echo -e "  ${GREEN}[SUCCESS] $1${ENDCOLOR}"; }
warning_msg(){ echo -e "${ORANGE}[WARNING] $1${ENDCOLOR}"; }

# Start server and hold the process
info_msg "Starting server..."
cd "$HOME_DIR/nitrox" || error_exit "Failed to cd to $HOME_DIR/nitrox"

# Start the game server
"$HOME_DIR/nitrox/Nitrox.Server.Subnautica" || error_exit "Failed to start Nitrox server"
