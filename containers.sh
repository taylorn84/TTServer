#!/bin/bash

# Define the base directory for ttserver setup
BASE_DIR="$HOME/ttserver"
CONFIG_DIR="$BASE_DIR/config"
MEDIA_DIR="$BASE_DIR/media"
DOWNLOADS_DIR="$BASE_DIR/downloads"

# Fetch user and group IDs for ttserver
PUID=$(id -u ttserver)
PGID=$(id -g ttserver)

# Create the base folder structure
echo "Setting up folder structure under $BASE_DIR..."
#!/bin/bash

# Define the base directory for ttserver setup
BASE_DIR="$HOME/ttserver"
CONFIG_DIR="$BASE_DIR/config"
MEDIA_DIR="$BASE_DIR/media"
DOWNLOADS_DIR="$BASE_DIR/downloads"

# Fetch user and group IDs for ttserver
PUID=$(id -u ttserver)
PGID=$(id -g ttserver)

# Create the base folder structure with required subdirectories
echo "Setting up folder structure under $BASE_DIR..."
mkdir -p "$CONFIG_DIR"/{sonarr,radarr,lidarr,readarr,transmission,prowlarr,jellyfin,jellyseerr,nginx-proxy-manager/{data,letsencrypt},homepage}
mkdir -p "$MEDIA_DIR"/{TV/{Shows,"Kids Shows"},Movies/{Films,"Kids Films"},Books/{Ebooks,Audiobooks},Music}
mkdir -p "$DOWNLOADS_DIR"

# Set ownership of all created directories to user 'ttserver' and group 'ttserver'
echo "Setting ownership to user 'ttserver' and group 'ttserver'..."
sudo chown -R ttserver:ttserver "$BASE_DIR"

# Check if .env file exists in BASE_DIR; if not, create it with default values
ENV_FILE="$BASE_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "Creating .env file with default values at $ENV_FILE..."
  cat <<EOL > "$ENV_FILE"
# Base paths and environment variables for the ttserver setup
BASE_PATH=$CONFIG_DIR
DOWNLOADS_PATH=$DOWNLOADS_DIR
MEDIA_PATH=$MEDIA_DIR
PUID=$PUID
PGID=$PGID
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

# Run each container individually with correct image addresses and develop versions where applicable

# Sonarr (develop version)
podman run -d --name sonarr \
  -p 2406:8989 \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/sonarr:/config \
  -v ${DOWNLOADS_PATH}:/downloads \
  -v "${MEDIA_PATH}/TV/Shows":/tv \
  -v "${MEDIA_PATH}/TV/Kids Shows":/tv-kids \
  lscr.io/linuxserver/sonarr:develop

# Radarr (develop version)
podman run -d --name radarr \
  -p 2407:7878 \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/radarr:/config \
  -v ${DOWNLOADS_PATH}:/downloads \
  -v "${MEDIA_PATH}/Movies/Films":/movies \
  -v "${MEDIA_PATH}/Movies/Kids Films":/movies-kids \
  lscr.io/linuxserver/radarr:develop

# (Repeat for other containers as in the original script)

# Final message
echo "ttserver setup is complete, with all directories and containers set to user 'ttserver' and group 'ttserver'."

mkdir -p "$MEDIA_DIR"/{TV/{Shows,"Kids Shows"},Movies/{Films,"Kids Films"},Books/{Ebooks,Audiobooks},Music}
mkdir -p "$DOWNLOADS_DIR"

# Set ownership of all created directories to user 'ttserver' and group 'ttserver'
echo "Setting ownership to user 'ttserver' and group 'ttserver'..."
sudo chown -R ttserver:ttserver "$BASE_DIR"

# Check if .env file exists in BASE_DIR; if not, create it with default values
ENV_FILE="$BASE_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "Creating .env file with default values at $ENV_FILE..."
  cat <<EOL > "$ENV_FILE"
# Base paths and environment variables for the ttserver setup
BASE_PATH=$CONFIG_DIR
DOWNLOADS_PATH=$DOWNLOADS_DIR
MEDIA_PATH=$MEDIA_DIR
PUID=$PUID
PGID=$PGID
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

# Run each container individually with correct image addresses and develop versions where applicable

# Sonarr (develop version)
podman run -d --name sonarr \
  -p 2406:8989 \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/sonarr:/config \
  -v ${DOWNLOADS_PATH}:/downloads \
  -v "${MEDIA_PATH}/TV/Shows":/tv \
  -v "${MEDIA_PATH}/TV/Kids Shows":/tv-kids \
  lscr.io/linuxserver/sonarr:develop

# Radarr (develop version)
podman run -d --name radarr \
  -p 2407:7878 \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/radarr:/config \
  -v ${DOWNLOADS_PATH}:/downloads \
  -v "${MEDIA_PATH}/Movies/Films":/movies \
  -v "${MEDIA_PATH}/Movies/Kids Films":/movies-kids \
  lscr.io/linuxserver/radarr:develop

# Lidarr (develop version)
podman run -d --name lidarr \
  -p 2408:8686 \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/lidarr:/config \
  -v ${DOWNLOADS_PATH}:/downloads \
  -v ${MEDIA_PATH}/Music:/music \
  lscr.io/linuxserver/lidarr:develop

# Readarr (develop version)
podman run -d --name readarr \
  -p 2409:8787 \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/readarr:/config \
  -v ${DOWNLOADS_PATH}:/downloads \
  -v "${MEDIA_PATH}/Books/Ebooks":/ebooks \
  -v "${MEDIA_PATH}/Books/Audiobooks":/audiobooks \
  lscr.io/linuxserver/readarr:develop

# Transmission
podman run -d --name transmission \
  -p 2402:9091 \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/transmission:/config \
  -v ${DOWNLOADS_PATH}:/downloads \
  lscr.io/linuxserver/transmission:latest

# Prowlarr
podman run -d --name prowlarr \
  -p 2403:9117 \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/prowlarr:/config \
  lscr.io/linuxserver/prowlarr:develop

# Jellyfin
podman run -d --name jellyfin \
  -p 2410:8096 \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/jellyfin:/config \
  -v ${MEDIA_PATH}:/media \
  lscr.io/linuxserver/jellyfin:latest

# Jellyseerr
podman run -d --name jellyseerr \
  -p 2411:5055 \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/jellyseerr:/config \
  docker.io/fallenbagel/jellyseerr:develop

# Nginx Proxy Manager
podman run -d --name nginx-proxy-manager \
  -p 2404:80 \
  -p 2405:443 \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=$TZ \
  -v ${CONFIG_DIR}/nginx-proxy-manager/data:/data \
  -v ${CONFIG_DIR}/nginx-proxy-manager/letsencrypt:/etc/letsencrypt \
  docker.io/jc21/nginx-proxy-manager:latest

# Homepage
podman run -d --name homepage \
  -p 2401:3000 \
  -v ${CONFIG_DIR}/homepage:/app/config \
  -v ${MEDIA_PATH}:/media \
  -v ${DOWNLOADS_PATH}:/downloads \
  ghcr.io/benphelps/homepage:latest

# FlareSolverr
podman run -d --name flaresolverr \
  -p 2412:8191 \
  -e LOG_LEVEL=info \
  -e LOG_HTML=false \
  -e CAPTCHA_SOLVER=none \
  ghcr.io/flaresolverr/flaresolverr:latest

echo "ttserver setup is complete, with all directories and containers set to user 'ttserver' and group 'ttserver'."
