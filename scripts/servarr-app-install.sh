#!/bin/bash

### Colors
green='\033[0;32m'
yellow='\033[1;33m'
red='\033[0;31m'
brown='\033[0;33m'
reset='\033[0m'

scriptversion="3.0.12"
scriptdate="2024-04-10"

set -euo pipefail

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "${red}Please run as root!"
    echo -e "Exiting script!${reset}"
    exit 1
fi

# Title splash
echo -e "${brown}#############################################################"
echo -e "#   Welcome to the Servarr Community Installation Script!   #"
echo -e "#############################################################${reset}"

echo "Running Servarr Install Script - Version ${brown}[$scriptversion]${reset} as of ${brown}[$scriptdate]${reset}"
echo ""

echo "Select the application to install: "
select app in lidarr prowlarr radarr readarr sonarr quit; do
    case $app in
    lidarr)
        app_port="8686"
        app_prereq="curl sqlite3 libchromaprint-tools mediainfo"
        app_umask="0002"
        branch="develop"
        break
        ;;
    prowlarr)
        app_port="9696"
        app_prereq="curl sqlite3"
        app_umask="0002"
        branch="develop"
        break
        ;;
    radarr)
        app_port="7878"
        app_prereq="curl sqlite3"
        app_umask="0002"
        branch="develop"
        break
        ;;
    readarr)
        app_port="8787"
        app_prereq="curl sqlite3"
        app_umask="0002"
        branch="develop"
        break
        ;;
    sonarr)
        app_port="8989"
        app_prereq="curl sqlite3"
        app_umask="0002"
        branch="develop"
        break
        ;;
    quit)
        exit 0
        ;;
    *)
        echo "Invalid option $REPLY"
        ;;
    esac
done

### Custom paths
installdir="/home-server/media-automation"
bindir="${installdir}/${app^}"
datadir="/home-server/media-automation/${app^}/config"
app_bin=${app^}

# Default user and group to ttserver
app_uid="ttserver"
app_guid="ttserver"

echo -e "${brown}[${app^}]${reset} will be installed to ${brown}[$bindir]${reset} and use ${brown}[$datadir]${reset} for AppData."
echo -e "The application will run as user ${brown}[$app_uid]${reset} and group ${brown}[$app_guid]${reset}."
read -r -p "Type 'yes' to continue with the installation: " response
if [[ $response != "yes" ]]; then
    echo "Operation canceled. Exiting script."
    exit 0
fi

# Create user/group if needed
if ! getent group "$app_guid" >/dev/null; then
    groupadd "$app_guid"
fi
if ! getent passwd "$app_uid" >/dev/null; then
    adduser --system --no-create-home --ingroup "$app_guid" "$app_uid"
fi

# Stop any existing service
if systemctl is-active --quiet "$app"; then
    systemctl stop "$app"
    systemctl disable "$app"
fi

# Create directories
mkdir -p "$datadir" "$bindir"
chown -R "$app_uid":"$app_guid" "$datadir" "$bindir"
chmod 775 "$datadir" "$bindir"

# Install prerequisites
missing_packages=()
for pkg in $app_prereq; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        missing_packages+=("$pkg")
    fi
done
if [ ${#missing_packages[@]} -gt 0 ]; then
    apt update && apt install -y "${missing_packages[@]}"
fi

# Download and install the app
ARCH=$(dpkg --print-architecture)
dlbase="https://$app.servarr.com/v1/update/$branch/updatefile?os=linux&runtime=netcore"
case "$ARCH" in
"amd64") DLURL="${dlbase}&arch=x64" ;;
"armhf") DLURL="${dlbase}&arch=arm" ;;
"arm64") DLURL="${dlbase}&arch=arm64" ;;
*) echo "${red}Unsupported architecture. Exiting.${reset}" && exit 1 ;;
esac

wget --content-disposition "$DLURL"
tarball="${app^}".*.tar.gz
tar -xvzf "$tarball" -C "$bindir" --strip-components=1
chown -R "$app_uid":"$app_guid" "$bindir"
rm -f "$tarball"

# Create service file
cat <<EOF | tee /etc/systemd/system/"$app".service >/dev/null
[Unit]
Description=${app^} Daemon
After=syslog.target network.target
[Service]
User=$app_uid
Group=$app_guid
UMask=$app_umask
Type=simple
ExecStart=$bindir/$app_bin -nobrowser -data=$datadir
TimeoutStopSec=20
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now "$app"

# Verify service
if systemctl is-active --quiet "$app"; then
    echo -e "${green}${app^} installed successfully! Access it at http://$(hostname -I | awk '{print $1}'):$app_port${reset}"
else
    echo -e "${red}Failed to start ${app^}. Check the logs for more details.${reset}"
fi

exit 0
