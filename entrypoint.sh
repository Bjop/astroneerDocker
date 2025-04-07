#!/bin/bash
set -e

# Set default values if environment variables are not provided.
: "${SERVER_PORT:=8777}"
: "${PUBLIC_IP:=0.0.0.0}"
: "${OWNER_NAME:=DefaultOwner}"
: "${OWNER_GUID:=0000-0000-0000-0000}"

# Simple logging function
log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ${message}"
}

log "Starting configuration update."

# start Xvfb
log "xvfb_display"
xvfb_display=0
rm -rf /tmp/.X$xvfb_display-lock
Xvfb :$xvfb_display -screen 0, 1024x768x24:32 -nolisten tcp &
export DISPLAY=:$xvfb_display

mkdir -p /usr/share/wine/mono /usr/share/wine/gecko
log "install wine-mono"
if [ ! -f /usr/share/wine/mono/wine-mono-5.0.0-x86.msi ]; then
    log "Downloading wine-mono package..."
    wget --progress=bar:force -O /usr/share/wine/mono/wine-mono-5.0.0-x86.msi http://dl.winehq.org/wine/wine-mono/5.0.0/wine-mono-5.0.0-x86.msi
    log "wine-mono download completed."
fi

log "install wine-gecko"
if [ ! -f /usr/share/wine/gecko/wine-gecko-2.47.1-x86_64.msi ]; then
    log "Downloading wine-gecko 64-bit package..."
    wget --progress=bar:force -O /usr/share/wine/gecko/wine-gecko-2.47.1-x86_64.msi http://dl.winehq.org/wine/wine-gecko/2.47.1/wine-gecko-2.47.1-x86_64.msi
    log "wine-gecko 64-bit download completed."
fi

if [ ! -f /usr/share/wine/gecko/wine-gecko-2.47.1-x86.msi ]; then
    log "Downloading wine-gecko 32-bit package..."
    wget --progress=bar:force -O /usr/share/wine/gecko/wine-gecko-2.47.1-x86.msi http://dl.winehq.org/wine/wine-gecko/2.47.1/wine-gecko-2.47.1-x86.msi
    log "wine-gecko 32-bit download completed."
fi


# Add it to PATH if not already in PATH
log "adding the wine path to PATH"
WINE_DIR="/usr/local/bin/wine64"
if [[ ":$PATH:" != *":$WINE_DIR:"* ]]; then
    export PATH="/usr/local/bin/wine64"

    echo "Added $WINE_DIR to PATH."
else
    echo "$WINE_DIR is already in PATH."
fi
# Check if the command to execute (e.g., wine) is available.
command_name="$1"
if [ "$command_name" = "wine64" ]; then
    if ! command -v wine >/dev/null 2>&1; then
        log "Error: 'wine' command not found. Please ensure Wine is installed and available in your PATH."
        exit 1
    fi
fi

log "Stopping Astroneer server..."
pkill -f AstroServer.exe

log "Starting Astroneer server..."
wine ~/Steam/steamapps/common/Astroneer\ Dedicated\ Server/AstroServer.exe

# Check if both configuration files exist.
ENGINE_INI="/home/steam/astroneer/Engine.ini"
ASTRO_INI="/home/steam/astroneer/AstroServerSettings.ini"

if [ ! -f "$ENGINE_INI" ] || [ ! -f "$ASTRO_INI" ]; then
    log "Configuration file(s) missing. Please run the server once and then close it to generate the necessary configuration files."
    exit 1
fi

log "Parameters: ServerPort=${SERVER_PORT}, PublicIP=${PUBLIC_IP}, OwnerName=${OWNER_NAME}, OwnerGuid=${OWNER_GUID}"

# Update Engine.ini with the SERVER_PORT
if sed -i "s/^ServerPort=.*/ServerPort=${SERVER_PORT}/" "$ENGINE_INI"; then
    log "Successfully updated Engine.ini with ServerPort=${SERVER_PORT}"
else
    log "Error updating Engine.ini with ServerPort"
fi

# Update AstroServerSettings.ini with the PublicIP, OwnerName, and OwnerGuid
if sed -i "s/^PublicIP=.*/PublicIP=${PUBLIC_IP}/" "$ASTRO_INI"; then
    log "Successfully updated AstroServerSettings.ini with PublicIP=${PUBLIC_IP}"
else
    log "Error updating AstroServerSettings.ini with PublicIP"
fi

if sed -i "s/^OwnerName=.*/OwnerName=${OWNER_NAME}/" "$ASTRO_INI"; then
    log "Successfully updated AstroServerSettings.ini with OwnerName=${OWNER_NAME}"
else
    log "Error updating AstroServerSettings.ini with OwnerName"
fi

if sed -i "s/^OwnerGuid=.*/OwnerGuid=${OWNER_GUID}/" "$ASTRO_INI"; then
    log "Successfully updated AstroServerSettings.ini with OwnerGuid=${OWNER_GUID}"
else
    log "Error updating AstroServerSettings.ini with OwnerGuid"
fi

log "Configuration update completed."
echo "Updated configuration: ServerPort=${SERVER_PORT}, PublicIP=${PUBLIC_IP}, OwnerName=${OWNER_NAME}, OwnerGuid=${OWNER_GUID}"

log "Executing command: $@"
exec "$@"