#!/bin/bash

# Define the base directory for ttserver setup
BASE_DIR="$HOME/ttserver"
CONFIG_DIR="$BASE_DIR/config"
MEDIA_DIR="$BASE_DIR/media"
DOWNLOADS_DIR="$BASE_DIR/downloads"

# Create the base folder structure
echo "Setting up folder structure under $BASE_DIR..."
mkdir -p "$CONFIG_DIR"/{sonarr,radarr,lidarr,readarr,transmission,prowlarr,jellyfin,jellyseerr,nginx-proxy-manager,homepage}
mkdir -p "$MEDIA_DIR"/{TV/{Shows,"Kids Shows"},Movies/{Films,"Kids Films"},Books/{Ebooks,Audiobooks},Music}
mkdir -p "$DOWNLOADS_DIR"

# Check if .env file exists in BASE_DIR; if not, create it with default values
ENV_FILE="$BASE_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "Creating .env file with default values at $ENV_FILE..."
  cat <<EOL > "$ENV_FILE"
# Base paths and environment variables for the ttserver pod
BASE_PATH=$CONFIG_DIR
DOWNLOADS_PATH=$DOWNLOADS_DIR
MEDIA_PATH=$MEDIA_DIR
PUID=1000
PGID=1000
TZ=Asia/Dubai
EOL
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

# Ensure the script has executable permissions (self-set)
chmod +x "$0"

# Create the Pod without comments in-between
echo "Creating Podman pod and starting services..."
podman pod create --name ttserver \
  --publish 2406:8989 \
  --publish 2407:7878 \
  --publish 2408:8686 \
  --publish 2409:8787 \
  --publish 2403:9117 \
  --publish 2410:8096 \
  --publish 2411:5055 \
  --publish 2402:9091 \
  --publish 2401:3000 \
  --publish 2404:80 \
  --publish 2405:443

# Start each container within the ttserver Pod

# Sonarr
podman run -d --name sonarr --pod ttserver \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/sonarr:/config \
  -v ${DOWNLOADS_PATH}:/downloads \
  -v "${MEDIA_PATH}/TV/Shows":/tv \
  -v "${MEDIA_PATH}/TV/Kids Shows":/tv-kids \
  lscr.io/linuxserver/sonarr

# Radarr
podman run -d --name radarr --pod ttserver \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/radarr:/config \
  -v ${DOWNLOADS_PATH}:/downloads \
  -v "${MEDIA_PATH}/Movies/Films":/movies \
  -v "${MEDIA_PATH}/Movies/Kids Films":/movies-kids \
  lscr.io/linuxserver/radarr

# Lidarr
podman run -d --name lidarr --pod ttserver \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/lidarr:/config \
  -v ${DOWNLOADS_PATH}:/downloads \
  -v ${MEDIA_PATH}/Music:/music \
  lscr.io/linuxserver/lidarr

# Readarr
podman run -d --name readarr --pod ttserver \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/readarr:/config \
  -v ${DOWNLOADS_PATH}:/downloads \
  -v "${MEDIA_PATH}/Books/Ebooks":/ebooks \
  -v "${MEDIA_PATH}/Books/Audiobooks":/audiobooks \
  lscr.io/linuxserver/readarr

# Transmission
podman run -d --name transmission --pod ttserver \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/transmission:/config \
  -v ${DOWNLOADS_PATH}:/downloads \
  lscr.io/linuxserver/transmission

# Prowlarr
podman run -d --name prowlarr --pod ttserver \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/prowlarr:/config \
  lscr.io/linuxserver/prowlarr

# Jellyfin
podman run -d --name jellyfin --pod ttserver \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/jellyfin:/config \
  -v ${MEDIA_PATH}:/media \
  lscr.io/linuxserver/jellyfin

# Jellyseerr
podman run -d --name jellyseerr --pod ttserver \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/jellyseerr:/config \
  lscr.io/linuxserver/jellyseerr

# Nginx Proxy Manager
podman run -d --name nginx-proxy-manager --pod ttserver \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/nginx-proxy-manager/data:/data \
  -v ${CONFIG_DIR}/nginx-proxy-manager/letsencrypt:/etc/letsencrypt \
  lscr.io/linuxserver/nginx-proxy-manager

# Homepage
podman run -d --name homepage --pod ttserver \
  -v ${CONFIG_DIR}/homepage:/app/config \
  -v ${MEDIA_PATH}:/media \
  -v ${DOWNLOADS_PATH}:/downloads \
  ghcr.io/benphelps/homepage:latest

# FlareSolverr
podman run -d --name flaresolverr --pod ttserver \
  -e LOG_LEVEL=info \
  -e LOG_HTML=false \
  -e CAPTCHA_SOLVER=none \
  ghcr.io/flaresolverr/flaresolverr:latest
