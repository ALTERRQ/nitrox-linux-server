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
USER="nitrox-server"
GROUP="nitrox-server"
DEPLIST="wget tar unzip lib32gcc-s1"
LOG_FILE="./installer.log"
SAVED_LOG_FILE="$HOME_DIR/installer.log"
GAME_DIR="$HOME_DIR/game"
STEAMCMD="$HOME_DIR/steamcmd/steamcmd.sh"

# Function for consistent error messages
error_exit() {
    echo -e "${RED}[ERROR] $1${ENDCOLOR}"
    exit 1
}

# Function for consistent info messages
info_msg() {
    echo -e "${BLUE}[INFO] $1${ENDCOLOR}"
}

# Function for consistent success messages
success_msg() {
    echo -e "  ${GREEN}[SUCCESS] $1${ENDCOLOR}"
}

# Function for consistent warning messages
warning_msg() {
    echo -e "${ORANGE}[WARNING] $1${ENDCOLOR}"
}

# Start logging
exec > >(tee -a "$LOG_FILE") 2>&1

# Check root
if [[ $EUID -ne 0 ]]; then
    error_exit "This install script must be run as root."
fi

# Check if required files exist
for file in steam-game.script nitrox-server.sh nitrox-server.service; do
    if [ ! -f "./$file" ]; then
        error_exit "Required file $file not found in current directory"
    fi
done

# Function to check if a package is installed.
is_installed() {
    dpkg -s "$1" >/dev/null 2>&1
}

# Check if ANY dependencies are missing.
check_dependencies() {
    local missing_pkgs=()

    for pkg in $DEPLIST; do
        if ! is_installed "$pkg"; then
            missing_pkgs+=("$pkg")
        fi
    done

    if [ ${#missing_pkgs[@]} -eq 0 ]; then
        return 0  # All installed
    else
        echo "${missing_pkgs[@]}"
        return 1  # Some missing
    fi
}

# Main installation logic
info_msg "Checking dependencies"

if missing=$(check_dependencies); then
    info_msg "All dependencies are already installed."
else
    info_msg "Adding i368 architecture"
    dpkg --add-architecture i386 || error_exit "Failed to add i368 architecture"
    success_msg "i368 architecture installed successfully."
    
    info_msg "Installing missing packages: $missing"
    apt update || error_exit "Failed to apt update"

    # Convert space-separated string to array for safe installation
    read -ra pkgs_to_install <<< "$missing"

    if apt install -y "${pkgs_to_install[@]}"; then
        success_msg "Dependencies installed successfully."
    else
        error_exit "Failed to install dependencies"
    fi
fi

# Create nitrox-server user and group
if id "$USER" >/dev/null 2>&1; then
    warning_msg "User nitrox-server already exists"
else
    info_msg "Creating nitrox-server user and group"
    adduser nitrox-server --disabled-password --gecos "" || error_exit "Failed to create nitrox-server user"
    usermod -aG video $USER || error_exit "Failed to add user nitrox-server to video group"
    usermod -aG render $USER || error_exit "Failed to add user nitrox-server to render group"
    success_msg "Created user nitrox-server successfully"
fi

# (Re)create and populate server home dir
info_msg "Populating server home dir"
rm -fr $HOME_DIR || error_exit "Failed to delete $HOME_DIR"
mkdir $HOME_DIR || error_exit "Failed to create $HOME_DIR"
mkdir $GAME_DIR
cp ./steam-game.script $HOME_DIR || error_exit "Failed to inflate steam-game.script"
cp ./nitrox-server.sh $HOME_DIR/nitrox-server.sh || error_exit "Failed to inflate nitrox-server.sh"
success_msg "Populated server home dir successfully"

# Install SteamCMD
info_msg "Installing SteamCMD"
mkdir $HOME_DIR/steamcmd
wget -qO- 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz' | tar zxf - -C $HOME_DIR/steamcmd || error_exit "Failed to download SteamCMD to $HOME_DIR"
success_msg "Installed SteamCMD successfully"

# Install Nitrox Server
info_msg "Installing Nitrox Server"
mkdir $HOME_DIR/nitrox
wget -qO /tmp/nitrox.zip 'https://.../Nitrox_1.8.1.0_linux_x64.zip' \
  && unzip -q /tmp/nitrox.zip -d $HOME_DIR/nitrox \
  && rm /tmp/nitrox.zip
success_msg "Installed Nitrox Server successfully"

# (Re)install nitrox-server.service
info_msg "Installing nitrox-server.service"
rm -f /etc/systemd/system/nitrox-server.service || error_exit "Failed to delete /etc/systemd/system/nitrox-server.service"
cp ./nitrox-server.service /etc/systemd/system || error_exit "Failed to install nitrox-server.service to /etc/systemd/system"
systemctl daemon-reload || error_exit "Failed to do 'systemctl daemon-reload'"
systemctl enable nitrox-server.service || error_exit "Failed to enable nitrox-server.service"
success_msg "Installed nitrox-server.service successfully"

# Install Subnautica
info_msg "Installing Subnautica"
bash $STEAMCMD +runscript "$HOME_DIR/steam-game.script" || error_exit "Failed to install Subnautica"
success_msg "Installed Subnautica successfully"

# Own $HOME_DIR and change its permissions
chown -R $USER:$GROUP $HOME_DIR || error_exit "Failed to make nitrox-server own $HOME_DIR"
chmod -R 750 $HOME_DIR || error_exit "Failed to change the permissions of $HOME_DIR to 750"

echo ""
info_msg "To start the server run 'systemctl start nitrox-server'"

# Save log file to $HOME_DIR
cp $LOG_FILE $SAVED_LOG_FILE || warning_msg "Failed to save installation logs to $SAVED_LOG_FILE"
