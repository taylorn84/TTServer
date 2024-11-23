#!/bin/bash
### Description: TTServer Media Automation Script - Installs All Applications
### Version: 1.2
### Original Authors: Nathan Taylor

### Custom Colors from Palette
pink='\033[38;2;255;0;255m'          # Hot Pink
purple='\033[38;2;128;0;128m'        # Purple
navy='\033[38;2;26;26;89m'           # Navy Blue
deep_blue='\033[38;2;0;0;255m'       # Deep Blue
cyan_blue='\033[38;2;0;170;255m'     # Bright Cyan Blue
reset='\033[0m'                      # Reset

scriptversion="1.2"
scriptdate="2024-11-23"

set -euo pipefail

### Ensure Script is Run as Root
if [ "$EUID" -ne 0 ]; then
    echo -e "${pink}Please run as root!${reset}"
    exit 1
fi

### Title Splash
echo -e "${purple}"
echo -e "#############################################################"
echo -e "#       TTServer Media Automation Script - Version $scriptversion      #"
echo -e "#                 Last Updated: $scriptdate                 #"
echo -e "#############################################################"
echo -e "${reset}"

### Constants
installdir="/nfserver/media-automation"  # Installation Directory
app_user="ttserver"                      # Fixed user
app_group="ttserver"                     # Fixed group

# Applications and ports
declare -A apps
apps=(
    ["Radarr"]="2405"
    ["Sonarr"]="2406"
    ["Lidarr"]="2407"
    ["Readarr"]="2408"
    ["Prowlarr"]="2409"
)

### Create User/Group if Needed
if ! getent group "$app_group" >/dev/null; then
    groupadd "$app_group"
fi
if ! getent passwd "$app_user" >/dev/null; then
    adduser --system --no-create-home --ingroup "$app_group" "$app_user"
fi
if ! getent group "$app_group" | grep -qw "$app_user"; then
    usermod -a -G "$app_group" "$app_user"
fi

### Install Each Application
for app in "${!apps[@]}"; do
    app_port="${apps[$app]}"
    app_bin="${app^}"
    branch="develop"  # Fixed to always install the 'develop' branch
    bindir="${installdir}/${app^}"
    datadir="${bindir}/config"

    echo -e "${cyan_blue}Installing $app on port $app_port...${reset}"

    ### Stop Existing Service if Running
    if service --status-all | grep -Fq "$app"; then
        systemctl stop "$app"
        systemctl disable "$app".service
    fi

    ### Create Directories and Set Permissions
    mkdir -p "$datadir"
    mkdir -p "$installdir"
    chown -R "$app_user:$app_group" "$datadir" "$installdir"
    chmod 750 "$datadir"
    chmod 775 "$installdir"

    ### Install Required Packages
    echo -e "${cyan_blue}Checking for missing prerequisite packages...${reset}"
    app_prereq="curl sqlite3"
    if [[ "$app" == "Lidarr" ]]; then
        app_prereq+=" libchromaprint-tools mediainfo"
    fi
    missing_packages=()
    for pkg in $app_prereq; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            missing_packages+=("$pkg")
        fi
    done
    if [ ${#missing_packages[@]} -gt 0 ]; then
        echo -e "Installing: ${deep_blue}${missing_packages[*]}${reset}"
        apt update && apt install -y "${missing_packages[@]}"
    else
        echo -e "${green}All prerequisite packages are already installed!${reset}"
    fi

    ### Download and Install the App
    echo -e "${cyan_blue}Downloading and installing ${app^}...${reset}"
    ARCH=$(dpkg --print-architecture)
    dlbase="https://$app.servarr.com/v1/update/$branch/updatefile?os=linux&runtime=netcore"
    case "$ARCH" in
    "amd64") DLURL="${dlbase}&arch=x64" ;;
    "armhf") DLURL="${dlbase}&arch=arm" ;;
    "arm64") DLURL="${dlbase}&arch=arm64" ;;
    *)
        echo -e "${red}Unsupported architecture! Exiting.${reset}"
        exit 1
        ;;
    esac
    wget --content-disposition "$DLURL" -O "${app^}.tar.gz" || { echo "${red}Failed to download ${app^}.${reset}"; exit 1; }
    tar -xvzf "${app^}.tar.gz" -C /tmp/
    rm -rf "$bindir"
    mv "/tmp/${app^}" "$bindir"
    chown -R "$app_user:$app_group" "$bindir"
    chmod 775 "$bindir"
    rm "${app^}.tar.gz"

    ### Create Systemd Service File
    echo -e "${cyan_blue}Setting up systemd service for $app...${reset}"
    cat <<EOF | tee /etc/systemd/system/"$app".service >/dev/null
[Unit]
Description=${app^} Daemon
After=syslog.target network.target

[Service]
User=$app_user
Group=$app_group
UMask=0002
Type=simple
ExecStart=$bindir/$app_bin -nobrowser -data=$datadir
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    ### Start and Enable Service
    systemctl daemon-reload
    systemctl enable --now "$app"

    ### Verify Installation
    if systemctl is-active --quiet "$app"; then
        ip_local=$(hostname -I | awk '{print $1}')
        echo -e "${green}${app^} installation complete!${reset}"
        echo -e "Access ${app^} at: ${pink}http://$ip_local:$app_port${reset}"
    else
        echo -e "${red}Failed to start ${app^} service. Check logs for details.${reset}"
    fi
done
