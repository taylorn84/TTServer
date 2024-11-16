#!/bin/bash

# Define the base directory for ttserver setup
BASE_DIR="/ttserver"
CONFIG_DIR="$BASE_DIR/config"
MEDIA_DIR="$BASE_DIR/media"
DOWNLOADS_DIR="$BASE_DIR/downloads"

# Fetch user and group IDs for ttserver
PUID=$(id -u ttserver)
PGID=$(id -g ttserver)

# Create the base folder structure with required subdirectories
echo "Setting up folder structure under $BASE_DIR..."
sudo mkdir -p "$CONFIG_DIR"/{sonarr,radarr,lidarr,readarr,transmission,prowlarr,jellyfin,jellyseerr,nginx-proxy-manager/{data,letsencrypt},homepage}
sudo mkdir -p "$MEDIA_DIR"/{TV/{Shows,"Kids Shows"},Movies/{Films,"Kids Films"},Books/{Ebooks,Audiobooks},Music}
sudo mkdir -p "$DOWNLOADS_DIR"

# Set ownership of all created directories to user 'ttserver' and group 'ttserver'
echo "Setting ownership to user 'ttserver' and group 'ttserver'..."
sudo chown -R ttserver:ttserver "$BASE_DIR"

# Check if .env file exists in BASE_DIR; if not, create it with default values
ENV_FILE="$BASE_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "Creating .env file with default values at $ENV_FILE..."
  sudo bash -c "cat <<EOL > '$ENV_FILE'
# Base paths and environment variables for the ttserver setup
BASE_PATH=$CONFIG_DIR
DOWNLOADS_PATH=$DOWNLOADS_DIR
MEDIA_PATH=$MEDIA_DIR
PUID=$PUID
PGID=$PGID
TZ=Asia/Dubai
EOL"
  echo ".env file created with default values. Please modify it as needed."
else
  echo ".env file already exists. Loading values..."
fi

# Load environment variables from the .env file
export $(grep -v '^#' "$ENV_FILE" | xargs)

# Install Podman if it's not already installed
if ! command -v podman &> /dev/null; then
  echo "Podman not found. Installing Podman..."
  sudo apt update
  sudo apt install -y podman
else
  echo "Podman is already installed."
fi

# Run each container independently

# Sonarr
sudo podman run -d --name sonarr \
  --user $PUID:$PGID \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/sonarr:/config \
  -v ${DOWNLOADS_PATH}:/downloads \
  -v "${MEDIA_PATH}/TV/Shows":/tv \
  -v "${MEDIA_PATH}/TV/Kids Shows":/tv-kids \
  -p 2406:8989 \
  lscr.io/linuxserver/sonarr:develop

# Radarr
sudo podman run -d --name radarr \
  --user $PUID:$PGID \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/radarr:/config \
  -v ${DOWNLOADS_PATH}:/downloads \
  -v "${MEDIA_PATH}/Movies/Films":/movies \
  -v "${MEDIA_PATH}/Movies/Kids Films":/movies-kids \
  -p 2407:7878 \
  lscr.io/linuxserver/radarr:develop

# Lidarr
sudo podman run -d --name lidarr \
  --user $PUID:$PGID \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/lidarr:/config \
  -v ${DOWNLOADS_PATH}:/downloads \
  -v ${MEDIA_PATH}/Music:/music \
  -p 2408:8686 \
  lscr.io/linuxserver/lidarr:develop

# Readarr
sudo podman run -d --name readarr \
  --user $PUID:$PGID \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/readarr:/config \
  -v ${DOWNLOADS_PATH}:/downloads \
  -v "${MEDIA_PATH}/Books/Ebooks":/ebooks \
  -v "${MEDIA_PATH}/Books/Audiobooks":/audiobooks \
  -p 2409:8787 \
  lscr.io/linuxserver/readarr:develop

# Transmission
sudo podman run -d --name transmission \
  --user $PUID:$PGID \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/transmission:/config \
  -v ${DOWNLOADS_PATH}:/downloads \
  -p 2402:9091 \
  lscr.io/linuxserver/transmission:latest

# Prowlarr
sudo podman run -d --name prowlarr \
  --user $PUID:$PGID \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/prowlarr:/config \
  -p 2403:9117 \
  lscr.io/linuxserver/prowlarr:develop

# Jellyfin
sudo podman run -d --name jellyfin \
  --user $PUID:$PGID \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/jellyfin:/config \
  -v ${MEDIA_PATH}:/media \
  -p 2410:8096 \
  lscr.io/linuxserver/jellyfin:latest

# Jellyseerr
sudo podman run -d --name jellyseerr \
  --user $PUID:$PGID \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/jellyseerr:/app/config \
  -p 2411:5055 \
  docker.io/fallenbagel/jellyseerr:develop

# Nginx Proxy Manager
sudo podman run -d --name nginx-proxy-manager \
  --user $PUID:$PGID \
  --security-opt label=disable \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/nginx-proxy-manager/data:/data \
  -v ${CONFIG_DIR}/nginx-proxy-manager/letsencrypt:/etc/letsencrypt \
  -p 2480:80 \
  -p 2443:443 \
  docker.io/jc21/nginx-proxy-manager:latest

# Homepage
sudo podman run -d --name homepage \
  --user $PUID:$PGID \
  -v ${CONFIG_DIR}/homepage:/app/config \
  -v ${MEDIA_PATH}:/media \
  -v ${DOWNLOADS_PATH}:/downloads \
  -p 2401:3000 \
  ghcr.io/benphelps/homepage:latest

# FlareSolverr
sudo podman run -d --name flaresolverr \
  --user $PUID:$PGID \
  -e LOG_LEVEL=info \
  -e LOG_HTML=false \
  -e CAPTCHA_SOLVER=none \
  -p 2412:8191 \
  ghcr.io/flaresolverr/flaresolverr:latest

echo "ttserver setup is complete, with all directories and containers set to user 'ttserver' and group 'ttserver'."
