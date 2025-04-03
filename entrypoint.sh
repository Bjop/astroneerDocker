#!/bin/bash
set -e

# Set default values if environment variables are not provided.
: "${SERVER_PORT:=8777}"
: "${PUBLIC_IP:=192.168.0.1}"
: "${OWNER_NAME:=DefaultOwner}"
: "${OWNER_GUID:=0000-0000-0000-0000}"

# Update Engine.ini with the SERVER_PORT
sed -i "s/^ServerPort=.*/ServerPort=${SERVER_PORT}/" /home/steam/astroneer/Engine.ini

# Update AstroServerSettings.ini with the PublicIP, OwnerName, and OwnerGuid
sed -i "s/^PublicIP=.*/PublicIP=${PUBLIC_IP}/" /home/steam/astroneer/AstroServerSettings.ini
sed -i "s/^OwnerName=.*/OwnerName=${OWNER_NAME}/" /home/steam/astroneer/AstroServerSettings.ini
sed -i "s/^OwnerGuid=.*/OwnerGuid=${OWNER_GUID}/" /home/steam/astroneer/AstroServerSettings.ini

echo "Updated configuration: ServerPort=${SERVER_PORT}, PublicIP=${PUBLIC_IP}, OwnerName=${OWNER_NAME}, OwnerGuid=${OWNER_GUID}"

exec "$@"